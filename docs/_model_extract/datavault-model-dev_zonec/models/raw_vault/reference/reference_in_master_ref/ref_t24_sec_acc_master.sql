-- depends_on: {{ ref('v_stg_t24_t24_sec_acc_master') }}

{{ config(
    alias = 'ref_t24_sec_acc_master',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_account_officer', 't_customer_number', 't_reference_currency', 't_date_of_valuation', 't_start_date', 't_co_code', 't_portfolio_type'] -%}

{{ ref_table(
    src_table='t24_sec_acc_master',
    src_type='sec_acc_master',
    src_code="id",
    src_des="t_account_name",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
