WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_listings') }}
),

price_cleaned AS (
    SELECT
        *,
        TRY_CAST(
            REPLACE(REPLACE(price, '$', ''), ',', '') AS FLOAT
        ) AS price_numeric
    FROM source
),

percentiles AS (
    SELECT
        city,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY price_numeric) AS p99_price
    FROM price_cleaned
    WHERE price_numeric IS NOT NULL
    GROUP BY city
),

final AS (
    SELECT
        TRY_CAST(pc.id AS INTEGER)                              AS listing_id,
        pc.price                                                AS price_raw,
        pc.price_numeric,
        LEAST(pc.price_numeric, p.p99_price)                   AS price_winsorized,
        LEAST(pc.price_numeric, p.p99_price)
            / NULLIF(TRY_CAST(pc.accommodates AS INTEGER), 0)  AS price_per_person,
        TRY_CAST(pc.minimum_nights AS INTEGER)                  AS minimum_nights,
        TRY_CAST(pc.maximum_nights AS INTEGER)                  AS maximum_nights,
        CASE
            WHEN pc.has_availability = 't' THEN TRUE
            ELSE FALSE
        END                                                     AS has_availability,
        TRY_CAST(pc.availability_30 AS INTEGER)                 AS availability_30,
        TRY_CAST(pc.availability_60 AS INTEGER)                 AS availability_60,
        TRY_CAST(pc.availability_90 AS INTEGER)                 AS availability_90,
        TRY_CAST(pc.availability_365 AS INTEGER)                AS availability_365,
        CASE
            WHEN TRY_CAST(pc.availability_365 AS INTEGER) > 180 THEN TRUE
            ELSE FALSE
        END                                                     AS is_high_availability,
        CASE
            WHEN TRY_CAST(pc.availability_365 AS INTEGER) < 60
                THEN 'Casi sin disponibilidad'
            WHEN TRY_CAST(pc.availability_365 AS INTEGER) < 180
                THEN 'Uso parcial'
            ELSE 'Alta disponibilidad'
        END                                                     AS availability_profile,
        TRY_CAST(pc.estimated_occupancy_l365d AS FLOAT)         AS estimated_occupancy_l365d,
        TRY_CAST(
            REPLACE(REPLACE(pc.estimated_revenue_l365d, '$', ''), ',', '')
            AS FLOAT)                                           AS estimated_revenue_l365d,
        TRY_TO_DATE(pc.last_scraped, 'YYYY-MM-DD')             AS last_scraped,
        pc.city

    FROM price_cleaned pc
    LEFT JOIN percentiles p ON pc.city = p.city
)

SELECT * FROM final