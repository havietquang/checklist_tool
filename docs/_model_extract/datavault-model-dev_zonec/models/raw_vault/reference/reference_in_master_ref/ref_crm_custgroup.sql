-- depends_on: {{ ref('v_stg_crm_crm_naming_custgroup') }}

{{ config(
    alias = 'ref_crm_custgroup',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['crm', 'reference','phase2', 'all']
) }}

{% set list_cols = ['parent_key', 'user_created', 'date_created', 'user_updated', 'date_updated', 'user_deleted', 'date_deleted', 'isactive', 'isdeleted'] -%}

{{ ref_table(
    src_table='crm_naming_custgroup',
    src_type='crm_custgroup',
    src_code="custgroup",
    src_des="name",
    source_name='crm'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
