{{ config(
    alias = 'hub_md_3544_san_pham_t24',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['md_3544_san_pham_t24_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set unique_key = 'md_3544_san_pham_t24_hashkey' %}
{% set business_key = 'id' %}
{% set source_table = 'md_3544_san_pham_t24' %}
{% set source_model = 'v_stg_bpm_md_3544_san_pham_t24' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}
