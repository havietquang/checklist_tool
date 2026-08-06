-- depends_on: {{ ref('v_stg_t24_t24_ld_aprv_user') }}

{{ config(
    alias = 'ref_t24_ld_aprv_user',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_ubtd1', 't_ubtd2', 't_ubtd3', 't_direct_aprv', 't_indirect_aprv', 't_reval_level', 't_active_info', 't_user_status', 't_curr_no', 't_inputter', 't_authoriser', 't_date_time'] -%}

{{ ref_table(
    src_table='t24_ld_aprv_user',
    src_type='ld_aprv_user',
    src_code="id",
    src_des="t_app_user_name",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
