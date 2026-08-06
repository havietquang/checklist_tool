-- depends_on: {{ ref('v_stg_way4_ows_branch') }}

{{ config(
    alias = 'ref_way4_ows_branch',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'zonec', 'all']
) }}

{% set list_cols = ['ID', 'CODE', 'AMND_STATE', 'AMND_DATE', 'AMND_OFFICER', 'AMND_PREV', 'F_I', 'BRANCH__OID', 'LIAB_CONTRACT', 'UNIT', 'BANK_CLIENT', 'TIME_ZONE', 'UNIT_TYPE'] -%}

{{ ref_table(
    src_table='ows_branch',
    src_type='w4_ows_branch',
    src_code="concat_ws('', cast(id as string), cast(code as string))",
    src_des="name",
    source_name='way4'
    ,where_clause='AMND_STATE  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
