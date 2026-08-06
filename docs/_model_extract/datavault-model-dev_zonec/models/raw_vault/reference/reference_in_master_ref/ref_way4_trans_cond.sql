-- depends_on: {{ ref('v_stg_way4_trans_cond') }}

{{ config(
    alias = 'ref_way4_trans_cond',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['way4', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['id', 'code', 'name', 'condition_details', 'amnd_state', 'amnd_date', 'amnd_officer', 'amnd_prev', 'term_cat', 'category_code', 'default_condition', 'late_condition', 'security_code', 'addendum'] -%}

{{ ref_table(
    src_table='trans_cond',
    src_type='w4_trans_cond',
    src_code="concat_ws('', cast(id as string), cast(code as string))",
    src_des="name || condition_details",
    source_name='way4',
    record_source='way4__ows_trans_cond'
    ,where_clause='amnd_state  = "A"'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
