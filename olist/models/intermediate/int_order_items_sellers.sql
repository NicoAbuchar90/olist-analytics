WITH order_items AS (
    SELECT * FROM {{ ref('stg_order_items') }}
),

orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

sellers AS (
    SELECT * FROM {{ ref('stg_sellers') }}
),

joined AS (
    SELECT
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        oi.price,
        oi.freight_value,
        o.order_status,
        o.purchased_at,
        date_trunc(date(o.purchased_at), MONTH) AS order_month,
        s.seller_city,
        s.seller_state

    FROM order_items AS oi
    INNER JOIN orders AS o
        ON oi.order_id = o.order_id
    LEFT JOIN sellers AS s
        ON oi.seller_id = s.seller_id
)

SELECT * FROM joined
