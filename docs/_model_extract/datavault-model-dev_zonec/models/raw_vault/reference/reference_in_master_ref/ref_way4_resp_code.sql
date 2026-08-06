-- depends_on: {{ ref('v_stg_way4_resp_code') }}

{{ config(
    alias = 'ref_way4_resp_code',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['id', 'resp_code', 'amnd_state', 'amnd_date', 'amnd_officer', 'amnd_prev', 'resp_level', 'message_code', 'is_status'] -%}

{{ ref_table(
    src_table='resp_code',
    src_type='w4_resp_code',
    src_code="concat_ws('', cast(id as string), cast(resp_code as string))",
    src_des="resp_text",
    source_name='way4',
    record_source='way4__ows_resp_code'
    ,where_clause='amnd_state  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
