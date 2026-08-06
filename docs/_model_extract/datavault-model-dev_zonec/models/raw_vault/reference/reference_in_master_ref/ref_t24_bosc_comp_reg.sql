-- depends_on: {{ ref('v_stg_t24_t24_bosc_comp_reg') }}

{{ config(
    alias = 'ref_t24_bosc_comp_reg',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference','phase2', 'all']
) }}

{% set list_cols = ['data_date', 't_account_number', 't_branch_id'] -%}

{{ ref_table(
    src_table='t24_bosc_comp_reg',
    src_type='bosc_comp_reg',
    src_code="id",
    src_des="t_company_name",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
