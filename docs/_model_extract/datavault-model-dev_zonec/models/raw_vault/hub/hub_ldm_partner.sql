{{ config(
    alias = 'hub_ldm_partner',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['ldm_partner_hashkey'],
    skip_matched_step = true,
    tags = ['qldt', 'zonec', 'all']
) }}

{% set source_name = 'qldt' %}
{% set unique_key = 'ldm_partner_hashkey' %}
{% set business_key = 'partner_id' %}
{% set source_table = 'ldm_partner' %}
{% set source_model = 'v_stg_qldt_ldm_partner' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}
