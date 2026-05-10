-- =============================================================
-- dim_neighbourhood
-- Una fila por barrio y ciudad.
-- Dimensión minimalista: solo atributos descriptivos estables
-- (nombre del barrio y ciudad). Las métricas agregadas por barrio
-- (pct_entire_home, avg_price, etc.) van en mart_neighbourhood_pressure,
-- no aquí, porque cambian con cada snapshot de datos.
--
-- La clave natural es neighbourhood_cleansed + city porque el
-- mismo nombre de barrio puede existir en las dos ciudades.
-- El surrogate key neighbourhood_id se genera con dbt_utils
-- para usarlo como FK en fact_listings y dim_listing.
-- =============================================================

WITH source AS (
    -- DISTINCT elimina los duplicados que surgen de que cada listing
    -- tiene su propio barrio — necesitamos una fila por barrio único
    SELECT DISTINCT
        TRIM(neighbourhood_cleansed) AS neighbourhood_cleansed,
        city
    FROM {{ ref('stg_listings__location') }}
    WHERE neighbourhood_cleansed IS NOT NULL
        AND TRIM(neighbourhood_cleansed) != 'no asignado'
)

SELECT
    -- Hash MD5 de neighbourhood_cleansed + city.
    -- Determinista: el mismo barrio siempre genera el mismo ID,
    -- lo que garantiza que los joins en fact_listings sean estables
    -- entre ejecuciones de dbt.
    {{ dbt_utils.generate_surrogate_key(
        ['neighbourhood_cleansed', 'city']
    ) }}                        AS neighbourhood_id,
    neighbourhood_cleansed,
    city
FROM source