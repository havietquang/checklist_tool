-- depends_on: {{ ref('v_stg_way4_sic') }}

{{ config(
    alias = 'ref_way4_sic',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['id', 'code', 'amnd_state', 'amnd_date', 'amnd_officer', 'amnd_prev', 'group_code', 'custom_code', 'limit_code', 'sic_group_dflt', 'use_in_bank'] -%}

{{ ref_table(
    src_table='sic',
    src_type='w4_ows_sic',
    src_code="concat_ws('', cast(id as string), cast(code as string))",
    src_des="name",
    source_name='way4',
    record_source='way4__ows_sic'
    ,where_clause='amnd_state  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
