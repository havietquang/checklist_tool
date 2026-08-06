{{ config(
    alias = 'hub_y_kien_ycbs',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['y_kien_ycbs_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set unique_key = 'y_kien_ycbs_hashkey' %}
{% set business_key = 'id' %}
{% set source_table = 'y_kien_ycbs' %}
{% set source_model = 'v_stg_bpm_y_kien_ycbs' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}
