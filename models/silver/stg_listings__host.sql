-- =============================================================
-- stg_listings__host
-- Información del anfitrión por listing.
-- IMPORTANTE: esta tabla tiene UNA FILA POR LISTING, no una
-- por host. Un host con 5 listings aparece 5 veces. La
-- deduplicación a una fila por host se hace en dim_host (Gold).
-- Columnas clave para el proyecto: host_profile clasifica al
-- host en tres niveles de profesionalización (caso de uso 2.1)
-- y host_seniority_years permite analizar la veteranía.
-- =============================================================

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_listings') }}
)

SELECT
    TRY_CAST(host_id AS INTEGER)                                    AS host_id,

    -- listing_id es FK hacia stg_listings__details.
    -- Necesario para poder unir esta tabla con el resto de Silver.
    TRY_CAST(id AS INTEGER)                                         AS listing_id,

    host_name,

    -- host_since viene como string 'YYYY-MM-DD' en Bronze
    TRY_TO_DATE(host_since, 'YYYY-MM-DD')                          AS host_since,

    -- Antigüedad del host en años completos desde que se registró.
    -- Permite analizar si los hosts más veteranos tienen más
    -- propiedades o mejores valoraciones (usado en mart_host_profile).
    DATEDIFF('year',
        TRY_TO_DATE(host_since, 'YYYY-MM-DD'),
        CURRENT_DATE())                                             AS host_seniority_years,

    -- Bronze almacena booleanos como 't'/'f' en texto
    CASE
        WHEN host_is_superhost = 't' THEN TRUE
        ELSE FALSE
    END                                                             AS host_is_superhost,

    host_response_time,

    -- Los porcentajes vienen como string '95%' — hay que quitar el %
    -- y convertir a número para poder calcular medias en Gold
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

    -- calculated_host_listings_count es más fiable que host_listings_count
    -- porque Inside Airbnb lo calcula a partir del scraping real,
    -- no de lo que el host declara. Es específico por ciudad.
    TRY_CAST(calculated_host_listings_count AS INTEGER)             AS calculated_host_listings_count,
    TRY_CAST(calculated_host_listings_count_entire_homes AS INTEGER) AS calc_listings_entire_homes,
    TRY_CAST(calculated_host_listings_count_private_rooms AS INTEGER) AS calc_listings_private_rooms,
    TRY_CAST(calculated_host_listings_count_shared_rooms AS INTEGER) AS calc_listings_shared_rooms,

    -- Clasificación del host en tres niveles según el número de
    -- viviendas completas que gestiona (no listings totales).
    -- Usar entire_homes en lugar del total distingue al inversor
    -- profesional del host que alquila habitaciones privadas.
    -- Esta columna es el núcleo del Bloque 2 del proyecto.
    CASE
        WHEN TRY_CAST(calculated_host_listings_count_entire_homes AS INTEGER) >= 5
            THEN 'Operador profesional'
        WHEN TRY_CAST(calculated_host_listings_count_entire_homes AS INTEGER) >= 2
            THEN 'Multipropiedad'
        ELSE 'Host individual'
    END                                                             AS host_profile,

    city

FROM source