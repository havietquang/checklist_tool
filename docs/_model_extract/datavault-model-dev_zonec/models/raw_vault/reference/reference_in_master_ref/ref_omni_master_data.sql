-- depends_on: {{ ref('v_stg_omni_master_data') }}

{{ config(
    alias = 'ref_omni_master_data',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['omni', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['id', 'code', 'created_at', 'created_by', 'updated_at', 'updated_by', 'name', 'status', 'type'] -%}

{{ ref_table(
    src_table='master_data',
    src_type='omni_master_data',
    src_code="concat_ws('', cast(id as string), cast(code as string))",
    src_des="description",
    source_name='omni'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
