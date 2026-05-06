WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_listings') }}
)

SELECT
    CAST(id AS INTEGER)                          AS listing_id,
    name,
    property_type,
    room_type,
    CASE
        WHEN room_type = 'Entire home/apt' THEN TRUE
        ELSE FALSE
    END                                          AS is_entire_home,
    TRY_CAST(accommodates AS INTEGER)            AS accommodates,
    TRY_CAST(bedrooms AS FLOAT)                  AS bedrooms,
    TRY_CAST(beds AS FLOAT)                      AS beds,
    TRY_CAST(bathrooms AS FLOAT)                 AS bathrooms,
    bathrooms_text,
    amenities,
    CASE
        WHEN instant_bookable = 't' THEN TRUE
        ELSE FALSE
    END                                          AS instant_bookable,
    license,
    city

FROM source