WITH source AS (

    SELECT * FROM {{ source('olist_raw', 'product_category_name_translation') }}

),

renamed AS (

    SELECT
        product_category_name,
        product_category_name_english

    FROM source

)

SELECT * FROM renamed
