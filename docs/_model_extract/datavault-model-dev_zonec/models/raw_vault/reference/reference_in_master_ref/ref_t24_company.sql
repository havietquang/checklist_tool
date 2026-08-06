-- depends_on: {{ ref('v_stg_t24_t24_company') }}

{{ config(
    alias = 'ref_t24_company',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_mnemonic', 't_consolidation_mark', 't_default_no_of_auth', 't_pgm_autom_id', 't_applications', 't_tax_code', 't_financial_year_end', 't_sub_division_code', 't_official_holiday', 't_branch_holiday', 't_batch_holiday', 't_name_address', 't_language_code'] -%}

{{ ref_table(
    src_table='t24_company',
    src_type='company',
    src_code="id",
    src_des="t_company_name",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
