{{ config(
    alias = 'hub_aa_arrangement',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['aa_arrangement_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'zonec', 'all']
) }}

{% set source_name = 't24' %}
{% set unique_key = 'aa_arrangement_hashkey' %}
{% set business_key = 'id' %}
{% set source_table = 't24_aa_arrangement' %}
{% set source_model = 'v_stg_t24_t24_aa_arrangement' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}
