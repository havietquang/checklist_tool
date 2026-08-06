{{ config(
    alias = 'v_stg_t24_t24_aa_arr_account',
    materialized = 'view',
    tags = ['t24', 'zonec', 'all']
) }}

{% set source_name = "t24" %}
{% set source_table = "t24_aa_arr_account" %}
{% set business_key_cols = ["substring_index(id, '-', 1)"] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_aa_arr_account_information': ['t_activity', 't_category', 't_currency', 't_l_orig_val_date', 't_l_link_ref', 't_ocb_pro_partner', 't_ocb_promotion', 't_l_ln_remark', 't_linked_tfdr_ref', 't_extend_sch', 't_extendsch_date', 't_source_of_fund', 't_term', 't_loan_subproduct', 't_loan_method', 't_loan_purpose', 't_purpose_amt', 't_ld_cust_group', 't_cu_cust_group', 't_auto_name', 't_auto_type', 't_real_type', 't_ocb_pro_bundle', 't_bpm_disb_id', 't_ocb_outof_area', 't_ocbint_chg_date', 't_repay_source', 't_action', 't_account_title_1', 't_co_code'],
    'hashdiff_aa_arr_account_regulations': ['t_l_class_covid', 't_doubtful_sta', 't_ln_class_manual', 't_vmb_ln_class', 't_vmb_class_date', 't_ftp_nd_term_int', 't_ftp_fee_repaid', 't_ftp_int_rate_tp', 't_industry_levo', 't_industry_levt', 't_industry_lev1', 't_industry_lev2', 't_industry_lev3', 't_basel_home_pp', 't_basel_rd_party', 't_basel_clr_bal', 't_cb_liab_ccy', 't_cb_liab_amt', 't_cb_liab_duedate', 't_baselderivative', 't_drvt_pr_ccy', 't_drvt_pr_amt', 't_drvt_pr_duedate', 't_crext_purpose', 't_legal_entity', 't_basel_coll', 't_ins_type', 't_ins_company', 't_ins_contract', 't_ins_fee', 't_ins_start', 't_ins_end', 't_ins_amount', 't_ins_trans', 't_ins_sales_id', 't_ins_auto_numpla'],
    'hashdiff_aa_arr_account_audit': ['t_ld_aprv_date', 't_ld_aprv_level', 't_ld_aprv_user', 't_aprv_reval_user', 't_ld_aprv_ch_date', 't_aprv_ch_desc', 't_aprv_ch_level', 't_aprv_ch_user', 't_ap_rev_ch_user', 't_inputter', 't_date_time', 't_authoriser'],
} %}

{% if execute -%}
{%- set columns = get_columns(source(source_name, source_table)) -%}
{%- set cols_name = [] -%}
{%- for column in columns -%}{%- do cols_name.append(column.name) -%}{%- endfor -%}

{%- set raw_sql %}
select
    {{ hash_column(["substring_index(id, '-', 1)"], source_name) }} as hashkey,
    {% for column in columns %}src.{{ column.name }},
    {% endfor %}
    regexp_replace(id, '^[^-]*-', '') AS ma_key,
    {{ hash_column(cols_name, source_name) }} as hashdiff_full,
    {% for k, v in hashdiff_satellite_dict.items() %}{{ hash_column(v, source_name) }} as {{ k }},
    {% endfor %}
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    '{{ source_name }}' as record_source,
    cast(current_timestamp as timestamp) as load_timestamp
from {{ source(source_name, source_table) }} src
{% if source_event_date_col is not none %}
where {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
{% endif %}
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY id
    ORDER BY {{ source_event_date_col if source_event_date_col is not none else 'id' }} DESC
) = 1
{%- endset %}

{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=hashdiff_satellite_dict,
    source_event_date_col=source_event_date_col,
    source_event_date_dttype=source_event_date_dttype,
    source_name=source_name,
    raw_sql=raw_sql
) }}
{% endif -%}
