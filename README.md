# Olist E-Commerce Analytics — end-to-end dbt + BigQuery project

## Design decisions

- **No source freshness checks**: Olist is a static historical dataset (2016-2018), loaded once from CSVs with no recurring ingestion and no real "loaded at" timestamp. Checking freshness against event timestamps (e.g. `order_purchase_timestamp`) would always report stale data, so it was left out as not applicable to this dataset.
