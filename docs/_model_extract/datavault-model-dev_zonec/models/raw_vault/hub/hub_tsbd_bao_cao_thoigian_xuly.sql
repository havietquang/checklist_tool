{{ config(
    alias = 'hub_tsbd_bao_cao_thoigian_xuly',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['tsbd_bao_cao_thoigian_xuly_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set unique_key = 'tsbd_bao_cao_thoigian_xuly_hashkey' %}
{% set business_key = 'id' %}
{% set source_table = 'tsbd_bao_cao_thoigian_xuly' %}
{% set source_model = 'v_stg_bpm_tsbd_bao_cao_thoigian_xuly' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}
