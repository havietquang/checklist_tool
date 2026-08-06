/*
====================================================================
DEPRECATED – file này đã được tái sử dụng cho sat_callcenter_information.
Satellite tách theo loại dữ liệu (information / outcome) thay vì hướng cuộc gọi.
====================================================================
*/

{{ config(
    alias = 'sat_callcenter_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['callcenter_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['callcenter', 'contact', 'phase2', 'all']
) }}

{% set source_name = 'callcenter' %}
{% set source_table = 'callcenter' %}
{% set hashdiff_col = 'hashdiff_callcenter_information' %}
{% set hub_hashkey = 'callcenter_hashkey' %}

{% set raw_sql -%}
SELECT
    hashkey AS callcenter_hashkey,
    {{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp)             AS load_timestamp,
    CONCAT(CAST('{{source_name}}' AS string), '__', '{{source_table}}') AS record_source,
    uniqueid,
    gcalluuid,
    accountcode,
    dialid,
    sipserver,
    src,
    dst,
    channel,
    dstchannel,
    queue,
    in_out,
    did_number,
    prefix_detail,
    carrier,
    callername,
    customer_id,
    customer_code,
    customername,
    customercif
FROM {{ ref('v_stg_callcenter_callcenter') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}
