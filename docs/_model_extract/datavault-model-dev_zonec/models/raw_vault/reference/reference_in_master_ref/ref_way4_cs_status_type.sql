-- depends_on: {{ ref('v_stg_way4_cs_status_type') }}

{{ config(
    alias = 'ref_way4_cs_status_type',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['amnd_date', 'amnd_officer', 'amnd_state', 'amnd_prev', 'code', 'group_code', 'default_value', 'applies_to', 'pcat', 'con_cat', 'ccat', 'status_category', 'log_flag', 'is_primary', 'on_off_mode', 'domain_code', 'domain_type__id', 'add_info', 'is_ready'] -%}

{{ ref_table(
    src_table='cs_status_type',
    src_type='w4_ows_cs_status_type',
    src_code="id",
    src_des="name",
    source_name='way4',
    record_source='way4__ows_cs_status_type'
    ,where_clause='amnd_state  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
