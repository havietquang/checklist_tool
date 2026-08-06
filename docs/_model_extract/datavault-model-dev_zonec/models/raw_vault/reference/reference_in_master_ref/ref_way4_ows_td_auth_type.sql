-- depends_on: {{ ref('v_stg_way4_ows_td_auth_type') }}

{{ config(
    alias = 'ref_way4_ows_td_auth_type',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'phase2', 'all']
) }}

{% set list_cols = ['id', 'code', 'amnd_date', 'amnd_officer', 'amnd_state', 'amnd_prev', 'auth_type_cat', 'idt_required', 'version_idt', 'base_type', 'is_ready'] -%}

{{ ref_table(
    src_table='ows_td_auth_type',
    src_type='w4_ows_td_auth_type',
    src_code="concat_ws('', cast(id as string), cast(code as string))",
    src_des="name",
    source_name='way4'
    ,where_clause='amnd_state  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
