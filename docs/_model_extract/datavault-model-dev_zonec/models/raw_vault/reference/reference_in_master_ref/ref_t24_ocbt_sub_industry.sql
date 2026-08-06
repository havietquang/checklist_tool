-- depends_on: {{ ref('v_stg_t24_t24_ocbt_sub_industry') }}

{{ config(
    alias = 'ref_t24_ocbt_sub_industry',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_id_parent', 't_order', 't_active'] -%}

{{ ref_table(
    src_table='t24_ocbt_sub_industry',
    src_type='sub_industry',
    src_code="id",
    src_des="t_sub_industry_name",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
