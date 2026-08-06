/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record (thuong: hub_hashkey + hashdiff)
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['way4'] = filter khi run (dbt run --select tag:way4)
====================================================================
*/
{{ config(
    alias = 'hub_appsflyer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['appsflyer_hashkey'],
    skip_matched_step = true,
    tags = ['appsflyer', 'phase2', 'all']
) }}

{% set source_name = 'appsflyer' %}
{% set unique_key = 'appsflyer_hashkey' %}

{% set raw_sql %}
with unioned_source as (

    select
        hashkey as appsflyer_hashkey ,
        appsflyer_id as business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'installs_report') AS record_source,
        load_timestamp
    from {{ ref('v_stg_appsflyer_installs_report') }}
    where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')

    union

    select
        hashkey as appsflyer_hashkey,
        appsflyer_id as business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'organic_installs_report') AS record_source,
        load_timestamp
    from {{ ref('v_stg_appsflyer_organic_installs_report') }}
    where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')

    union

    select
        hashkey as appsflyer_hashkey,
        appsflyer_id as business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'reinstalls') AS record_source,
        load_timestamp
    from {{ ref('v_stg_appsflyer_reinstalls') }}
    where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')

    union

    select
        hashkey as appsflyer_hashkey,
        appsflyer_id as business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'reinstalls_organic') AS record_source,
        load_timestamp
    from {{ ref('v_stg_appsflyer_reinstalls_organic') }}
    where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')

    union

    select
        hashkey as appsflyer_hashkey ,
        appsflyer_id as business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'in_app_events_report') AS record_source,
        load_timestamp
    from {{ ref('v_stg_appsflyer_in_app_events_report') }}
    where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')

    union

    select
        hashkey as appsflyer_hashkey ,
        appsflyer_id as business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'organic_in_app_events_report') AS record_source,
        load_timestamp
    from {{ ref('v_stg_appsflyer_organic_in_app_events_report') }}
    where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')

    union

    select
        hashkey as appsflyer_hashkey ,
        appsflyer_id as business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'uninstall_events_report') AS record_source,
        load_timestamp
    from {{ ref('v_stg_appsflyer_uninstall_events_report') }}
    where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')

    union

    select
        hashkey as appsflyer_hashkey ,
        appsflyer_id as business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'organic_uninstall_events_report') AS record_source,
        load_timestamp
    from {{ ref('v_stg_appsflyer_organic_uninstall_events_report') }}
    where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
)
-- Cung 1 appsflyer_id (=> appsflyer_hashkey) co the xuat hien o nhieu report,
-- moi nhanh gan record_source khac nhau nen UNION khong gop duoc.
-- Giu 1 dong/appsflyer_hashkey de tranh trung khoa o hub.
select *
from unioned_source
qualify row_number() over (
    partition by appsflyer_hashkey
    order by source_event_date, load_timestamp, record_source
) = 1
{% endset %}
/*
========================================================================
HUB MACRO PARAMETERS
========================================================================
  - source_model : Ten cua model/view nguon. VD: 'v_stg_appsflyer_in_app_events_report'.
  - source_name  : Ten he thong nguon (Record Source).
  - source_table : Ten bang nguon business duoc dua vao metadata.
  - unique_key   : Ten cot Hash Key cua Hub (Primary Key cua bang Hub).
  - business_key : Ten cot Business Key tu nguon.
========================================================================
*/

-- Su dung hub macro voi cac tham so native
{{ hub(
    source_name = source_name,
    unique_key = unique_key,
    raw_sql = raw_sql
) }}





