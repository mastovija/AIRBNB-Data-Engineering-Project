-- =============================================================
-- dim_host_snapshot
-- Implementa SCD Tipo 2 sobre dim_host.
-- Cada vez que se ejecuta dbt snapshot, dbt compara los valores
-- actuales de check_cols con los del snapshot anterior.
-- Si detecta un cambio (por ejemplo un host pasa de 2 a 5
-- listings o cambia de categoría), cierra el registro anterior
-- (dbt_valid_to = fecha actual) e inserta uno nuevo
-- (dbt_valid_from = fecha actual, dbt_valid_to = NULL).
--
-- Con un único snapshot se explica el mecanismo.
-- Con dos snapshots se demuestra en producción: cargar el
-- snapshot de septiembre 2025 + ejecutar dbt snapshot muestra
-- hosts que cambiaron de perfil entre fechas.
-- =============================================================

{% snapshot dim_host_snapshot %}

    {{
        config(
            target_schema='GOLD',
            target_database=env_var('DBT_DATABASE_GOLD', 'AIRBNB_DEV_GOLD'),
            unique_key='host_sk',
            strategy='check',
            check_cols=['calculated_host_listings_count', 'host_profile'],
            invalidate_hard_deletes=True
        )
    }}

    -- Fuente: dim_host ya deduplicada (una fila por host_id + city)
    SELECT
        host_sk,
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
    FROM {{ ref('dim_host') }}

{% endsnapshot %}