{{ config(
    alias = 'hub_users_logon',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['users_logon_hashkey'],
    skip_matched_step = true,
    tags = ['newfo', 'zonec', 'all']
) }}

{% set source_name = 'newfo' %}
{% set unique_key = 'users_logon_hashkey' %}
{% set business_key = 'user_id' %}
{% set source_table = 'users_logon' %}
{% set source_model = 'v_stg_newfo_users_logon' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}
