-- depends_on: {{ ref('v_stg_t24_t24_ft_txn_type_condition') }}

{{ config(
    alias = 'ref_t24_ft_txn_type_condition',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_txn_code_cr', 't_txn_code_dr', 't_sto_txn_code_cr', 't_sto_txn_code_dr'] -%}

{{ ref_table(
    src_table='t24_ft_txn_type_condition',
    src_type='ft_txn_type_condition',
    src_code="id",
    src_des="t_short_descr",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
