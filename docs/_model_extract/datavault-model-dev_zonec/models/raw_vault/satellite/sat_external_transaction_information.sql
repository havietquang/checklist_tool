{{ config(
    alias = 'sat_external_transaction_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['external_transaction_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'external_transaction' %}
{% set hashdiff_col = 'hashdiff_external_transaction_information' %}
{% set hub_hashkey = 'external_transaction_hashkey' %}
{% set source_model = 'v_stg_bpm_external_transaction' %}
{% set list_cols = [
    'refcode',
    'ma_giao_dich',
    'ngay_tao',
    'source',
    'process_id',
    'process_type',
    'ho_ten',
    'so_cif',
    'ngay_sinh',
    'so_dien_thoai',
    'email',
    'san_pham_id',
    'loai_san_pham',
    'so_tien_vay_dx',
    'thoi_han_vay'
] %}
{% set raw_sql = None %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}
