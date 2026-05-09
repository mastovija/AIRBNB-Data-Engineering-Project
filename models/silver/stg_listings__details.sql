-- =============================================================
-- stg_listings__details
-- Información descriptiva del inmueble.
-- Es la tabla central de Silver: todas las demás tablas de
-- listings se unen a esta por listing_id.
-- Alimenta dim_listing en Gold.
-- Columna calculada: is_entire_home — el KPI más importante
-- del proyecto (% de viviendas completas capturadas por Airbnb).
-- =============================================================

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_listings') }}
)

SELECT
    -- CAST (no TRY_CAST) porque id nunca debería ser no numérico.
    -- Si fallara indicaría un problema grave en la fuente.
    CAST(id AS INTEGER)                          AS listing_id,

    name,
    property_type,
    room_type,

    -- Flag derivado de room_type. TRUE significa que el inmueble
    -- completo está dedicado al alquiler turístico — es el indicador
    -- central del Bloque 1: ¿cuánta vivienda está siendo capturada?
    CASE
        WHEN room_type = 'Entire home/apt' THEN TRUE
        ELSE FALSE
    END                                          AS is_entire_home,

    -- Número de personas que admite el listing.
    -- Necesario para calcular price_per_person en stg_listings__availability.
    TRY_CAST(accommodates AS INTEGER)            AS accommodates,

    -- Pueden ser decimales (ej: 0.5 baños = aseo sin ducha)
    TRY_CAST(bedrooms AS FLOAT)                  AS bedrooms,
    TRY_CAST(beds AS FLOAT)                      AS beds,
    TRY_CAST(bathrooms AS FLOAT)                 AS bathrooms,
    bathrooms_text,

    -- amenities viene como array JSON: ["Wifi","Kitchen","TV",...]
    -- Se conserva como texto en Silver. Análisis de amenities es
    -- opcional y se procesaría en Gold si se necesitara.
    amenities,

    -- Bronze almacena booleanos como 't'/'f' en texto
    CASE
        WHEN instant_bookable = 't' THEN TRUE
        ELSE FALSE
    END                                          AS instant_bookable,

    license,
    city

FROM source