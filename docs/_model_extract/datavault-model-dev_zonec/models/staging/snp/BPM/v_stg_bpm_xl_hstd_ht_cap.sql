{{ config(
    alias = 'v_stg_bpm_xl_hstd_ht_cap',
    materialized = 'view',
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = "bpm" %}
{% set source_table = "xl_hstd_ht_cap" %}
{% set business_key_cols = ['ksgn.ma_giao_dich'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set raw_sql %}
select
    {{ hash_column(['ksgn.ma_giao_dich'], source_name) }} as hashkey,
    hstd.hthuc_cap_id,
    hstd.loai_van_kien,
    hstd.van_kien_ct,
    hstd.ngay_tao,
    hstd.nguoi_tao,
    hstd.ghi_chu,
    hstd.don_vi_xu_ly,
    hstd.ben_ngoai_bpm,
    hstd.so_luong,
    hstd.gd_chinh_id,
    {{ hash_column(['hstd.hthuc_cap_id', 'hstd.loai_van_kien', 'hstd.van_kien_ct', 'hstd.ngay_tao', 'hstd.nguoi_tao', 'hstd.ghi_chu', 'hstd.don_vi_xu_ly', 'hstd.ben_ngoai_bpm', 'hstd.so_luong', 'hstd.gd_chinh_id'], source_name) }} as hashdiff_full,
    {{ hash_column(['hstd.hthuc_cap_id', 'hstd.loai_van_kien', 'hstd.van_kien_ct', 'hstd.ngay_tao', 'hstd.nguoi_tao', 'hstd.ghi_chu', 'hstd.don_vi_xu_ly', 'hstd.ben_ngoai_bpm', 'hstd.so_luong', 'hstd.gd_chinh_id'], source_name) }} as hashdiff_xl_hstd_ht_cap,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    '{{ source_name }}' as record_source,
    cast(current_timestamp as timestamp) as load_timestamp
from {{ source(source_name, 'xl_hstd_ht_cap') }} hstd
join {{ source(source_name, 'xl_ksgn_chung') }} ksgn on hstd.gd_chinh_id = ksgn.gd_chinh_id
{% if source_event_date_col is not none %}
where {{ to_yyyymmdd_str('hstd.' ~ source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
{% endif %}
{% endset %}

{% if execute -%}
{{ stage(source_table=source_table
        ,business_key_cols=business_key_cols
        ,hashdiff_satellite_dict={'hashdiff_xl_hstd_ht_cap': ['hthuc_cap_id', 'loai_van_kien', 'van_kien_ct', 'ngay_tao', 'nguoi_tao', 'ghi_chu', 'don_vi_xu_ly', 'ben_ngoai_bpm', 'so_luong', 'gd_chinh_id']}
        ,source_event_date_col=source_event_date_col
        ,source_event_date_dttype=source_event_date_dttype
        ,source_name=source_name
        ,raw_sql=raw_sql)
}}
{% endif -%}
