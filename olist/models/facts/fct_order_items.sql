{{
    config(
        materialized='incremental',
        unique_key='order_item_key',
        incremental_strategy='merge',
        partition_by={
            'field': 'purchased_at',
            'data_type': 'timestamp',
            'granularity': 'day'
        }
    )
}}

with int_items as (

    select * from {{ ref('int_order_items_sellers') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['order_id', 'order_item_id']) }} as order_item_key,
        order_id,
        order_item_id,
        product_id,
        seller_id,
        price,
        freight_value,
        order_status,
        purchased_at,
        order_month,
        seller_city,
        seller_state

    from int_items

    {% if is_incremental() %}

    where purchased_at > (select max(purchased_at) from {{ this }})

    {% endif %}

)

select * from final