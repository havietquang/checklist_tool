-- depends_on: {{ ref('v_stg_t24_t24_int_chg_type') }}

{{ config(
    alias = 'ref_t24_int_chg_type',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference','phase2', 'all']
) }}

{% set list_cols = ['data_date'] -%}

{{ ref_table(
    src_table='t24_int_chg_type',
    src_type='int_chg_type',
    src_code="t_frequency",
    src_des="t_descriptions",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
