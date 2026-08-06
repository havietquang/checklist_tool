{{ config(
    alias = 'v_stg_qldt_ldm_partner',
    materialized = 'view',
    tags = ['qldt', 'zonec', 'all']
) }}

{% set source_name = "qldt" %}
{% set source_table = "ldm_partner" %}
{% set business_key_cols = ['partner_id'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_ldm_partner_information': ['cif', 'partner_type_id', 'partner_name', 'short_name', 'commission_rate_limit', 'brand_id', 'create_date_time', 'user_create', 'status', 'approve_date_time', 'user_approve', 'branch_code', 'business_code', 'business_name', 'cust_group', 'web', 'contract_date', 'founded_date', 'second_hand', 'private', 'position', 'phone_number', 'email', 'note', 'cif_full_name', 'account_officer_id', 'account_officer_name', 'branch_contact', 'last_user_update', 'last_date_update', 'reject_note', 'partner_id_t24', 'car_number', 'staff_number', 'commission_rate_loan', 'partner_account_number', 'partner_bank_at', 'cust_group_comfirm', 'fax', 'contract', 'english_name', 'business_type'],
    'hashdiff_ldm_partner_detail': ['vicegerent_name', 'vicegerent_position', 'vicegernet_phone_number', 'contact_name', 'contact_position', 'contact_phone_number', 'business_home_address', 'business_province_address', 'business_district_address', 'business_town_address', 'current_b_home_address', 'current_b_province_address', 'current_b_district_address', 'current_b_town_address', 'owner_home_address', 'owner_province_address', 'owner_district_address', 'owner_town_address', 'project_home_address', 'project_province_address', 'project_district_address', 'project_town_address', 'office_home_address', 'office_province_address', 'office_district_address', 'office_town_address', 'ho_contact', 'ho_position', 'ho_phone_number', 'ho_email', 'branch_position', 'branch_phone_number', 'branch_email', 'vicegerent_email', 'vicegerent_cell_phone', 'contact_mail', 'contact_cell_phone', 'office_phone_number', 'office_fax', 'expired_date', 'auto_extend', 'status_coop', 'reason_coop'],
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
