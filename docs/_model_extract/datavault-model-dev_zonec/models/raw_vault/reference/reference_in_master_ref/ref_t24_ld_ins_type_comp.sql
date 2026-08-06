-- depends_on: {{ ref('v_stg_t24_t24_ld_ins_type_comp') }}

{{ config(
    alias = 'ref_t24_ld_ins_type_comp',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_ins_type', 't_ins_company', 't_ins_type_id', 't_nused'] -%}

{{ ref_table(
    src_table='t24_ld_ins_type_comp',
    src_type='ld_ins_type_comp',
    src_code="id",
    src_des="t_description",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
