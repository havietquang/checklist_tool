/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['bpm', 'phase2'] = filter khi run (dbt run --select tag:bpm)
====================================================================
*/
{{ config(
    alias = 'v_stg_bpm_pdtd_giao_dich_tin_dung',
    materialized = 'view',
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = "bpm" -%}
{% set source_table = "pdtd_giao_dich_tin_dung" -%}
{% set business_key_cols = ['nhom_giao_dich'] -%}
{% set staging_config = get_staging_config(source_name, source_table) -%}
{% set source_event_date_col = staging_config.source_event_date_col -%}
{% set source_event_date_dttype = staging_config.source_event_date_dttype -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_pdtd_giao_dich_tin_dung': ['so_tien_vay_de_xuat','tong_hmrr_100','tong_hmrr_ko_100','tong_dthu_gan_nhat','tong_tsan_gan_nhat','du_no_vay_tctd','ttin_tien_gui','tvay_la_tgui','loai_tsdb','phan_loai_tsdb','ty_le_dam_bao','qche_chovay_bao_khac','qdinh_tin_dung','cstindung_theokh','spham_tindung','tyle_baodam_ngoaile','ngoai_le_cv_nv_ocb','pdnl_upload','ds_xe_mua_khanga','dsdv_banxe_ocb_cnhan','tsbd','csh_tsbd','ploai_bds','dvkd_tpho_trung_uong','tle_cvay_dgia_tsbd','loai_bdsmua','loaikh','kh_nocic_12thang','diaban_dvkd','vitritsbd_khanga','mien_bcao_gsat_tdung','tdiem_bcao_gsat_tdung','ngung_qhtd_ocb_nho_6thang','ngung_qhtd_ocb_nho_3thang','no_qua_han','kqua_bcao_gstd','tdiem_bcao_gstd_3t','tong_hmuc_rui_ro','loai_tdung_da_cap','tsbd_hang_hoa','tdiem_cap_tdung_hon_3thang','kh_mien_tdinh_ttiep','filedinhkem','ngay_tdtt_truocday','no_nhom2_12thang','tthu_dk_pduyet','datadate','json_tin_dung_cap_moi','json_tai_cap','tai_san_dam_bao','to_trinh_goc_id','loai_hinh_vay','nhom_giao_dich','loai_giao_dich','so_tien_da_cap']
}
-%}

{% if execute -%}
{%- set columns = get_columns(source(source_name, source_table)) -%}
{%- set cols_name = [] -%}
{%- for column in columns -%}{%- do cols_name.append(column.name) -%}{%- endfor -%}

{%- set raw_sql %}
select
    {{ hash_column(business_key_cols, source_name) }} as hashkey,
    {% for column in columns %}src.{{ column.name }},
    {% endfor %}
    CAST(src.gdtd_id AS STRING) AS ma_key,
    {{ hash_column(cols_name, source_name) }} as hashdiff_full,
    {% for k, v in hashdiff_satellite_dict.items() %}{{ hash_column(v, source_name) }} as {{ k }},
    {% endfor %}
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    '{{ source_name }}' as record_source,
    cast(current_timestamp as timestamp) as load_timestamp
from {{ source(source_name, source_table) }} src
{% if source_event_date_col is not none %}
where {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
{% endif %}
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY gdtd_id
    ORDER BY etl_time DESC
) = 1
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
