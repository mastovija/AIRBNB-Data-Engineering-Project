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