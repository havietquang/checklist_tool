-- depends_on: {{ ref('v_stg_way4_trans_type') }}

{{ config(
    alias = 'ref_way4_trans_type',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['amnd_state', 'amnd_date', 'amnd_officer', 'amnd_prev', 'service_class', 's_cat', 't_cat', 'dr_cr', 'is_impersonal', 'is_authorized', 'is_required', 'enable_adjustment', 'enable_reversal', 'enable_request', 'prev_trans_type', 'chain_type', 'charge_event', 'dispute_trn_class', 'terminal_category', 'production_type', 'production_event', 'trans_code', 'reversal_code', 'trans_type_idt', 'priority'] -%}

{{ ref_table(
    src_table='trans_type',
    src_type='w4_trans_type',
    src_code="id",
    src_des="name",
    source_name='way4',
    record_source='way4__ows_trans_type'
    ,where_clause='amnd_state  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
