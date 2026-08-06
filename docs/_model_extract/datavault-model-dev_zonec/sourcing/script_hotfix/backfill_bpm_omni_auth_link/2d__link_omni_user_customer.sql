-- =============================================================================
-- Source : ocb_datavault_prod_sourcing.omni.en_user
-- Target : link_omni_user_customer
-- Link key: sha2(UPPER(id) || '$' || TRIM(cif), 256)  -- CIF khong uppercase
-- CIF    : regexp_extract(additions, '"cif":"([0-9]+)"', 1)
-- Note   : omni.en_user khong co data_date → doc toan bo, dedup by etl_time
-- =============================================================================

TRUNCATE TABLE ocb_datavault_prod_cleaned.raw_vault.link_omni_user_customer;

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_omni_user_customer
(link_omni_user_customer_hashkey, omni_user_hashkey, customer_hashkey,
 source_event_date, load_timestamp, record_source)
SELECT
    sha2(
        COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
        CASE
            WHEN regexp_extract(additions, '"cif":"([0-9]+)"', 1) IS NULL THEN ''
            ELSE TRIM(CAST(regexp_extract(additions, '"cif":"([0-9]+)"', 1) AS string))
        END
    , 256)                                                               AS link_omni_user_customer_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256)            AS omni_user_hashkey,
    sha2(
        CASE
            WHEN regexp_extract(additions, '"cif":"([0-9]+)"', 1) IS NULL THEN ''
            ELSE TRIM(CAST(regexp_extract(additions, '"cif":"([0-9]+)"', 1) AS string))
        END
    , 256)                                                               AS customer_hashkey,
    to_date('20230301', 'yyyyMMdd')                                      AS source_event_date,
    current_timestamp(),
    'omni__en_user'
FROM ocb_datavault_prod_sourcing.omni.en_user
WHERE id IS NOT NULL
  AND regexp_extract(additions, '"cif":"([0-9]+)"', 1) IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY id, regexp_extract(additions, '"cif":"([0-9]+)"', 1) ORDER BY etl_time DESC) = 1;
