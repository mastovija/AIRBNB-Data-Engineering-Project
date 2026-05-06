WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_listings') }}
)

SELECT
    TRY_CAST(id AS INTEGER)          AS listing_id,
    TRIM(neighbourhood_cleansed)     AS neighbourhood_cleansed,
    TRY_CAST(latitude AS FLOAT)      AS latitude,
    TRY_CAST(longitude AS FLOAT)     AS longitude,
    city

FROM source