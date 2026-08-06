{{ config(
    alias = 'hub_auth_to_chuc_dvi_link',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['auth_to_chuc_dvi_link_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set unique_key = 'auth_to_chuc_dvi_link_hashkey' %}
{% set business_key = 'id' %}
{% set source_table = 'auth_to_chuc_dvi_link' %}
{% set source_model = 'v_stg_bpm_auth_to_chuc_dvi_link' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}
