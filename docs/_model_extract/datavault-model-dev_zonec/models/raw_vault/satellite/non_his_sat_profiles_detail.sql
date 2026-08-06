{{ config(
    alias = 'non_his_sat_profiles_detail',
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
{% set list_cols = ['averagecasarecent1month', 'averagecasarecent3month', 'averagecasarecent6month', 'totalaccountbalancevnd', 'groupavgcasarecent1month', 'groupavgcasarecent3month', 'groupavgcasarecent6month', 'grouptotalaccbalancevnd', 'group_avg_casa_recent_1_mth', 'group_avg_casa_recent_3_mth', 'group_avg_casa_recent_6_mth', 'group_total_acc_balance_vnd', 'aum', 'depositnearestaccountdate', 'haveonlinesavingbook', 'lastonlinesavingdate', 'lastsavingdate', 'grouptotalesavingbalancevnd', 'deposit_nearest_account_date', 'group_total_esaving_balance_vnd', 'last_online_savings_date', 'last_savings_bank', 'avgnumbertranstopupinmonth', 'firsttransaction', 'havebillpayment', 'latesttopup', 'latesttransaction', 'numbertransin12month', 'numbertransin1month', 'numbertransin3month', 'numbertransferin12month', 'numbertransferin1month', 'numbertransferin3month', 'avg_num_trans_topup_mth', 'first_omni_tnx', 'latest_omni_tnx', 'latest_topup', 'num_transfer_12_mth', 'num_transfer_1_mth', 'num_transfer_3_mth', 'num_trans_12_mth', 'num_trans_1_mth', 'num_trans_3_mth', 'have_auto_bill', 'avgcreditcardtransday', 'avgcreditcardtransmth', 'billduedate', 'duedateviacard', 'havecreditcard', 'havedebitcard', 'latestcardpay', 'totalcardcreditamount', 'latepaymentstatus', 'avg_creditcard_trans_day', 'avg_creditcard_trans_mth', 'bill_due_date', 'due_date_via_card', 'late_payment_status', 'latest_card_pay', 'mastercard_card_linked_to_applepay', 'napas_card_linked_to_applepay', 'visa_card_linked_to_applepay', 'currentcoins', 'loyaltystatus', 'current_coins', 'campaign_codes', 'number_of_voucher_series']
 %}

{{ non_his_satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    list_cols=list_cols
) }}
