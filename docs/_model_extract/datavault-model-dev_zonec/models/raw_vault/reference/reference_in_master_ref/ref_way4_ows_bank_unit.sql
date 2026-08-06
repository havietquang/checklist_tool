-- depends_on: {{ ref('v_stg_way4_ows_bank_unit') }}

{{ config(
    alias = 'ref_way4_ows_bank_unit',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'phase2', 'all']
) }}

{% set list_cols = ['id', 'code', 'amnd_state', 'amnd_date', 'amnd_officer', 'amnd_prev', 'unit_type', 'bank_unit__oid', 'f_i', 'liab_contract', 'bank_client', 'is_ready'] -%}

{{ ref_table(
    src_table='ows_bank_unit',
    src_type='w4_ows_bank_unit',
    src_code="concat_ws('', cast(id as string), cast(code as string))",
    src_des="name",
    source_name='way4'
    ,where_clause='amnd_state  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
