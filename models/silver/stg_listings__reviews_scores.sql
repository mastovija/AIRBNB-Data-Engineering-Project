-- =============================================================
-- stg_listings__reviews_scores
-- Puntuaciones y métricas de actividad de reviews por listing.
-- Alimenta fact_listings en Gold con indicadores de calidad
-- y actividad reciente.
-- Columna calculada clave: days_since_last_review, que junto
-- con number_of_reviews_ltm se usa en Gold para determinar
-- si un listing está realmente activo (is_active_listing).
-- =============================================================

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_listings') }}
)

SELECT
    TRY_CAST(id AS INTEGER)                     AS listing_id,

    -- Volumen histórico total de reviews del listing
    TRY_CAST(number_of_reviews AS INTEGER)      AS number_of_reviews,

    -- Reviews en los últimos 12 meses: proxy de actividad reciente.
    -- Un listing sin reviews en el último año probablemente está
    -- inactivo aunque siga publicado en Airbnb.
    TRY_CAST(number_of_reviews_ltm AS INTEGER)  AS number_of_reviews_ltm,

    TRY_CAST(number_of_reviews_l30d AS INTEGER) AS number_of_reviews_l30d,
    TRY_CAST(number_of_reviews_ly AS INTEGER)   AS number_of_reviews_ly,
    TRY_CAST(reviews_per_month AS FLOAT)        AS reviews_per_month,

    TRY_TO_DATE(first_review, 'YYYY-MM-DD')    AS first_review,
    TRY_TO_DATE(last_review, 'YYYY-MM-DD')     AS last_review,

    -- Días transcurridos desde la última review hasta hoy.
    -- Se calcula en Silver para no repetir esta lógica en cada
    -- modelo de Gold que necesite detectar listings inactivos.
    -- Un listing con >180 días sin review se considera inactivo.
    DATEDIFF(
        'day',
        TRY_TO_DATE(last_review, 'YYYY-MM-DD'),
        CURRENT_DATE())                         AS days_since_last_review,

    -- Puntuaciones del 1 al 5 en cada dimensión de calidad.
    -- TRY_CAST devuelve NULL si el valor no es numérico,
    -- sin romper la pipeline (listings sin reviews tienen NULL aquí).
    TRY_CAST(review_scores_rating AS FLOAT)     AS review_scores_rating,
    TRY_CAST(review_scores_accuracy AS FLOAT)   AS review_scores_accuracy,
    TRY_CAST(review_scores_cleanliness AS FLOAT) AS review_scores_cleanliness,
    TRY_CAST(review_scores_checkin AS FLOAT)    AS review_scores_checkin,
    TRY_CAST(review_scores_communication AS FLOAT) AS review_scores_communication,
    TRY_CAST(review_scores_location AS FLOAT)   AS review_scores_location,
    TRY_CAST(review_scores_value AS FLOAT)      AS review_scores_value,

    city

FROM source