WITH source AS (

    SELECT * FROM {{ source('olist_raw', 'olist_order_payments') }}

),

renamed AS (

    SELECT
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value

    FROM source

)

SELECT * FROM renamed
