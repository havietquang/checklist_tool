{{ config(
    alias = 'link_tdcn_st_van_kien_giao_dich',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_tdcn_st_van_kien_giao_dich_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tdcn_st_van_kien' %}
{% set source_model = 'v_stg_bpm_tdcn_st_van_kien' %}
{% set raw_sql = None %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = 'link_tdcn_st_van_kien_giao_dich_hashkey',
    source_business_key_cols = ['id', 'gd_id'],
    foreign_business_key_cols = {
        'tdcn_st_van_kien_hashkey': ['id'],
        'giao_dich_hashkey': ['gd_id'],
    }
) }}
