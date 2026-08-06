-- depends_on: {{ ref('v_stg_way4_mess_channel') }}

{{ config(
    alias = 'ref_way4_mess_channel',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['id', 'code', 'amnd_state', 'amnd_date', 'amnd_officer', 'amnd_prev', 'contra_channel', 'data_source', 'is_on_us', 'settl_date'] -%}

{{ ref_table(
    src_table='mess_channel',
    src_type='w4_mess_channel',
    src_code="concat_ws('', cast(id as string), cast(code as string))",
    src_des="name",
    source_name='way4',
    record_source='way4__ows_mess_channel'
    ,where_clause='amnd_state  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
