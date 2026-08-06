-- depends_on: {{ ref('v_stg_t24_t24_transaction') }}

{{ config(
    alias = 'ref_t24_transaction',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_transaction_code', 't_data_capture', 't_cheque_ind', 't_mandatory_ref_no', 't_debit_credit_ind', 't_charge_key', 't_immediate_charge', 't_default_value_date', 't_exposure_date', 't_record_status', 't_curr_no', 't_co_code', 't_dept_code', 't_auditor_code'] -%}

{{ ref_table(
    src_table='t24_transaction',
    src_type='transaction',
    src_code="id",
    src_des="t_narrative",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
