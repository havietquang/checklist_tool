{{ config(
    alias = 'sat_aa_arr_account_regulations',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['aa_arrangement_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'zonec', 'all']
) }}

{% set source_name = 't24' %}
{% set source_table = 't24_aa_arr_account' %}
{% set hashdiff_col = 'hashdiff_aa_arr_account_regulations' %}
{% set hub_hashkey = 'aa_arrangement_hashkey' %}
{% set source_model = 'v_stg_t24_t24_aa_arr_account' %}
{% set list_cols = [
    'ma_key',
    't_l_class_covid',
    't_doubtful_sta',
    't_ln_class_manual',
    't_vmb_ln_class',
    't_vmb_class_date',
    't_ftp_nd_term_int',
    't_ftp_fee_repaid',
    't_ftp_int_rate_tp',
    't_industry_levo',
    't_industry_levt',
    't_industry_lev1',
    't_industry_lev2',
    't_industry_lev3',
    't_basel_home_pp',
    't_basel_rd_party',
    't_basel_clr_bal',
    't_cb_liab_ccy',
    't_cb_liab_amt',
    't_cb_liab_duedate',
    't_baselderivative',
    't_drvt_pr_ccy',
    't_drvt_pr_amt',
    't_drvt_pr_duedate',
    't_crext_purpose',
    't_legal_entity',
    't_basel_coll',
    't_ins_type',
    't_ins_company',
    't_ins_contract',
    't_ins_fee',
    't_ins_start',
    't_ins_end',
    't_ins_amount',
    't_ins_trans',
    't_ins_sales_id',
    't_ins_auto_numpla'
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
