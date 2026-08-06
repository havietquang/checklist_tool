-- ============================================================================
-- BACKFILL: pit_account - bo sung cac account bi thieu hoan toan do filter cu

USE CATALOG ocb_datavault_prod_cleaned;

-- ----------------------------------------------------------------------------


-- ----------------------------------------------------------------------------
--  Backfill toan bo lich su snapshot_date cho cac account bi thieu
--    (giu nguyen logic tinh cot y het models/business_vault/pit/pit_account.sql,
--     chi thay to_date(target_date) bang tung snapshot_date da co tren live,
--     va gioi han hub_account theo record_source <> 't24__t24_account')
-- ----------------------------------------------------------------------------

INSERT INTO business_vault.pit_account
(
    account_hashkey,
    snapshot_date,
    sat_deposits_rate_src_ev_dt,
    sat_deposits_information_src_ev_dt,
    sat_deposits_terms_src_ev_dt,
    sat_account_balance_src_ev_dt,
    sat_account_information_src_ev_dt,
    sat_account_classification_src_ev_dt
)
WITH snapshot_dates AS (
    SELECT DISTINCT snapshot_date
    FROM business_vault.pit_account
),
missing_hub_account AS (
    SELECT account_hashkey, source_event_date
    FROM raw_vault.hub_account
    WHERE record_source <> 't24__t24_account'
),
hub_deposits AS (
    SELECT deposit_hashkey, source_event_date
    FROM raw_vault.hub_deposits
)
SELECT
    h.account_hashkey,
    d.snapshot_date,
    max(sdr.source_event_date) AS sat_deposits_rate_src_ev_dt,
    max(sdi.source_event_date) AS sat_deposits_information_src_ev_dt,
    max(sdt.source_event_date) AS sat_deposits_terms_src_ev_dt,
    max(sab.source_event_date) AS sat_account_balance_src_ev_dt,
    max(sai.source_event_date) AS sat_account_information_src_ev_dt,
    max(sac.source_event_date) AS sat_account_classification_src_ev_dt
FROM missing_hub_account h
CROSS JOIN snapshot_dates d
LEFT JOIN hub_deposits hdp
    ON h.account_hashkey = hdp.deposit_hashkey
   AND hdp.source_event_date <= d.snapshot_date
LEFT JOIN raw_vault.sat_deposits_rate sdr
    ON hdp.deposit_hashkey = sdr.deposit_hashkey
   AND sdr.source_event_date <= d.snapshot_date
LEFT JOIN raw_vault.sat_deposits_information sdi
    ON hdp.deposit_hashkey = sdi.deposit_hashkey
   AND sdi.source_event_date <= d.snapshot_date
LEFT JOIN raw_vault.sat_deposits_terms sdt
    ON hdp.deposit_hashkey = sdt.deposit_hashkey
   AND sdt.source_event_date <= d.snapshot_date
LEFT JOIN raw_vault.sat_account_balance sab
    ON h.account_hashkey = sab.account_hashkey
   AND sab.source_event_date <= d.snapshot_date
LEFT JOIN raw_vault.sat_account_information sai
    ON h.account_hashkey = sai.account_hashkey
   AND sai.source_event_date <= d.snapshot_date
LEFT JOIN raw_vault.sat_account_classification sac
    ON h.account_hashkey = sac.account_hashkey
   AND sac.source_event_date <= d.snapshot_date
WHERE h.source_event_date <= d.snapshot_date
  AND NOT EXISTS (
        SELECT 1 FROM business_vault.pit_account p
        WHERE p.account_hashkey = h.account_hashkey
          AND p.snapshot_date = d.snapshot_date
  )
GROUP BY h.account_hashkey, d.snapshot_date;

-- ----------------------------------------------------------------------------