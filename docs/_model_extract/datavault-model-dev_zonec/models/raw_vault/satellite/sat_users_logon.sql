{{ config(
    alias = 'sat_users_logon',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['users_logon_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['newfo', 'zonec', 'all']
) }}

{% set source_name = 'newfo' %}
{% set source_table = 'users_logon' %}
{% set hashdiff_col = 'hashdiff_users_logon' %}
{% set hub_hashkey = 'users_logon_hashkey' %}
{% set source_model = 'v_stg_newfo_users_logon' %}
{% set list_cols = [
    'user_last_name',
    'user_first_name',
    'branch_code',
    'user_status',
    'user_t24',
    'till_no',
    'user_created',
    'date_created',
    'user_session'
] %}
{% set raw_sql = None %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}
