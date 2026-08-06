{{ config(
    alias = 'hub_passbook',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['passbook_hashkey'],
    skip_matched_step = true,
    tags = ['newfo', 'zonec', 'all']
) }}

{% set source_name = 'newfo' %}
{% set unique_key = 'passbook_hashkey' %}
{% set business_key = 'id' %}
{% set source_table = 'passbook' %}
{% set source_model = 'v_stg_newfo_passbook' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}
