{{ config(
    alias = 'v_stg_bpm_danh_muc',
    materialized = 'view',
    tags = ['bpm', 'reference', 'phase1', 'all']
) }}

{% set source_name = "bpm" -%}
{% set source_table = "danh_muc" -%}
{% set business_key_cols = ['id', 'loai'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict = none -%}

{% if execute -%}
{%- set columns = get_columns(source(source_name, source_table)) -%}
{% set list_cols = ['id', 'ma', 'ten', 'loai', 'ghi_chu', 'stt', 'trang_thai', 'nguoi_tao', 'nguoi_update', 'ngay_update'] -%}

{%- set raw_sql %}
select
    {{ hash_column(business_key_cols, source_name) }} as hashkey,
    {% for column in columns %}src.{{ column.name }},
    {% endfor %}
    {{ hash_column(list_cols, source_name) }} as hashdiff_full,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    '{{ source_name }}' as record_source,
    cast(current_timestamp as timestamp) as load_timestamp
from {{ source(source_name, source_table) }} src
{%- endset %}

{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=hashdiff_satellite_dict,
    source_event_date_col=source_event_date_col,
    source_name=source_name,
    raw_sql=raw_sql
) }}
{% endif -%}
