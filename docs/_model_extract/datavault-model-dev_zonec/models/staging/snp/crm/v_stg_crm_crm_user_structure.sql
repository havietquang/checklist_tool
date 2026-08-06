{{ config(
    alias = 'v_stg_crm_crm_user_structure',
    materialized = 'view',
    tags = ['crm', 'crm_user_structure', 'zonec']
) }}

{% set source_name = "crm" -%}
{% set source_table = "crm_user_structure" -%}
{% set business_key_cols = ['user_id'] -%}
{% set ma_key_expr = "src.user_manager_id" -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}
{% set hashdiff_satellite_dict = {
    'hashdiff_crm_user_structure': ['ma_key', 'user_manager_id', 'custgroup', 'branch_code', 'division_id', 'user_created', 'datetime_created', 'user_updated', 'datetime_updated', 'user_sale_code', 'user_manager_sale_code'],
} -%}

/*
------------------------------------------------------------------------
STAGE MACRO CALL
------------------------------------------------------------------------
Raw_sql tu viet (theo pattern v_stg_t24_t24_crb) de sinh them cot ma_key
(user_manager_id) - mot user_id co the co nhieu dong voi user_manager_id
khac nhau. business_key_cols van la ['user_id'].
------------------------------------------------------------------------
*/

{% if execute -%}
{%- set columns = get_columns(source(source_name, source_table)) -%}
{%- set cols_name = [] -%}
{%- for column in columns -%}{%- do cols_name.append(column.name) -%}{%- endfor -%}

{%- set raw_sql %}
with source_data as (
    select
        {% for column in columns %}src.{{ column.name }},
        {% endfor %}
        {{ ma_key_expr }} as ma_key
    from {{ source(source_name, source_table) }} src
    {%- if source_event_date_col is not none %}
    where {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
    {%- endif %}
)

select
    --HASH KEY
    {{ hash_column(business_key_cols, source_name) }} as hashkey,

    --ALL COLUMNS FROM SOURCE TABLE
    {% for column in columns %}{{ column.name }},
    {% endfor %}

    --DERIVED BUSINESS KEYS
    ma_key,

    --HASHDIFF FULL
    {{ hash_column(cols_name, source_name) }} as hashdiff_full,

    --HASHDIFF SATELLITES
    {% for k, v in hashdiff_satellite_dict.items() %}{{ hash_column(v, source_name) }} as {{ k }},
    {% endfor %}

    --TIME & SOURCE COLUMNS
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    '{{ source_name }}' as record_source,
    cast(current_timestamp as timestamp) as load_timestamp

from source_data
{%- endset %}

{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=hashdiff_satellite_dict,
    source_event_date_col=source_event_date_col,
    source_event_date_dttype=source_event_date_dttype,
    source_name=source_name,
    raw_sql=raw_sql
) }}
{% endif -%}
