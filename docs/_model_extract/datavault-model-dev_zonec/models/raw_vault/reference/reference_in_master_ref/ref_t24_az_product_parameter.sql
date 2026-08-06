-- depends_on: {{ ref('v_stg_t24_t24_az_product_parameter') }}

{{ config(
    alias = 'ref_t24_az_product_parameter',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_allowed_categ', 't_dr_txn_code', 't_cr_txn_code', 't_int_basis', 't_minimum_term', 't_maximum_term', 't_periodic_rate_key', 't_maturity_instr', 't_record_status', 't_curr_no', 't_inputter', 't_authoriser', 't_date_time', 't_co_code', 't_loan_deposit', 't_prod_end_date', 't_prod_start_date'] -%}

{{ ref_table(
    src_table='t24_az_product_parameter',
    src_type='az_product_parameter',
    src_code="id",
    src_des="t_description",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
