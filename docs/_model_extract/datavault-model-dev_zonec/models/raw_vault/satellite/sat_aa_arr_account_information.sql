{{ config(
    alias = 'sat_aa_arr_account_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['aa_arrangement_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'zonec', 'all']
) }}

{% set source_name = 't24' %}
{% set source_table = 't24_aa_arr_account' %}
{% set hashdiff_col = 'hashdiff_aa_arr_account_information' %}
{% set hub_hashkey = 'aa_arrangement_hashkey' %}
{% set source_model = 'v_stg_t24_t24_aa_arr_account' %}
{% set list_cols = [
    'ma_key',
    't_activity',
    't_category',
    't_currency',
    't_l_orig_val_date',
    't_l_link_ref',
    't_ocb_pro_partner',
    't_ocb_promotion',
    't_l_ln_remark',
    't_linked_tfdr_ref',
    't_extend_sch',
    't_extendsch_date',
    't_source_of_fund',
    't_term',
    't_loan_subproduct',
    't_loan_method',
    't_loan_purpose',
    't_purpose_amt',
    't_ld_cust_group',
    't_cu_cust_group',
    't_auto_name',
    't_auto_type',
    't_real_type',
    't_ocb_pro_bundle',
    't_bpm_disb_id',
    't_ocb_outof_area',
    't_ocbint_chg_date',
    't_repay_source',
    't_action',
    't_account_title_1',
    't_co_code'
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
