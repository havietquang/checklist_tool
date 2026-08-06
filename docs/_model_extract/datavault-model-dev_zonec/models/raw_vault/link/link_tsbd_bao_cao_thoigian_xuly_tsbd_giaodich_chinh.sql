{{ config(
    alias = 'link_tsbd_bao_cao_thoigian_xuly_tsbd_giaodich_chinh',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_tsbd_bao_cao_thoigian_xuly_tsbd_giaodich_chinh_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tsbd_bao_cao_thoigian_xuly' %}
{% set source_model = 'v_stg_bpm_tsbd_bao_cao_thoigian_xuly' %}
{% set raw_sql = None %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = 'link_tsbd_bao_cao_thoigian_xuly_tsbd_giaodich_chinh_hashkey',
    source_business_key_cols = ['id', 'ma_giao_dich'],
    foreign_business_key_cols = {
        'tsbd_bao_cao_thoigian_xuly_hashkey': ['id'],
        'tsbd_giaodich_chinh_hashkey': ['ma_giao_dich'],
    }
) }}
