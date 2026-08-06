WITH monthly AS (

    SELECT * FROM {{ ref('seller_monthly_activity') }}

),

seller_cohort AS (

    SELECT
        seller_id,
        min(order_month) AS cohort_month
    FROM monthly
    GROUP BY seller_id

),

activity_with_cohort AS (

    SELECT
        m.seller_id,
        c.cohort_month,
        m.order_month,
        m.seller_state,
        date_diff(m.order_month, c.cohort_month, MONTH) + 1 AS tenure,
        m.revenue
    FROM monthly AS m
    INNER JOIN seller_cohort AS c
        ON m.seller_id = c.seller_id

),

cohort_retention AS (

    SELECT
        cohort_month,
        order_month,
        tenure,
        seller_state,
        count(DISTINCT seller_id) AS n_active_sellers,
        round(sum(revenue), 2) AS cohort_revenue
    FROM activity_with_cohort
    GROUP BY cohort_month, order_month, tenure, seller_state

)

SELECT
    cohort_month,
    order_month,
    tenure,
    seller_state,
    n_active_sellers,
    cohort_revenue,
    round(
        n_active_sellers / first_value(n_active_sellers) OVER (
            PARTITION BY cohort_month ORDER BY tenure
        ),
        4
    ) AS retention_pct
FROM cohort_retention
ORDER BY order_month, cohort_month, tenure
