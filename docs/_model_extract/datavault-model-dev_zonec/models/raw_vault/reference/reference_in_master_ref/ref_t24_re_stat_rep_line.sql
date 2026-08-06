-- depends_on: {{ ref('v_stg_t24_t24_re_stat_rep_line') }}

{{ config(
    alias = 'ref_t24_re_stat_rep_line',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_k_type', 't_co_code', 't_inputter', 't_date_time', 't_authoriser'] -%}

{{ ref_table(
    src_table='t24_re_stat_rep_line',
    src_type='re_stat_rep_line',
    src_code="id",
    src_des="t_desc",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
