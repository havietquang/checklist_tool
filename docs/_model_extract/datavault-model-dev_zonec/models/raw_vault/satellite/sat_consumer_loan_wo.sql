{{ config(
    alias = 'sat_consumer_loan_wo',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['consumer_loan_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['comb', 'zonec', 'all']
) }}

{% set source_name = 'comb' %}
{% set source_table = 'consumer_loan_wo' %}
{% set hashdiff_col = 'hashdiff_consumer_loan_wo' %}
{% set hub_hashkey = 'consumer_loan_hashkey' %}
{% set source_model = 'v_stg_comb_consumer_loan_wo' %}
{% set list_cols = [
    'app_id',
    'customer_id',
    'branch_code',
    'currency',
    'mature_date',
    'open_date',
    'disbursment_amount',
    'oustanding_amount',
    'custgroup',
    'loan_classification',
    'begin_repayment_date',
    'next_repayment_date',
    'frequency',
    'interst_amount',
    'pd_interest',
    'interest_rate',
    'interest_type',
    'industry_level_3',
    'term',
    'purpose_id',
    'extend_sch',
    'extendsch_date',
    'account_officer_id',
    'product_id',
    'provision_amount',
    'provision_oustanding',
    'link_reference',
    'full_name',
    'legal_id',
    'gl',
    'pd_amount_eq',
    'pr_day',
    'in_day',
    'interest_rate1',
    'interest_spread',
    'sbv21_sector_legal',
    'loan_subproduct',
    'datasource',
    'loan_subproduct_name',
    'purpose_name',
    'on_due_principal',
    'acrrual_balance'
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
