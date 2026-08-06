-- depends_on: {{ ref('v_stg_t24_t24_loan_purpose') }}

{{ config(
    alias = 'ref_t24_loan_purpose',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_level_1', 't_level_1_desc', 't_level_2', 't_level_2_desc', 't_record_status', 't_curr_no', 't_inputter', 't_authoriser', 't_date_time', 't_co_code', 't_category'] -%}

{{ ref_table(
    src_table='t24_loan_purpose',
    src_type='loan_purpose',
    src_code="id",
    src_des="t_description",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
