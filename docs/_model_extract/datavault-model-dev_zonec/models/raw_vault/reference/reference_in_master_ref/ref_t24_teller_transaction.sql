-- depends_on: {{ ref('v_stg_t24_t24_teller_transaction') }}

{{ config(
    alias = 'ref_t24_teller_transaction',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase2', 'all']
) }}

{% set list_cols = ['data_date', 't_short_desc', 't_transaction_code_1', 't_transaction_code_2', 't_record_status', 't_curr_no', 't_inputter', 't_date_time', 't_authoriser', 't_co_code', 't_dept_code'] -%}

{{ ref_table(
    src_table='t24_teller_transaction',
    src_type='teller_transaction',
    src_code="id",
    src_des="t_desc",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
