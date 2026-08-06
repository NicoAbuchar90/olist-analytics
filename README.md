# Olist E-Commerce Analytics

Analytics engineering project on top of the public **Olist Brazilian E-Commerce**
dataset. Olist is a marketplace that connects third-party sellers to customers
across Brazil; this project models the raw order data into BI-ready marts and
exposes it through dashboards, using **dbt Core + BigQuery + Looker Studio**.

## The data

Source: [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
on Kaggle — a static historical dump covering **2016–2018**, loaded once (not a
recurring feed). It ships as 9 CSVs, loaded into a BigQuery dataset (`olist_raw`):

| File | Contents |
|---|---|
| `olist_orders_dataset.csv` | One row per order, with status and timestamps |
| `olist_order_items_dataset.csv` | Line items per order (product, seller, price, freight) |
| `olist_order_payments_dataset.csv` | Payment method and value per order |
| `olist_order_reviews_dataset.csv` | Customer review score and text per order |
| `olist_customers_dataset.csv` | Customer id and location |
| `olist_sellers_dataset.csv` | Seller id and location |
| `olist_products_dataset.csv` | Product attributes and category |
| `olist_geolocation_dataset.csv` | Zip-code-level lat/long for Brazil |
| `product_category_name_translation.csv` | Category names, Portuguese → English |

## Architecture

A layered dbt pipeline, fact-centric rather than a full dimensional model — the
two dashboards this project feeds only need seller location denormalized onto the
fact, so there's no separate `dim_sellers`/`dim_customers`:

```
sources (olist_raw, BigQuery)
   │
   ▼
staging (views)         one view per source table: rename/cast only, no logic
                         stg_orders, stg_customers, stg_order_items,
                         stg_order_payments, stg_products, stg_sellers,
                         stg_geolocation, stg_product_category_name_translation
   │
   ▼
intermediate (view)     int_order_items_sellers
                         order_items ⋈ orders ⋈ sellers, derives order_month
   │
   ▼
facts (incremental)     fct_order_items — grain: one row per order item
                         merge strategy, day-partitioned on purchased_at
   │
   ▼
marts (views)           seller_monthly_activity   (seller × month revenue/orders)
                         seller_cohort_retention   (seller cohort retention %)
   │
   ▼
exposures → BI          Looker Studio: Sellers, Olist Executive
```

12 models total. `staging`/`intermediate`/`marts` default to `view`
(project-level config); `fct_order_items` overrides to `incremental` and is the
single source of truth every mart reads from.

## Repo structure

| Path | What it is |
|---|---|
| `olist/` | dbt project — models, macros, tests, packages |
| `data/` | raw CSVs (gitignored, populated by `scripts/download_data.py`) |
| `scripts/download_data.py` | pulls the dataset from Kaggle via `kagglehub` into `data/` |
| `scripts/load_to_bigquery.py` | loads the CSVs from `data/` into BigQuery (`olist_raw`) |
| `.github/workflows/ci.yml` | CI: lint + build on every PR and push to `main` |

## Running it

```bash
pip install -r requirements.txt

python scripts/download_data.py       # pulls CSVs into data/
python scripts/load_to_bigquery.py    # loads them into BigQuery (olist_raw)

cd olist
dbt deps
dbt build
```

Requires a `~/.dbt/profiles.yml` with a BigQuery target for the `olist` profile
(see `.github/workflows/ci.yml` for the shape CI uses).

## CI/CD

Every PR and every push to `main` runs (`.github/workflows/ci.yml`):

```yaml
- run: sqlfluff lint models/
- run: dbt build --target ci
```

against a dedicated BigQuery dataset (`dbt_ci_testing`), isolated from the
production dataset the live dashboards read from — a broken model in a PR can't
reach `main` or affect what's on screen in Looker Studio.

## Design decisions

- **No source freshness checks**: Olist is a static historical dataset (2016-2018), loaded once from CSVs with no recurring ingestion and no real "loaded at" timestamp. Checking freshness against event timestamps (e.g. `order_purchase_timestamp`) would always report stale data, so it was left out as not applicable to this dataset.
- **No conformed dimensions**: seller attributes (`seller_city`, `seller_state`) are denormalized straight into `fct_order_items` via the intermediate layer rather than modeled as a `dim_sellers`. The source has no seller attribute history to track, and the two dashboards this project feeds only need those two columns — a surrogate-keyed dimension for that would be over-engineering relative to what's actually needed.
- **Incremental strategy on `fct_order_items`**: `merge` on a hashed surrogate key (`order_id`, `order_item_id`), day-partitioned on `purchased_at`. This keeps repeated `dbt build` runs cheap via BigQuery partition pruning, at the cost of no lookback/grace window — acceptable for a one-time static load, but would need one before this could safely run against a genuinely incrementing feed.
