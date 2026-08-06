-- depends_on: {{ ref('v_stg_t24_t24_basic_interest') }}

{{ config(
    alias = 'ref_t24_basic_interest',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_interest_rate', 't_record_status', 't_curr_no', 't_inputter', 't_authoriser', 't_date_time', 't_co_code'] -%}

{{ ref_table(
    src_table='t24_basic_interest',
    src_type='basic_interest',
    src_code="id",
    src_des="id",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
