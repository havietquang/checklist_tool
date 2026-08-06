-- depends_on: {{ ref('v_stg_t24_t24_ocbh_cat_prod') }}

{{ config(
    alias = 'ref_t24_ocbh_cat_prod',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff_full'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'zonec']
) }}

{% set list_cols = ['PRODUCT_GRP', 'PRODUCT_SYS', 'KPI_ID', 'LOCAL_REF', 'OVERRIDE', 'RECORD_STATUS', 'CURR_NO', 'INPUTTER', 'DATE_TIME', 'AUTHORISER', 'CO_CODE', 'DEPT_CODE', 'AUDITOR_CODE', 'AUDIT_DATE_TIME'] -%}

{{ ref_table(
    src_table='t24_ocbh_cat_prod',
    src_type='ocbh_cat_prod',
    src_code="id",
    src_des="PRODUCT_TYPE",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
