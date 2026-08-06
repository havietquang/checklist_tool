-- Source: way4.ows_acnt_contract | Target: hub_acnt_contract, sat_acnt_contract_*, sat_card_*, sat_liability_contract_*
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_ows_acnt_contract; CREATE TEMPORARY TABLE tmp_ows_acnt_contract AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS acnt_contract_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(add_info_01      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(add_info_02      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(add_info_03      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(add_info_04      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(report_address   AS string))), ''), 256) AS hd_acnt_contract_add_data,
    sha2(COALESCE(UPPER(TRIM(CAST(auth_limit_amount  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(base_auth_limit    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(own_balance        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(own_blocked        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sub_blocked        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sub_balance        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_blocked      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_balance      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(shared_blocked     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(shared_balance     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(amount_available   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_scheme__id     AS string))), ''), 256) AS hd_account_contract_amount,
    sha2(COALESCE(UPPER(TRIM(CAST(contract_number        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contract_name          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rbs_number             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(comment_text           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contr_type             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contr_subtype__id      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(behavior_group         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(behavior_type          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(serv_pack__id          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(channel                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(curr                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_open              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_expire            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(last_billing_date      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(next_billing_date      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(last_scan              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contract_level         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contr_status           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(liab_contract          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(liab_contract_prev     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(billing_contract       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(auth_limit_amount      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(base_auth_limit        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(own_balance            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(own_blocked            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sub_blocked            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sub_balance            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_blocked          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_balance          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(shared_blocked         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(shared_balance         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(amount_available       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_scheme__id         AS string))), ''), 256) AS hd_acnt_contract_information,
    sha2(COALESCE(UPPER(TRIM(CAST(terminal_category      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(f_i                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(service_group          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_pack               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_scheme             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(parent_product         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(product_prev           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(main_product           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(client_type            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(behavior_type_prev     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_curr               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(production_status      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(report_type            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(max_pin_attempts       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(pin_attempts           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(risk_scheme            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(risk_factor            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(risk_factor_prev       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(share_balance          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_multycurrency       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(enables_item           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cycle_length           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interval_type          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(status_category        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(limit_is_active        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(routing_idt            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_ready               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(settlement_type        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(auth_seq_n             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(apply_dt               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(local_version          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(remote_version         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acnt_contract__id      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(liab_contract          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(product                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(liab_balance           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(liab_blocked           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(card_expire            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rbs_member_id          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(chip_scheme            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(merchant_id            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tr_title               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tr_company             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tr_country             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tr_first_nam           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tr_last_nam            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tr_sic                 AS string))), ''), 256) AS hd_acnt_contract_other,
    sha2(COALESCE(UPPER(TRIM(CAST(pcat             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(con_cat          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ccat             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(base_relation    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(check_available  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(check_usage      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ext_data         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(liab_category    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(relation_tag     AS string))), ''), 256) AS hd_acnt_contract_type,
    sha2(COALESCE(UPPER(TRIM(CAST(last_scan AS string))), ''), 256) AS hd_acnt_contract_scan,
    sha2(COALESCE(UPPER(TRIM(CAST(add_info_01      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(add_info_02      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(add_info_03      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(add_info_04      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(report_address   AS string))), ''), 256) AS hd_card_add_data,
    sha2(COALESCE(UPPER(TRIM(CAST(auth_limit_amount  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(base_auth_limit    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(own_balance        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(own_blocked        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sub_blocked        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sub_balance        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_blocked      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_balance      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(shared_blocked     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(shared_balance     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(amount_available   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_scheme__id     AS string))), ''), 256) AS hd_card_amount,
    sha2(COALESCE(UPPER(TRIM(CAST(contract_number    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contract_name      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tr_title           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tr_company         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tr_country         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tr_first_nam       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tr_last_nam        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tr_sic             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(comment_text       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contr_type         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contr_subtype__id  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(behavior_group     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(behavior_type      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(serv_pack__id      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_scheme__id     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(channel            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(curr               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_open          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(card_expire        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_expire        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(last_billing_date  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(next_billing_date  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(last_scan          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contract_level     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contr_status       AS string))), ''), 256) AS hd_card_information,
    sha2(COALESCE(UPPER(TRIM(CAST(terminal_category      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(f_i                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(service_group          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_pack               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_scheme             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(parent_product         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(product_prev           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(main_product           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(client_type            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(behavior_type_prev     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_curr               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(production_status      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rbs_member_id          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(report_type            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(max_pin_attempts       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(pin_attempts           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(risk_scheme            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(chip_scheme            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(risk_factor            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(risk_factor_prev       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(merchant_id            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(share_balance          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_multycurrency       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(enables_item           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cycle_length           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interval_type          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(status_category        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(limit_is_active        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(routing_idt            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_ready               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(settlement_type        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(auth_seq_n             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(apply_dt               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(local_version          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(remote_version         AS string))), ''), 256) AS hd_card_other,
    sha2(COALESCE(UPPER(TRIM(CAST(pcat             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(con_cat          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ccat             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(base_relation    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(check_available  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(check_usage      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ext_data         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(liab_category    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(relation_tag     AS string))), ''), 256) AS hd_card_type,
    sha2(COALESCE(UPPER(TRIM(CAST(add_info_01      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(add_info_02      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(add_info_03      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(add_info_04      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(report_address   AS string))), ''), 256) AS hd_liability_contract_add_data,
    sha2(COALESCE(UPPER(TRIM(CAST(auth_limit_amount  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(base_auth_limit    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(liab_balance       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(liab_blocked       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(own_balance        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(own_blocked        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sub_blocked        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sub_balance        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_blocked      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_balance      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(shared_blocked     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(shared_balance     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(amount_available   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_scheme__id     AS string))), ''), 256) AS hd_liability_contract_amount,
    sha2(COALESCE(UPPER(TRIM(CAST(contract_number    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contract_name      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(comment_text       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contr_type         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contr_subtype__id  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(serv_pack__id      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_scheme__id     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(channel            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(curr               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_open          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_expire        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(last_billing_date  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(next_billing_date  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(last_scan          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contract_level     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contr_status       AS string))), ''), 256) AS hd_liability_contract_information,
    sha2(COALESCE(UPPER(TRIM(CAST(pcat             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(con_cat          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ccat             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(base_relation    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(check_available  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(check_usage      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ext_data         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(liab_category    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(relation_tag     AS string))), ''), 256) AS hd_liability_contract_type,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    add_info_01, add_info_02, add_info_03, add_info_04, report_address,
    auth_limit_amount, base_auth_limit, own_balance, own_blocked, sub_blocked, sub_balance,
    total_blocked, total_balance, shared_blocked, shared_balance, amount_available, acc_scheme__id,
    contract_number, contract_name, rbs_number, comment_text, contr_type, contr_subtype__id,
    behavior_group, behavior_type, serv_pack__id, channel, curr, date_open, date_expire,
    last_billing_date, next_billing_date, last_scan, contract_level, contr_status,
    liab_contract, liab_contract_prev, billing_contract,
    terminal_category, f_i, service_group, old_pack, old_scheme, parent_product, product_prev,
    main_product, client_type, behavior_type_prev, old_curr, production_status, report_type,
    max_pin_attempts, pin_attempts, risk_scheme, risk_factor, risk_factor_prev, share_balance,
    is_multycurrency, enables_item, cycle_length, interval_type, status_category, limit_is_active,
    routing_idt, is_ready, settlement_type, auth_seq_n, apply_dt, local_version, remote_version,
    acnt_contract__id, product, liab_balance, liab_blocked, card_expire, rbs_member_id,
    chip_scheme, merchant_id, tr_title, tr_company, tr_country, tr_first_nam, tr_last_nam, tr_sic,
    pcat, con_cat, ccat, base_relation, check_available, check_usage, ext_data, liab_category, relation_tag
FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_acnt_contract')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL AND amnd_state = 'A';

-- SAT: sat_acnt_contract_scan
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_acnt_contract_scan')
(acnt_contract_hashkey, hashdiff, source_event_date, load_timestamp, record_source, last_scan)
WITH deduped AS (SELECT * FROM tmp_ows_acnt_contract QUALIFY ROW_NUMBER() OVER (PARTITION BY acnt_contract_hashkey, hd_acnt_contract_scan ORDER BY data_date) = 1)
SELECT d.acnt_contract_hashkey, d.hd_acnt_contract_scan, d.source_event_date, current_timestamp(), 'way4__ows_acnt_contract',
       d.last_scan
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_acnt_contract_scan') t
    ON t.acnt_contract_hashkey = d.acnt_contract_hashkey AND t.hashdiff = d.hd_acnt_contract_scan;

-- STS HUB: sts_hub_acnt_contract (CDC delete/reinsert tren snapshot data_date trong [start,end]; doc tu tmp_ows_acnt_contract)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_acnt_contract')
(acnt_contract_hashkey, source_event_date, cdc_status)
WITH staging AS (
    SELECT DISTINCT acnt_contract_hashkey, data_date FROM tmp_ows_acnt_contract
),
days AS (SELECT DISTINCT data_date FROM staging),
key_first AS (
    SELECT acnt_contract_hashkey, MIN(data_date) AS first_day FROM staging GROUP BY acnt_contract_hashkey
),
grid AS (
    SELECT k.acnt_contract_hashkey, d.data_date
    FROM key_first k JOIN days d ON d.data_date >= k.first_day
),
flagged AS (
    SELECT g.acnt_contract_hashkey, g.data_date,
           CASE WHEN s.acnt_contract_hashkey IS NOT NULL THEN 1 ELSE 0 END AS present
    FROM grid g
    LEFT JOIN staging s ON s.acnt_contract_hashkey = g.acnt_contract_hashkey AND s.data_date = g.data_date
),
trans AS (
    SELECT acnt_contract_hashkey, data_date, present,
           lag(present) OVER (PARTITION BY acnt_contract_hashkey ORDER BY data_date) AS prev_present
    FROM flagged
),
cdc AS (
    SELECT acnt_contract_hashkey, to_date(CAST(data_date AS string), 'yyyyMMdd') AS source_event_date, CAST('D' AS string) AS cdc_status
    FROM trans WHERE prev_present = 1 AND present = 0
    UNION ALL
    SELECT acnt_contract_hashkey, to_date(CAST(data_date AS string), 'yyyyMMdd') AS source_event_date, CAST('I' AS string) AS cdc_status
    FROM trans WHERE prev_present = 0 AND present = 1
)
SELECT d.acnt_contract_hashkey, d.source_event_date, d.cdc_status
FROM cdc d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_acnt_contract') t
    ON t.acnt_contract_hashkey = d.acnt_contract_hashkey
   AND t.source_event_date = d.source_event_date
   AND t.cdc_status = d.cdc_status;

DROP TEMPORARY TABLE IF EXISTS tmp_ows_acnt_contract;
