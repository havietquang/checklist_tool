-- depends_on: {{ ref('v_stg_qldt_ldm_partner_type') }}

{{ config(
    alias = 'ref_qldt_ldm_partner_type',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['qldt', 'reference', 'zonec', 'all']
) }}

{% set list_cols = ['url'] -%}

{{ ref_table(
    src_table='ldm_partner_type',
    src_type='ldm_partner_type',
    src_code="partner_type_id",
    src_des="partner_type_name",
    source_name='qldt',
    record_source='qldt__ldm_partner_type'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
