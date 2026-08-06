DROP TEMPORARY TABLE IF EXISTS src_ows_bin_table;
CREATE TEMPORARY TABLE src_ows_bin_table AS SELECT * FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_bin_table');
-- Source: way4.ows_bin_table (raw: way4.ows_bin_table) | Target: ref_way4_ows_bin_table (phase2)
-- Reference full load | Ref_code = cast(id as string) | filter: AMND_STATE  = 'A'
-- hashdiff_full = sha2 toan bo cot nguon (giong macro stage); source_event_date = start_date | loc data_date BETWEEN start/end (theo bronze)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_way4_ows_bin_table')
(Ref_hashkey, Ref_type, Ref_code, Ref_description, AMND_STATE, AMND_DATE, AMND_OFFICER, AMND_PREV, ID, BIN_GROUP__OID, NAME, MEMBER_ID, START_BIN, END_BIN, START_BIN_4, PAN_LENGTH, BIN_CONDITION, BIN_DETAILS, CARD_BRAND, CARD_ORG, CARD_TECHNOLOGY, CDV_ALGORITHM, CHANNEL, COUNTRY, DATA_SOURCE, EC_ATM_TYPE, FORWARDING_ID, ICA_NUMBER, PROCESSING_CLASS, PRODUCT_ID, LICENSED_PRODUCT_ID, PRODUCT_CATEGORY, REGION_FOR_ISSUER, SERVICE_INDICATOR, TERMINAL_CATEGORY, USAGE, USAGE_DOMAIN, BIN_STATUS, DATA_DATE, hashdiff_full, source_event_date, Record_source, load_timestamp)
WITH base AS (
    SELECT
        sha2(('w4_ows_bin_table' || cast(id as string)), 256) AS Ref_hashkey,
        'w4_ows_bin_table' AS Ref_type,
        cast(id as string) AS Ref_code,
        cast(name as string) AS Ref_description,
        AMND_STATE,
        AMND_DATE,
        AMND_OFFICER,
        AMND_PREV,
        ID,
        BIN_GROUP__OID,
        NAME,
        MEMBER_ID,
        START_BIN,
        END_BIN,
        START_BIN_4,
        PAN_LENGTH,
        BIN_CONDITION,
        BIN_DETAILS,
        CARD_BRAND,
        CARD_ORG,
        CARD_TECHNOLOGY,
        CDV_ALGORITHM,
        CHANNEL,
        COUNTRY,
        DATA_SOURCE,
        EC_ATM_TYPE,
        FORWARDING_ID,
        ICA_NUMBER,
        PROCESSING_CLASS,
        PRODUCT_ID,
        LICENSED_PRODUCT_ID,
        PRODUCT_CATEGORY,
        REGION_FOR_ISSUER,
        SERVICE_INDICATOR,
        TERMINAL_CATEGORY,
        USAGE,
        USAGE_DOMAIN,
        BIN_STATUS,
        DATA_DATE,
        sha2(COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(bin_group__oid AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(member_id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(start_bin AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(end_bin AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(start_bin_4 AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(pan_length AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(bin_condition AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(bin_details AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(card_brand AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(card_org AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(card_technology AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(cdv_algorithm AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(channel AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(country AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(data_source AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(ec_atm_type AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(forwarding_id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(ica_number AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(processing_class AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(product_id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(licensed_product_id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(product_category AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(region_for_issuer AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(service_indicator AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(terminal_category AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(usage AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(usage_domain AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(bin_status AS string))), ''), 256) AS hashdiff_full,
        to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_bin_table' as string) AS Record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM src_ows_bin_table
    WHERE AMND_STATE  = 'A' AND data_date BETWEEN {{start_date}} AND {{end_date}}
),
dedup AS (
    SELECT * FROM base
    WHERE Ref_hashkey IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY Ref_hashkey ORDER BY source_event_date DESC) = 1
)
SELECT d.Ref_hashkey, d.Ref_type, d.Ref_code, d.Ref_description, d.AMND_STATE, d.AMND_DATE, d.AMND_OFFICER, d.AMND_PREV, d.ID, d.BIN_GROUP__OID, d.NAME, d.MEMBER_ID, d.START_BIN, d.END_BIN, d.START_BIN_4, d.PAN_LENGTH, d.BIN_CONDITION, d.BIN_DETAILS, d.CARD_BRAND, d.CARD_ORG, d.CARD_TECHNOLOGY, d.CDV_ALGORITHM, d.CHANNEL, d.COUNTRY, d.DATA_SOURCE, d.EC_ATM_TYPE, d.FORWARDING_ID, d.ICA_NUMBER, d.PROCESSING_CLASS, d.PRODUCT_ID, d.LICENSED_PRODUCT_ID, d.PRODUCT_CATEGORY, d.REGION_FOR_ISSUER, d.SERVICE_INDICATOR, d.TERMINAL_CATEGORY, d.USAGE, d.USAGE_DOMAIN, d.BIN_STATUS, d.DATA_DATE, d.hashdiff_full, d.source_event_date, d.Record_source, d.load_timestamp
FROM dedup d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_way4_ows_bin_table') t
    ON t.Ref_hashkey = d.Ref_hashkey;
