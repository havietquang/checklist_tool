-- depends_on: {{ ref('v_stg_t24_t24_ocbh_loan_pro_bundle') }}

{{ config(
    alias = 'ref_t24_ocbh_loan_pro_bundle',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 'sub_product'] -%}

{{ ref_table(
    src_table='t24_ocbh_loan_pro_bundle',
    src_type='loan_pro_bundle',
    src_code="id",
    src_des="description",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
