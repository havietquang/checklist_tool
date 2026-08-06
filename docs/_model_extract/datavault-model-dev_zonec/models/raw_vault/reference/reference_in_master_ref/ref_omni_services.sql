-- depends_on: {{ ref('v_stg_omni_services') }}

{{ config(
    alias = 'ref_omni_services',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['omni', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['id', 'service_code', 'service_icon', 'created_at', 'modified_at', 'created_by', 'modified_by', 'prop1', 'prop2', 'prop3', 'prop4', 'prop5', 'service_order', 'service_code_new', 'visible', 'group_service'] -%}

{{ ref_table(
    src_table='services',
    src_type='omni_services',
    src_code="concat_ws('', cast(id as string), cast(service_code as string))",
    src_des="service_name",
    source_name='omni'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
