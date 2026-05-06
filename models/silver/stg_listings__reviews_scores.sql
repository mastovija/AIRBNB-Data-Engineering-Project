WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_listings') }}
)

SELECT
    TRY_CAST(id AS INTEGER)                     AS listing_id,
    TRY_CAST(number_of_reviews AS INTEGER)      AS number_of_reviews,
    TRY_CAST(number_of_reviews_ltm AS INTEGER)  AS number_of_reviews_ltm,
    TRY_CAST(number_of_reviews_l30d AS INTEGER) AS number_of_reviews_l30d,
    TRY_CAST(number_of_reviews_ly AS INTEGER)   AS number_of_reviews_ly,
    TRY_CAST(reviews_per_month AS FLOAT)        AS reviews_per_month,
    TRY_TO_DATE(first_review, 'YYYY-MM-DD')    AS first_review,
    TRY_TO_DATE(last_review, 'YYYY-MM-DD')     AS last_review,
    DATEDIFF(
        'day',
        TRY_TO_DATE(last_review, 'YYYY-MM-DD'),
        CURRENT_DATE())                         AS days_since_last_review,
    TRY_CAST(review_scores_rating AS FLOAT)     AS review_scores_rating,
    TRY_CAST(review_scores_accuracy AS FLOAT)   AS review_scores_accuracy,
    TRY_CAST(review_scores_cleanliness AS FLOAT) AS review_scores_cleanliness,
    TRY_CAST(review_scores_checkin AS FLOAT)    AS review_scores_checkin,
    TRY_CAST(review_scores_communication AS FLOAT) AS review_scores_communication,
    TRY_CAST(review_scores_location AS FLOAT)   AS review_scores_location,
    TRY_CAST(review_scores_value AS FLOAT)      AS review_scores_value,
    city

FROM source