{{ config(
    alias = 'v_stg_bpm_xl_ct_tsbd',
    materialized = 'view',
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = "bpm" %}
{% set source_table = "xl_ct_tsbd" %}
{% set business_key_cols = ['ksgn.ma_giao_dich'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set raw_sql %}
select
    {{ hash_column(['ksgn.ma_giao_dich'], source_name) }} as hashkey,
    ct.xl_tsbd_id,
    ct.loai_tsbd,
    ct.so_luong_tsbd,
    ct.ngay_tao,
    ct.nguoi_tao,
    ct.ben_ngoai_bpm,
    ct.gd_chinh_id,
    {{ hash_column(['ct.xl_tsbd_id', 'ct.loai_tsbd', 'ct.so_luong_tsbd', 'ct.ngay_tao', 'ct.nguoi_tao', 'ct.ben_ngoai_bpm', 'ct.gd_chinh_id'], source_name) }} as hashdiff_full,
    {{ hash_column(['ct.xl_tsbd_id', 'ct.loai_tsbd', 'ct.so_luong_tsbd', 'ct.ngay_tao', 'ct.nguoi_tao', 'ct.ben_ngoai_bpm', 'ct.gd_chinh_id'], source_name) }} as hashdiff_xl_ct_tsbd,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    '{{ source_name }}' as record_source,
    cast(current_timestamp as timestamp) as load_timestamp
from {{ source(source_name, 'xl_ct_tsbd') }} ct
join {{ source(source_name, 'xl_ksgn_chung') }} ksgn on ct.gd_chinh_id = ksgn.gd_chinh_id
{% if source_event_date_col is not none %}
where {{ to_yyyymmdd_str('ct.' ~ source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
{% endif %}
{% endset %}

{% if execute -%}
{{ stage(source_table=source_table
        ,business_key_cols=business_key_cols
        ,hashdiff_satellite_dict={'hashdiff_xl_ct_tsbd': ['xl_tsbd_id', 'loai_tsbd', 'so_luong_tsbd', 'ngay_tao', 'nguoi_tao', 'ben_ngoai_bpm', 'gd_chinh_id']}
        ,source_event_date_col=source_event_date_col
        ,source_event_date_dttype=source_event_date_dttype
        ,source_name=source_name
        ,raw_sql=raw_sql)
}}
{% endif -%}
