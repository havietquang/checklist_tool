-- depends_on: {{ ref('v_stg_t24_t24_acct_gen_condition') }}

{{ config(
    alias = 'ref_t24_acct_gen_condition',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference','phase2', 'all']
) }}

{% set list_cols = ['data_date', 't_item', 't_priority', 't_value', 't_multivalue', 't_co_code', 't_inputter', 't_date_time', 't_authoriser'] -%}

{{ ref_table(
    src_table='t24_acct_gen_condition',
    src_type='acct_gen_condition',
    src_code="id",
    src_des="t_description",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
