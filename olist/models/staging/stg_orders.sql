WITH source AS (

    SELECT * FROM {{ source('olist_raw', 'olist_orders') }}

),

renamed AS (

    SELECT
        order_id,
        customer_id,
        order_status,
        cast(order_purchase_timestamp AS timestamp) AS purchased_at,
        cast(order_approved_at AS timestamp) AS approved_at,
        cast(order_delivered_carrier_date AS timestamp) AS delivered_to_carrier_at,
        cast(order_delivered_customer_date AS timestamp) AS delivered_to_customer_at,
        cast(order_estimated_delivery_date AS timestamp) AS estimated_delivery_at

    FROM source

)

SELECT * FROM renamed
