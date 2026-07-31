with order_items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

sellers as (
    select * from {{ ref('stg_sellers') }}
),

joined as (
    select
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        oi.price,
        oi.freight_value,
        o.order_status,
        o.purchased_at,
        date_trunc(date(o.purchased_at), month) as order_month,
        s.seller_city,
        s.seller_state

    from order_items as oi
    inner join orders as o
        on oi.order_id = o.order_id
    left join sellers as s
        on oi.seller_id = s.seller_id
)

select * from joined
