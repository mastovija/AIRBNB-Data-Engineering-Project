-- =============================================================
-- dim_host
-- Una fila por host único (deduplicada por host_id + city).
-- PROBLEMA DE ORIGEN: stg_listings__host tiene una fila por
-- listing, no por host. Un host con 5 listings aparece 5 veces.
-- Esta tabla colapsa eso en una fila por host y ciudad.
--
-- Por qué la clave es host_id + city (no solo host_id):
-- Inside Airbnb calcula calculated_host_listings_count por ciudad.
-- Un host con 3 listings en Sevilla y 2 en Málaga tiene valores
-- distintos en cada ciudad — son entidades analíticamente distintas.
--
-- Para el SCD Tipo 2: esta tabla es la base. El snapshot de dbt
-- (snapshots/dim_host_snapshot.sql) añade valid_from, valid_to
-- e is_current para rastrear cambios históricos entre snapshots.
-- =============================================================

WITH source AS (
    SELECT * FROM {{ ref('stg_listings__host') }}
),

deduped AS (
    SELECT
        host_id,
        city,
        host_name,
        host_since,
        host_seniority_years,
        host_is_superhost,
        calculated_host_listings_count,
        calc_listings_entire_homes,
        host_profile,
        -- is_multihost: TRUE si el host gestiona más de un listing.
        -- Separa el particular que alquila su casa del inversor.
        CASE
            WHEN calculated_host_listings_count > 1 THEN TRUE
            ELSE FALSE
        END AS is_multihost
    FROM source
    WHERE host_id IS NOT NULL
    -- QUALIFY con ROW_NUMBER elimina duplicados manteniendo solo
    -- una fila por host_id + city. Se ordena por
    -- calculated_host_listings_count DESC para quedarse con el
    -- registro más completo en caso de inconsistencias en la fuente.
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY host_id, city
        ORDER BY calculated_host_listings_count DESC
    ) = 1
)

SELECT
    -- Surrogate key generada con dbt_utils: hash MD5 de host_id + city.
    -- Necesaria para el SCD Tipo 2 — la FK en fact_listings apunta
    -- a host_sk, no a host_id, para poder rastrear versiones históricas.
    {{ dbt_utils.generate_surrogate_key(['host_id', 'city']) }}
                                        AS host_sk,
    host_id,
    city,
    host_name,
    host_since,
    host_seniority_years,
    host_is_superhost,
    calculated_host_listings_count,
    calc_listings_entire_homes,
    host_profile,
    is_multihost
FROM deduped