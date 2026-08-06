-- depends_on: {{ ref('v_stg_t24_t24_posting_restrict') }}

{{ config(
    alias = 'ref_t24_posting_restrict',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_restriction_type', 't_dispo_officer', 't_allow_txn', 't_txn_code', 't_local_ref', 't_alt_override', 't_block_reason_codes', 't_unblock_reason_codes', 't_co_code'] -%}

{{ ref_table(
    src_table='t24_posting_restrict',
    src_type='posting_restrict',
    src_code="id",
    src_des="t_description",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
