{{ config(
    alias = 'v_stg_newfo_passbook',
    materialized = 'view',
    tags = ['newfo', 'zonec', 'all']
) }}

{% set source_name = "newfo" %}
{% set source_table = "passbook" %}
{% set business_key_cols = ['id'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_passbook': ['serialno', 'branchcode', 'status', 'price', 'passbooktype', 'useddate', 'accountno', 'damageddate', 'canceleddate', 'lostdate', 'lastdate', 'prevbranch', 'importdate', 'cif', 'note', 'custname', 'amount', 'checkstatus', 'checktrandetailid', 'lostreceiptdate', 'desposittranid'],
} %}

{% if execute -%}
{{ stage(source_table=source_table
        ,business_key_cols=business_key_cols
        ,hashdiff_satellite_dict=hashdiff_satellite_dict
        ,source_event_date_col=source_event_date_col
        ,source_event_date_dttype=source_event_date_dttype
        ,source_name=source_name)
}}
{% endif -%}
