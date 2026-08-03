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

WITH int_items AS (

    SELECT * FROM {{ ref('int_order_items_sellers') }}

),

final AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key(['order_id', 'order_item_id']) }} AS order_item_key,
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

    FROM int_items

    {% if is_incremental() %}

        WHERE int_items.purchased_at > (SELECT max(existing.purchased_at) FROM {{ this }} AS existing)

    {% endif %}

)

SELECT * FROM final
