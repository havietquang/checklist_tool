-- depends_on: {{ ref('v_stg_t24_t24_ocbh_ld_prod_main') }}

{{ config(
    alias = 'ref_t24_ocbh_ld_prod_main',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_category', 't_record_status', 't_curr_no', 't_inputter', 't_date_time', 't_authoriser', 't_co_code', 't_dept_code', 't_auditor_code', 't_audit_date_time'] -%}

{{ ref_table(
    src_table='t24_ocbh_ld_prod_main',
    src_type='ld_prod_main',
    src_code="id",
    src_des="t_name",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
