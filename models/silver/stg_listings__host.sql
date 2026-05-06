WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_listings') }}
)

SELECT
    TRY_CAST(host_id AS INTEGER)                                    AS host_id,
    TRY_CAST(id AS INTEGER)                                         AS listing_id,
    host_name,
    TRY_TO_DATE(host_since, 'YYYY-MM-DD')                          AS host_since,
    DATEDIFF('year',
        TRY_TO_DATE(host_since, 'YYYY-MM-DD'),
        CURRENT_DATE())                                             AS host_seniority_years,
    CASE
        WHEN host_is_superhost = 't' THEN TRUE
        ELSE FALSE
    END                                                             AS host_is_superhost,
    host_response_time,
    TRY_CAST(
        REPLACE(host_response_rate, '%', '') AS FLOAT)              AS host_response_rate,
    TRY_CAST(
        REPLACE(host_acceptance_rate, '%', '') AS FLOAT)            AS host_acceptance_rate,
    CASE
        WHEN host_has_profile_pic = 't' THEN TRUE
        ELSE FALSE
    END                                                             AS host_has_profile_pic,
    CASE
        WHEN host_identity_verified = 't' THEN TRUE
        ELSE FALSE
    END                                                             AS host_identity_verified,
    TRY_CAST(calculated_host_listings_count AS INTEGER)             AS calculated_host_listings_count,
    TRY_CAST(calculated_host_listings_count_entire_homes AS INTEGER) AS calc_listings_entire_homes,
    TRY_CAST(calculated_host_listings_count_private_rooms AS INTEGER) AS calc_listings_private_rooms,
    TRY_CAST(calculated_host_listings_count_shared_rooms AS INTEGER) AS calc_listings_shared_rooms,
    CASE
        WHEN TRY_CAST(calculated_host_listings_count_entire_homes AS INTEGER) >= 5
            THEN 'Operador profesional'
        WHEN TRY_CAST(calculated_host_listings_count_entire_homes AS INTEGER) >= 2
            THEN 'Multipropiedad'
        ELSE 'Host individual'
    END                                                             AS host_profile,
    city

FROM source