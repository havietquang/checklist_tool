-- depends_on: {{ ref('v_stg_way4_ows_add_data') }}

{{ config(
    alias = 'ref_way4_ows_add_data',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'phase2', 'all']
) }}

{% set list_cols = ['amnd_state', 'amnd_date', 'amnd_officer', 'amnd_prev', 'add_data_col__id', 'for_id', 'add_data_tab', 'partition_key', 'data_date'] -%}

{{ ref_table(
    src_table='ows_add_data',
    src_type='w4_ows_add_data',
    src_code="id",
    src_des="val",
    source_name='way4'
    ,where_clause='amnd_state  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
