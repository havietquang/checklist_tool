-- depends_on: {{ ref('v_stg_t24_t24_dealer_desk') }}

{{ config(
    alias = 'ref_t24_dealer_desk',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date'] -%}

{{ ref_table(
    src_table='t24_dealer_desk',
    src_type='dealer_desk',
    src_code="id",
    src_des="descriptions",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
