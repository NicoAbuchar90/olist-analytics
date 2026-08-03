WITH monthly AS (

    SELECT * FROM {{ ref('seller_monthly_activity') }}

),

-- 1. cohorte de cada seller = mes de su primera venta
seller_cohort AS (

    SELECT
        seller_id,
        min(order_month) AS cohort_month
    FROM monthly
    GROUP BY seller_id

),

-- 2. cada mes activo del seller + su cohorte + tenure
activity_with_cohort AS (

    SELECT
        m.seller_id,
        c.cohort_month,
        m.order_month,
        date_diff(m.order_month, c.cohort_month, MONTH) + 1 AS tenure,
        m.revenue
    FROM monthly AS m
    INNER JOIN seller_cohort AS c
        ON m.seller_id = c.seller_id

),

-- 3. retención: cuántos sellers activos por cohorte y tenure
cohort_retention AS (

    SELECT
        cohort_month,
        order_month,
        tenure,
        count(DISTINCT seller_id) AS n_active_sellers,
        round(sum(revenue), 2) AS cohort_revenue
    FROM activity_with_cohort
    GROUP BY cohort_month, order_month, tenure

)

SELECT * FROM cohort_retention
ORDER BY order_month, cohort_month, tenure
