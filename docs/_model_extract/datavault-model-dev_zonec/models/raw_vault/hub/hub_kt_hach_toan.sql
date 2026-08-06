{{ config(
    alias = 'hub_kt_hach_toan',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['kt_hach_toan_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set unique_key = 'kt_hach_toan_hashkey' %}
{% set business_key = 'id' %}
{% set source_table = 'kt_hach_toan' %}
{% set source_model = 'v_stg_bpm_kt_hach_toan' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}
