-- depends_on: {{ ref('v_stg_t24_t24_ocbh_cus_group') }}

{{ config(
    alias = 'ref_t24_ocbh_cus_group',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date'] -%}

{{ ref_table(
    src_table='t24_ocbh_cus_group',
    src_type='cus_group',
    src_code="id",
    src_des="t_cust_group_name",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
