-- depends_on: {{ ref('v_stg_t24_t24_de_bic') }}

{{ config(
    alias = 'ref_t24_de_bic',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_city', 't_address', 't_country', 't_subtype_ind', 't_recordkey', 't_branch', 't_bic_code'] -%}

{{ ref_table(
    src_table='t24_de_bic',
    src_type='de_bic',
    src_code="id",
    src_des="t_institution",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
