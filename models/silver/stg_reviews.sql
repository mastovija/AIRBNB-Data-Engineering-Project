WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_reviews') }}
)

SELECT
    TRY_CAST(id AS INTEGER)                         AS review_id,
    TRY_CAST(listing_id AS INTEGER)                 AS listing_id,
    TRY_CAST(reviewer_id AS INTEGER)                AS reviewer_id,
    TRY_TO_DATE(date, 'YYYY-MM-DD')                AS review_date,
    YEAR(TRY_TO_DATE(date, 'YYYY-MM-DD'))           AS review_year,
    MONTH(TRY_TO_DATE(date, 'YYYY-MM-DD'))          AS review_month,
    DATE_TRUNC('month', TRY_TO_DATE(date, 'YYYY-MM-DD')) AS review_month_start,
    city

FROM source