-- depends_on: {{ ref('v_stg_ocbchannel_authen_type') }}

{{ config(
    alias = 'ref_ocbchannel_authen_type',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['Ref_hashkey', 'hashdiff_full'],
    skip_matched_step = true,
    tags = ['ocbchannel', 'reference', 'zonec']
) }}

{% set raw_sql -%}
select
    sha2(('authen_type' || cast(authen_id as string)), 256) as Ref_hashkey,
    'authen_type' as Ref_type,
    cast(authen_id as string) as Ref_code,
    cast(authen_name as string) as Ref_description,
    AUTHEN_CODE_MAP,
    hashdiff_full,
    source_event_date,
    cast('ocbchannel__authen_type' as string) as Record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
from {{ ref('v_stg_ocbchannel_authen_type') }}
{%- endset %}

{{ ref_table(raw_sql) }}
