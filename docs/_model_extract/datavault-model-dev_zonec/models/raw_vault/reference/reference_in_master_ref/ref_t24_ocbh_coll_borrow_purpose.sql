-- depends_on: {{ ref('v_stg_t24_t24_ocbh_coll_borrow_purpose') }}

{{ config(
    alias = 'ref_t24_ocbh_coll_borrow_purpose',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 'id2', 't_curr_no', 't_inputter', 't_date_time', 't_authoriser', 't_co_code', 't_dept_code'] -%}

{{ ref_table(
    src_table='t24_ocbh_coll_borrow_purpose',
    src_type='coll_borrow_purpose',
    src_code="id",
    src_des="t_detail",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
