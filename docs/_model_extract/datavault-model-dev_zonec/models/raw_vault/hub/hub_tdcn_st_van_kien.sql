{{ config(
    alias = 'hub_tdcn_st_van_kien',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['tdcn_st_van_kien_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set unique_key = 'tdcn_st_van_kien_hashkey' %}
{% set business_key = 'id' %}
{% set source_table = 'tdcn_st_van_kien' %}
{% set source_model = 'v_stg_bpm_tdcn_st_van_kien' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}
