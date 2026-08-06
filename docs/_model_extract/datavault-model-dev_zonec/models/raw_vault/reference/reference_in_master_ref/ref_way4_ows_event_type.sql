-- depends_on: {{ ref('v_stg_way4_ows_event_type') }}

{{ config(
    alias = 'ref_way4_ows_event_type',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'phase2', 'all']
) }}

{% set list_cols = ['id', 'code', 'amnd_state', 'amnd_date', 'amnd_officer', 'amnd_prev', 'group_code', 'f_i', 'pcat', 'con_cat', 'event_renew_type', 'event_period', 'due_to_work_day', 'post_immediate', 'fee_type', 'new_status', 'next_event', 'start_job', 'client_stop_list', 'cr_limit_action', 'used_in_history', 'suppl_formula', 'custom_event_code', 'special_parms'] -%}

{{ ref_table(
    src_table='ows_event_type',
    src_type='w4_ows_event_type',
    src_code="concat_ws('', cast(id as string), cast(code as string))",
    src_des="name",
    source_name='way4'
    ,where_clause='amnd_state  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
