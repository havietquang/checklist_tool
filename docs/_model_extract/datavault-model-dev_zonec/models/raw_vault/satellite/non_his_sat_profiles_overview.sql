{{ config(
    alias = 'non_his_sat_profiles_overview',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['source_event_date'],
    skip_matched_step = false,
    tags = ['clevertap', 'profiles', 'zonec']
) }}

{% set source_name = 'clevertap' %}
{% set source_table = 'profiles' %}
{% set hub_hashkey = 'profiles_hashkey' %}
{% set source_model = 'v_stg_clevertap_profiles' %}
{% set list_cols = ['subscriptiongroups', 'msg_webpush', 'msg_push', 'msg_email', 'msg_sms', 'msg_whatsapp', 'email', 'phone', 'name', 'gender', 'dob', 'photo', 'ct_is_test_user', 'country', 'type', 'cif', 'language1', 'fullname', '`group`', 'partner', 'useragreement', 'omni_status', 'source_campaign', 'source_id', 'user_agreement', 'birth_date', 'group_sale', 'accept_promotion', 'mystuff', 'marital_status', 'segment', 'accountcategory', 'accounttype', 'ebankingpackage', 'account_type', 'nice_acc_source', 'nice_acc_type', 'acc_category', 'ebanking', 'account', 'cardinfo', 'casadeposit', 'loyalty', 'transactions', 'userprofile', 'network', 'omnistatus', 'prioritystatus', '`source`', 'sourcecampaign', 'sourceid', 'serialversionuid', 'orderquantity', 'order_quantity']
 %}

{{ non_his_satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    list_cols=list_cols
) }}
