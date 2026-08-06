-- depends_on: {{ ref('v_stg_way4_cs_status_value') }}

{{ config(
    alias = 'ref_way4_cs_status_value',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['amnd_date', 'amnd_officer', 'amnd_state', 'amnd_prev', 'cs_status_type__oid', 'status_type_code', 'is_ok', 'result_event_code', 'severity_level', 'to_rules', 'from_rules', 'add_info', 'is_active', 'date_from', 'date_to'] -%}

{{ ref_table(
    src_table='cs_status_value',
    src_type='w4_ows_cs_status_value',
    src_code="id",
    src_des="name",
    source_name='way4',
    record_source='way4__ows_cs_status_value'
    ,where_clause='amnd_state  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
