-- depends_on: {{ ref('v_stg_way4_ows_country') }}

{{ config(
    alias = 'ref_way4_ows_country',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'zonec', 'all']
) }}

{% set list_cols = ['ID', 'CODE', 'AMND_DATE', 'AMND_STATE', 'AMND_OFFICER', 'AMND_PREV', 'AREA_DFLT', 'CODE_2', 'CURR_CODE', 'CURR_NAME', 'CUSTOM_CODE', 'DEFAULT_LANGUAGE', 'LIMIT_CODE', 'N_CODE', 'N_CURR_CODE', 'POSTAL_CODE', 'USE_IN_BANK', 'COUNTRY_OBJECT__ID', 'CALENDAR_TYPE'] -%}

{{ ref_table(
    src_table='ows_country',
    src_type='w4_ows_country',
    src_code="concat_ws('', cast(id as string), cast(code as string))",
    src_des="name",
    source_name='way4'
    ,where_clause='AMND_STATE  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
