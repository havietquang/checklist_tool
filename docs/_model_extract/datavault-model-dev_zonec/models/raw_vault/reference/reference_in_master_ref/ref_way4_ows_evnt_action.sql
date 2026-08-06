-- depends_on: {{ ref('v_stg_way4_ows_evnt_action') }}

{{ config(
    alias = 'ref_way4_ows_evnt_action',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'phase2', 'all']
) }}

{% set list_cols = ['id', 'action_code', 'usage_action__oid', 'new_id', 'old_id', 'status', 'data_date'] -%}

{{ ref_table(
    src_table='ows_evnt_action',
    src_type='w4_ows_evnt_action',
    src_code="concat_ws('', cast(id as string), cast(action_code as string))",
    src_des="event_details",
    source_name='way4'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
