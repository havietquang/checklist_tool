{{ config(
    alias = 'sat_ldm_partner_detail',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['ldm_partner_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['qldt', 'zonec', 'all']
) }}

{% set source_name = 'qldt' %}
{% set source_table = 'ldm_partner' %}
{% set hashdiff_col = 'hashdiff_ldm_partner_detail' %}
{% set hub_hashkey = 'ldm_partner_hashkey' %}
{% set source_model = 'v_stg_qldt_ldm_partner' %}
{% set list_cols = [
    'vicegerent_name',
    'vicegerent_position',
    'vicegernet_phone_number',
    'contact_name',
    'contact_position',
    'contact_phone_number',
    'business_home_address',
    'business_province_address',
    'business_district_address',
    'business_town_address',
    'current_b_home_address',
    'current_b_province_address',
    'current_b_district_address',
    'current_b_town_address',
    'owner_home_address',
    'owner_province_address',
    'owner_district_address',
    'owner_town_address',
    'project_home_address',
    'project_province_address',
    'project_district_address',
    'project_town_address',
    'office_home_address',
    'office_province_address',
    'office_district_address',
    'office_town_address',
    'ho_contact',
    'ho_position',
    'ho_phone_number',
    'ho_email',
    'branch_position',
    'branch_phone_number',
    'branch_email',
    'vicegerent_email',
    'vicegerent_cell_phone',
    'contact_mail',
    'contact_cell_phone',
    'office_phone_number',
    'office_fax',
    'expired_date',
    'auto_extend',
    'status_coop',
    'reason_coop'
] %}
{% set raw_sql = None %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}
