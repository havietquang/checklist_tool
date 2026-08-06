-- depends_on: {{ ref('v_stg_t24_t24_collateral_code') }}

{{ config(
    alias = 'ref_t24_collateral_code',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_collateral_code', 't_short_name', 't_collateral_type', 't_record_status', 't_curr_no', 't_inputter', 't_authoriser', 't_date_time', 't_co_code'] -%}

{{ ref_table(
    src_table='t24_collateral_code',
    src_type='collateral_code',
    src_code="id",
    src_des="t_description",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
