-- depends_on: {{ ref('v_stg_t24_t24_re_stat_line_cont') }}

{{ config(
    alias = 'ref_t24_re_stat_line_cont',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_type', 't_profit_ccy', 't_asst_consol_key', 't_asset_type', 't_prft_consol_key'] -%}

{{ ref_table(
    src_table='t24_re_stat_line_cont',
    src_type='re_stat_line_cont',
    src_code="id",
    src_des="t_desc",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
