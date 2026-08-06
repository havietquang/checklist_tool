{{ config(
    alias = 'sat_ldm_partner_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['ldm_partner_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['qldt', 'zonec', 'all']
) }}

{% set source_name = 'qldt' %}
{% set source_table = 'ldm_partner' %}
{% set hashdiff_col = 'hashdiff_ldm_partner_information' %}
{% set hub_hashkey = 'ldm_partner_hashkey' %}
{% set source_model = 'v_stg_qldt_ldm_partner' %}
{% set list_cols = [
    'cif',
    'partner_type_id',
    'partner_name',
    'short_name',
    'commission_rate_limit',
    'brand_id',
    'create_date_time',
    'user_create',
    'status',
    'approve_date_time',
    'user_approve',
    'branch_code',
    'business_code',
    'business_name',
    'cust_group',
    'web',
    'contract_date',
    'founded_date',
    'second_hand',
    'private',
    'position',
    'phone_number',
    'email',
    'note',
    'cif_full_name',
    'account_officer_id',
    'account_officer_name',
    'branch_contact',
    'last_user_update',
    'last_date_update',
    'reject_note',
    'partner_id_t24',
    'car_number',
    'staff_number',
    'commission_rate_loan',
    'partner_account_number',
    'partner_bank_at',
    'cust_group_comfirm',
    'fax',
    'contract',
    'english_name',
    'business_type'
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
