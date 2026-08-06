{{ config(
    alias = 'sat_crm_users_other',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['crm_users_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['crm', 'contact', 'phase2', 'all']
) }}

{% set source_name = 'crm' %}
{% set source_table = 'crm_users' %}
{% set hashdiff_col = 'hashdiff_crm_users_other' %}
{% set hub_hashkey = 'crm_users_hashkey' %}
{% set source_model = 'v_stg_crm_crm_users' %}
{% set list_cols = ['is_team_manage','isactive','isdeleted','is_enable_market_place','is_lso_sk','is_out_of_line','old_custgroup','old_branch_code','old_user_full_name','old_account_officer_id','old_func_group','old_user_phone','old_telext','user_created','date_created','user_updated','date_updated','user_deleted','date_deleted'] %}
{% set raw_sql = None %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}
