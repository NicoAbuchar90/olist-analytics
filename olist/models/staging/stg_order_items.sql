WITH source AS (

    SELECT * FROM {{ source('olist_raw', 'olist_order_items') }}

),

renamed AS (

    SELECT
        order_id,
        order_item_id,
        product_id,
        seller_id,
        cast(shipping_limit_date AS timestamp) AS shipping_limit_at,
        price,
        freight_value

    FROM source

)

SELECT * FROM renamed
