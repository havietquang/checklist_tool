{{ config(
    alias = 'sat_aa_arr_account_audit',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['aa_arrangement_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'zonec', 'all']
) }}

{% set source_name = 't24' %}
{% set source_table = 't24_aa_arr_account' %}
{% set hashdiff_col = 'hashdiff_aa_arr_account_audit' %}
{% set hub_hashkey = 'aa_arrangement_hashkey' %}
{% set source_model = 'v_stg_t24_t24_aa_arr_account' %}
{% set list_cols = [
    'ma_key',
    't_ld_aprv_date',
    't_ld_aprv_level',
    't_ld_aprv_user',
    't_aprv_reval_user',
    't_ld_aprv_ch_date',
    't_aprv_ch_desc',
    't_aprv_ch_level',
    't_aprv_ch_user',
    't_ap_rev_ch_user',
    't_inputter',
    't_date_time',
    't_authoriser'
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
