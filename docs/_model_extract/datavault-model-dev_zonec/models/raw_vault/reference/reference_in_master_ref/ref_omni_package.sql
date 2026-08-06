-- depends_on: {{ ref('v_stg_omni_package') }}

{{ config(
    alias = 'ref_omni_package',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['omni', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['id', 'code', 'created_at', 'created_by', 'updated_at', 'updated_by', 'description', 'status', 'can_register_ep_portal', 'effective_date', 'package_discontinuation_date'] -%}

{{ ref_table(
    src_table='package',
    src_type='omni_package',
    src_code="concat_ws('', cast(id as string), cast(code as string))",
    src_des="name",
    source_name='omni'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
