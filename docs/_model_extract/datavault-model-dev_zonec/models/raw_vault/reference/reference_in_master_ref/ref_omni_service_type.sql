-- depends_on: {{ ref('v_stg_omni_service_type') }}

{{ config(
    alias = 'ref_omni_service_type',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['omni', 'reference','phase2', 'all']
) }}

{% set list_cols = ['id', 'service_code', 'business_function_id', 'maximum_default_transaction_bound', 'minimum_default_transaction_bound', 'support_limit', 'payment_type'] -%}

{{ ref_table(
    src_table='service_type',
    src_type='omni_service_type',
    src_code="concat_ws('', cast(id as string), cast(service_code as string))",
    src_des="service_name",
    source_name='omni'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
