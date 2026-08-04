WITH items AS (

    SELECT * FROM {{ ref('fct_order_items') }}


),

successful_items AS (

    SELECT *
    FROM items
    WHERE order_status IN ('delivered', 'shipped')
    AND order_month >= date('2017-01-01')

),

seller_monthly AS (

    SELECT
        seller_id,
        seller_state,
        order_month,
        count(DISTINCT order_id) AS n_orders,
        count(*) AS n_items,
        round(sum(price), 2) AS revenue,
        round(sum(freight_value), 2) AS freight

    FROM successful_items
    GROUP BY seller_id, seller_state, order_month

)

SELECT * FROM seller_monthly
