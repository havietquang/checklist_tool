{{ config(
    alias = 'sat_repo_system',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['repo_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'repo', 'phase1', 'all']
) }}

{% set source_name = 't24' %}
{% set source_table = 't24_repo' %}
{% set hashdiff_col = 'hashdiff_repo_system' %}
{% set hub_hashkey = 'repo_hashkey' %}
{% set source_model = 'v_stg_t24_t24_repo' %}
{% set list_cols = ['new_depo', 'business_centre', 'fwd_settlemnt', 'fwd_price', 'fx_rate', 'new_cu_acct_ccy', 'capitalisation'] %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}

