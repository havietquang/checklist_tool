-- depends_on: {{ ref('v_stg_omni_service_provider') }}

{{ config(
    alias = 'ref_omni_service_provider',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['omni', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['id', 'provider_code', 'provider_icon', 'services_id', 'service_code', 'provider_group_code', 'provider_group_name', 'auto_bill', 'title', 'image', 'created_at', 'modified_at', 'created_by', 'modified_by', 'provider_group_service_id', 'prop1', 'prop2', 'prop3', 'prop4', 'prop5', 'gateway_id', 'visible', 'allow_credit_card', 'content_en', 'content_vi', 'content_reason', 'provider_order', 'save_my_bill', 'module', 'group_service', 'has_fee', 'allow_in_group', 'allow_fav_trans', 'alt_provider_code', 'alt_gateway_id', 'content_ko', 'content_ja', 'auto_bill_permission', 'manual_bill_permission'] -%}

{{ ref_table(
    src_table='service_provider',
    src_type='omni_service_provider',
    src_code="concat_ws('', cast(id as string), cast(provider_code as string))",
    src_des="provider_name",
    source_name='omni'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
