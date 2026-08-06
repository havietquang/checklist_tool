-- depends_on: {{ ref('v_stg_ocbchannel_eb_package_type') }}

{{ config(
    alias = 'ref_ocbchannel_eb_package_type',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['Ref_hashkey', 'hashdiff_full'],
    skip_matched_step = true,
    tags = ['ocbchannel', 'reference', 'zonec']
) }}

{% set raw_sql -%}
select
    sha2(('eb_package_type' || cast(package_type_id || channel as string)), 256) as Ref_hashkey,
    'eb_package_type' as Ref_type,
    cast(package_type_id || channel as string) as Ref_code,
    cast(package_name as string) as Ref_description,
    package_type_id,
    channel,
    package_name,
    PACKAGE_STATUS,
    NOTES,
    PACKAGE_DESC,
    NEWOMNI_AUTHEN_CODE,
    hashdiff_full,
    source_event_date,
    cast('ocbchannel__eb_package_type' as string) as Record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
from {{ ref('v_stg_ocbchannel_eb_package_type') }}
{%- endset %}

{{ ref_table(raw_sql) }}
