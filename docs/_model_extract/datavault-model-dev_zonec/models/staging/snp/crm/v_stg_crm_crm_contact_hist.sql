{{ config(
    alias = 'v_stg_crm_crm_contact_hist',
    materialized = 'view',
    tags = ['crm', 'callcenter', 'contact', 'phase2', 'all']
) }}

{% set source_name = "crm" -%}
{% set source_table = "crm_contact_hist" -%}
{% set business_key_cols = ['ID'] -%}
{% set hashdiff_contact_hist_cols = ['CIF','DATE_CONTACT','FUNC_GROUP','BRANCH_CODE','NOTES','SOUCRE','CONTACT_STATUS_ID','CONTACT_TYPE_ID','CONTACT_RESULT_ID','CONTACTNOTEID','IMPORT_ID','PROGRAM_NOTYFY_ID','SALE_CODE','PROMISE_DATE','RECALL_DATE','CONDITION_DATE','REFERENCES_DATE','DIALID','DATETIME_CREATED','DATETIME_UPDATED','USER_CREATED','USER_UPDATED','UPDATE_TIMES'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set raw_sql %}
select
    {{ hash_column(business_key_cols, source_name, false) }}                  as hashkey,
    *,
    {{ hash_column(hashdiff_contact_hist_cols, source_name, false) }}         as hashdiff_contact_hist_information,
    to_date('{{ var("target_date") }}', 'yyyyMMdd')                         as source_event_date,
    'crm'                                                                   as record_source,
    cast(current_timestamp as timestamp)                                    as load_timestamp
from {{ source(source_name, source_table) }}
where ID is not null
{%- if source_event_date_col is not none %}
  and {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
{%- endif %}
{% endset %}
{% if execute -%}
{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=none,
    source_event_date_col=none,
    source_name=source_name,
    raw_sql=raw_sql
) }}
{% endif -%}
