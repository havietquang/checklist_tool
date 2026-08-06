-- depends_on: {{ ref('v_stg_way4_ows_bin_table') }}

{{ config(
    alias = 'ref_way4_ows_bin_table',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'phase2', 'all']
) }}

{% set list_cols = ['amnd_state', 'amnd_date', 'amnd_officer', 'amnd_prev', 'bin_group__oid', 'member_id', 'start_bin', 'end_bin', 'start_bin_4', 'pan_length', 'bin_condition', 'bin_details', 'card_brand', 'card_org', 'card_technology', 'cdv_algorithm', 'channel', 'country', 'data_source', 'ec_atm_type', 'forwarding_id', 'ica_number', 'processing_class', 'product_id', 'licensed_product_id', 'product_category', 'region_for_issuer', 'service_indicator', 'terminal_category', 'usage', 'usage_domain', 'bin_status', 'data_date'] -%}

{{ ref_table(
    src_table='ows_bin_table',
    src_type='w4_ows_bin_table',
    src_code="id",
    src_des="name",
    source_name='way4'
    ,where_clause='amnd_state  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
