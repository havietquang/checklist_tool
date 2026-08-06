{{ config(
    alias = 'v_stg_crm_crm_contact_result',
    materialized = 'view',
    tags = ['crm', 'reference', 'phase2', 'all']
) }}

{% set source_name = "crm" -%}
{% set source_table = "crm_contact_result" -%}
{% set business_key_cols = ['contact_result_id'] -%}
{% set list_cols = ['contact_result_id', 'contact_result_name', 'status', 'position', 'insurance', 'expired_card_prio', 'cust_group'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict = none -%}

{% if execute -%}
{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=hashdiff_satellite_dict,
    source_event_date_col=source_event_date_col,
    source_name=source_name
        ,list_cols=list_cols
        ) }}
{% endif -%}
