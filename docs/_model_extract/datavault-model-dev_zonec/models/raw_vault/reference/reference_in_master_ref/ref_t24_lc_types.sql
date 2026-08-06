-- depends_on: {{ ref('v_stg_t24_t24_lc_types') }}

{{ config(
    alias = 'ref_t24_lc_types',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_category_code', 't_import_export'] -%}

{{ ref_table(
    src_table='t24_lc_types',
    src_type='lc_types',
    src_code="id",
    src_des="t_description",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
