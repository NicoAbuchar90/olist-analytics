with items as (

    select * from {{ ref('int_order_items_sellers') }}

),

successful_items as (

    select *
    from items
    where order_status in ('delivered', 'shipped')

),

seller_monthly as (

    select
        seller_id,
        seller_state,
        order_month,
        count(distinct order_id) as n_orders,
        count(*) as n_items,
        round(sum(price), 2) as revenue,
        round(sum(freight_value), 2) as freight

    from successful_items
    group by seller_id, seller_state, order_month

)

select * from seller_monthly
