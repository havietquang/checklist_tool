{{ config(
    alias = 'v_stg_bpm_auth_nhom',
    materialized = 'view',
    tags = ['bpm', 'reference', 'phase1', 'all']
) }}

{% set source_name = "bpm" -%}
{% set source_table = "auth_nhom" -%}
{% set business_key_cols = ['id', 'ma_nhom'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict = none -%}

{% if execute -%}
{%- set columns = get_columns(source(source_name, source_table)) -%}
{% set list_cols = ['id', 'ten_nhom_viet_tat', 'ten_nhom_day_du', 'trang_thai', 'ghi_chu', 'ocb_hrm_id', 'nhom_cap_tren', 'search_scope', 'nhom_dai_dien', 'cap_phe_duyet', 'ma_nhom', 'quy_trinh', 'cap_do', 'cap_do_tim_kiem', 'cap_do_ecm', 'cap_do_ecm_xlgdtd', 'cap_do_ecm_tsbd', 'json_ecm', 'ma_nhom_ten'] -%}

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
