-- depends_on: {{ ref('v_stg_omni_fee_discount') }}

{{ config(
    alias = 'ref_omni_fee_discount',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['omni', 'reference','phase2', 'all']
) }}

{% set list_cols = ['id', 'code', 'created_at', 'created_by', 'updated_at', 'updated_by', 'discount_rate', 'end_at', 'name', 'start_at', 'status', 'fee_discount_type', 'fee_reduction_time', 'approved_by'] -%}

{{ ref_table(
    src_table='fee_discount',
    src_type='omni_fee_discount',
    src_code="concat_ws('', cast(id as string), cast(code as string))",
    src_des="description",
    source_name='omni'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
