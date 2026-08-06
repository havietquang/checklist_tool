-- depends_on: {{ ref('v_stg_way4_account_type') }}

{{ config(
    alias = 'ref_way4_account_type',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['id', 'code', 'amnd_state', 'amnd_date', 'amnd_officer', 'amnd_prev', 'group_name', 'pcat', 'acat', 'is_am_available', 'due_type', 'charge_for_open', 'send_credit_to', 'send_debit_to', 'payment_priority', 'account_status'] -%}

{{ ref_table(
    src_table='account_type',
    src_type='w4_ows_account_type',
    src_code="concat_ws('', cast(id as string), cast(code as string))",
    src_des="name",
    source_name='way4',
    record_source='way4__ows_account_type'
    ,where_clause='amnd_state  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
