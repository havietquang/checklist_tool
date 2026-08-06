{{ config(
    alias = 'v_stg_clevertap_events',
    materialized = 'view',
    tags = ['clevertap', 'event', 'phase2', 'all']
) }}
{% set source_name  = "clevertap" -%}
{% set source_table = "events" -%}
{% set business_key_cols = ['ts', 'eventName', 'eventProps', 'profile:identity'] -%}
{% set hashdiff_events_cols = ['profile',
                               'deviceInfo'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set raw_sql %}
with deduped as (
    select *
    from {{ source('clevertap', 'events') }}
    {%- if source_event_date_col is not none %}
    where {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
    {%- endif %}
    qualify row_number() over (
        partition by ts, eventName, eventProps, profile:identity
        order by deviceInfo desc nulls last 
    ) = 1
)
select
    {{ hash_column(business_key_cols, source_name, false) }}       as hashkey,
    *,
    {{ hash_column(hashdiff_events_cols, source_name, false) }}    as hashdiff_events_information,
    to_date('{{ var("target_date") }}', 'yyyyMMdd')         as source_event_date,
    'clevertap'                                             as record_source,
    cast(current_timestamp as timestamp)                    as load_timestamp
from deduped
where ts is not null
and eventName is not null
and eventProps is not null
and profile:identity is not null 
{% endset %}
{% if execute -%}
{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=none,
    source_event_date_col=none,
    source_name=source_name,
    raw_sql=raw_sql
) }}
{% endif -%}