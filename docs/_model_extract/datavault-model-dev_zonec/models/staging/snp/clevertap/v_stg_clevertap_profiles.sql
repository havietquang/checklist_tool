{{ config(
    alias = 'v_stg_clevertap_profiles',
    materialized = 'view',
    tags = ['clevertap', 'profiles', 'all', 'zonec']
) }}
{% set source_name  = "clevertap" -%}
{% set source_table = "profiles" -%}
{% set business_key_cols = ['identity', 'token'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set raw_sql %}
select
    {{ hash_column(business_key_cols, source_name, false) }}                  as hashkey,
    *,
    to_date('{{ var("target_date") }}', 'yyyyMMdd')                         as source_event_date,
    'clevertap'                                                                   as record_source,
    cast(current_timestamp as timestamp)                                    as load_timestamp
from {{ source(source_name, source_table) }}
where (trim(identity)<>'' or trim(token)<>'')
{%- if source_event_date_col is not none %}
  and {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
{%- endif %}
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