-- depends_on: {{ ref('ref_bpm_auth_nhom') }}
-- depends_on: {{ ref('ref_bpm_c_danh_muc') }}
-- depends_on: {{ ref('ref_bpm_danh_muc') }}
-- depends_on: {{ ref('ref_bpm_sk10_san_pham') }}
-- depends_on: {{ ref('ref_crm_contact_result') }}
-- depends_on: {{ ref('ref_crm_contact_status') }}
-- depends_on: {{ ref('ref_crm_contact_type') }}
-- depends_on: {{ ref('ref_crm_custgroup') }}
-- depends_on: {{ ref('ref_omni_fee_discount') }}
-- depends_on: {{ ref('ref_omni_master_data') }}
-- depends_on: {{ ref('ref_omni_package') }}
-- depends_on: {{ ref('ref_omni_service_provider') }}
-- depends_on: {{ ref('ref_omni_service_type') }}
-- depends_on: {{ ref('ref_omni_services') }}
-- depends_on: {{ ref('ref_t24_acct_gen_condition') }}
-- depends_on: {{ ref('ref_t24_auto_name') }}
-- depends_on: {{ ref('ref_t24_az_product_parameter') }}
-- depends_on: {{ ref('ref_t24_basic_interest') }}
-- depends_on: {{ ref('ref_t24_bc_sort_code') }}
-- depends_on: {{ ref('ref_t24_bosc_comp_reg') }}
-- depends_on: {{ ref('ref_t24_category') }}
-- depends_on: {{ ref('ref_t24_collateral_code') }}
-- depends_on: {{ ref('ref_t24_collateral_type') }}
-- depends_on: {{ ref('ref_t24_company') }}
-- depends_on: {{ ref('ref_t24_country') }}
-- depends_on: {{ ref('ref_t24_de_bic') }}
-- depends_on: {{ ref('ref_t24_dealer_desk') }}
-- depends_on: {{ ref('ref_t24_department') }}
-- depends_on: {{ ref('ref_t24_ft_txn_type_condition') }}
-- depends_on: {{ ref('ref_t24_industry') }}
-- depends_on: {{ ref('ref_t24_int_chg_type') }}
-- depends_on: {{ ref('ref_t24_job_title') }}
-- depends_on: {{ ref('ref_t24_lc_types') }}
-- depends_on: {{ ref('ref_t24_ld_aprv_user') }}
-- depends_on: {{ ref('ref_t24_ld_economic_sector') }}
-- depends_on: {{ ref('ref_t24_ld_ins_type_comp') }}
-- depends_on: {{ ref('ref_t24_ld_partner') }}
-- depends_on: {{ ref('ref_t24_ld_promotion') }}
-- depends_on: {{ ref('ref_t24_limit_level_auth') }}
-- depends_on: {{ ref('ref_t24_limit_reference') }}
-- depends_on: {{ ref('ref_t24_loan_method') }}
-- depends_on: {{ ref('ref_t24_loan_purpose') }}
-- depends_on: {{ ref('ref_t24_loan_subproduct') }}
-- depends_on: {{ ref('ref_t24_ocbh_classification') }}
-- depends_on: {{ ref('ref_t24_ocbh_coll_borrow_purpose') }}
-- depends_on: {{ ref('ref_t24_ocbh_coll_rev_agent') }}
-- depends_on: {{ ref('ref_t24_ocbh_cus_group') }}
-- depends_on: {{ ref('ref_t24_ocbh_deposit_prgm') }}
-- depends_on: {{ ref('ref_t24_ocbh_ft_outward_purpose') }}
-- depends_on: {{ ref('ref_t24_ocbh_fx_buyfcy_purpose') }}
-- depends_on: {{ ref('ref_t24_ocbh_ld_prod_main') }}
-- depends_on: {{ ref('ref_t24_ocbh_loan_pro_bundle') }}
-- depends_on: {{ ref('ref_t24_ocbh_md_purpose') }}
-- depends_on: {{ ref('ref_t24_ocbh_product_package') }}
-- depends_on: {{ ref('ref_t24_ocbt_sub_industry') }}
-- depends_on: {{ ref('ref_t24_occupation') }}
-- depends_on: {{ ref('ref_t24_posting_restrict') }}
-- depends_on: {{ ref('ref_t24_prod_package_cb') }}
-- depends_on: {{ ref('ref_t24_province') }}
-- depends_on: {{ ref('ref_t24_re_stat_line_cont') }}
-- depends_on: {{ ref('ref_t24_re_stat_rep_line') }}
-- depends_on: {{ ref('ref_t24_re_txn_code') }}
-- depends_on: {{ ref('ref_t24_sc_trans_name') }}
-- depends_on: {{ ref('ref_t24_sec_acc_master') }}
-- depends_on: {{ ref('ref_t24_sector') }}
-- depends_on: {{ ref('ref_t24_sub_asset_type') }}
-- depends_on: {{ ref('ref_t24_teller_transaction') }}
-- depends_on: {{ ref('ref_t24_town') }}
-- depends_on: {{ ref('ref_t24_transaction') }}
-- depends_on: {{ ref('ref_way4_account_type') }}
-- depends_on: {{ ref('ref_way4_contr_status') }}
-- depends_on: {{ ref('ref_way4_cs_status_type') }}
-- depends_on: {{ ref('ref_way4_cs_status_value') }}
-- depends_on: {{ ref('ref_way4_mess_channel') }}
-- depends_on: {{ ref('ref_way4_ows_add_data') }}
-- depends_on: {{ ref('ref_way4_ows_bank_unit') }}
-- depends_on: {{ ref('ref_way4_ows_bin_table') }}
-- depends_on: {{ ref('ref_way4_ows_event_type') }}
-- depends_on: {{ ref('ref_way4_ows_evnt_action') }}
-- depends_on: {{ ref('ref_way4_ows_td_auth_type') }}
-- depends_on: {{ ref('ref_way4_resp_code') }}
-- depends_on: {{ ref('ref_way4_sic') }}
-- depends_on: {{ ref('ref_way4_trans_cond') }}
-- depends_on: {{ ref('ref_way4_trans_type') }}

{{ config(
    alias = 'reference',
    materialized = 'view',
    tags = ['reference_all', 'all']
) }}

{% set queries = [] %}

{% for node in graph.nodes.values() %}

    {% if node.resource_type == 'model'
        and node.original_file_path.startswith('models/raw_vault/reference/reference_in_master_ref')
        and node.name.startswith('ref_') %}
        {% set raw_sql %}
            select
                ref_hashkey,
                ref_type,
                ref_code,
                ref_description,
                to_json(struct(* except(
                    ref_hashkey,
                    ref_type,
                    ref_code,
                    ref_description,
                    hashdiff,
                    source_event_date,
                    record_source,
                    load_timestamp
                ))) as ref_all_attributes,
                hashdiff,
                source_event_date,
                record_source,
                load_timestamp
            from {{ ref(node.name) }}
            where source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
            qualify row_number() over (partition by ref_hashkey order by source_event_date desc) = 1
        {% endset %}
        {% do queries.append(raw_sql) %}
    {% endif %}
{% endfor %}

{{ queries | join('\nUNION ALL\n') }}
