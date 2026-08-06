-- depends_on: {{ ref('v_stg_t24_t24_town') }}

{{ config(
    alias = 'ref_t24_town',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_order', 't_active', 't_province', 't_ocb_town_nation'] -%}

{{ ref_table(
    src_table='t24_town',
    src_type='town',
    src_code="id",
    src_des="t_town_name",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
