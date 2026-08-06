{{ config(
    alias = 'link_kt_hach_toan_giao_dich',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_kt_hach_toan_giao_dich_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'kt_hach_toan' %}
{% set source_model = 'v_stg_bpm_kt_hach_toan' %}
{% set raw_sql = None %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = 'link_kt_hach_toan_giao_dich_hashkey',
    source_business_key_cols = ['id', 'gd_id'],
    foreign_business_key_cols = {
        'kt_hach_toan_hashkey': ['id'],
        'giao_dich_hashkey': ['gd_id'],
    }
) }}
