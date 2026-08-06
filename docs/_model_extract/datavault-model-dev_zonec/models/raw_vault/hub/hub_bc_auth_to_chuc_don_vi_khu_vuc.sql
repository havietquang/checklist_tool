{{ config(
    alias = 'hub_bc_auth_to_chuc_don_vi_khu_vuc',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['bc_auth_to_chuc_don_vi_khu_vuc_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set unique_key = 'bc_auth_to_chuc_don_vi_khu_vuc_hashkey' %}
{% set business_key = 'id' %}
{% set source_table = 'bc_auth_to_chuc_don_vi_khu_vuc' %}
{% set source_model = 'v_stg_bpm_bc_auth_to_chuc_don_vi_khu_vuc' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}
