-- depends_on: {{ ref('v_stg_bpm_y_kien_ycbs') }}
-- depends_on: {{ ref('link_y_kien_ycbs_ksgn') }}

{{ config(
    alias = 'effsat_link_y_kien_ycbs_ksgn',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_y_kien_ycbs_ksgn_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_model = 'v_stg_bpm_y_kien_ycbs' %}
{% set source_name = 'bpm' %}
{% set source_table = 'y_kien_ycbs' %}
{% set link_model = 'link_y_kien_ycbs_ksgn' %}
{% set unique_key = 'link_y_kien_ycbs_ksgn_hashkey' %}

{{ effsat(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    source_business_key_cols = ['id', 'ma_giao_dich'],
    link_model = link_model
) }}
