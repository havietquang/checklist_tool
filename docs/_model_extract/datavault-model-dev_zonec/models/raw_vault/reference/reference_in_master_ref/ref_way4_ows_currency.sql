-- depends_on: {{ ref('v_stg_way4_ows_currency') }}

{{ config(
    alias = 'ref_way4_ows_currency',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'zonec', 'all']
) }}

{% set list_cols = ['ID', 'CODE', 'AMND_STATE', 'AMND_DATE', 'AMND_OFFICER', 'AMND_PREV', 'FULL_NAME', 'EXPONENT', 'FX_RANGE', 'USE_IN_BANK'] -%}

{{ ref_table(
    src_table='ows_currency',
    src_type='w4_ows_currency',
    src_code="concat_ws('', cast(id as string), cast(code as string))",
    src_des="name",
    source_name='way4'
    ,where_clause='AMND_STATE  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
