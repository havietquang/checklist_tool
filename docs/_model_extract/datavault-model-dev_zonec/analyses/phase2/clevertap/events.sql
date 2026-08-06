-- Source  : .clevertap.events
-- Targets : hub_events
--           sts_hub_events
--           sat_events_information
-- Range   : 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_events; CREATE TEMPORARY TABLE tmp_events AS
SELECT
    sha2(COALESCE(TRIM(CAST(ts              AS string)), '') || '$' ||
         COALESCE(TRIM(CAST(eventName       AS string)), '') || '$' ||
         COALESCE(TRIM(CAST(eventProps      AS string)), '') || '$' ||
         COALESCE(TRIM(CAST(profile:identity AS string)), ''), 256) AS events_hashkey,
    sha2(COALESCE(TRIM(CAST(profile         AS string)), '') || '$' ||
         COALESCE(TRIM(CAST(deviceInfo      AS string)), ''), 256) AS hd_events_information,
    data_date,
    to_date(substr(ts, 1, 8), 'yyyyMMdd') AS source_event_date,
    ts, profile, profile:identity, eventName, eventProps, deviceInfo
FROM IDENTIFIER({{catalog_sourcing}} || '.clevertap.events')
WHERE to_date(substr(ts, 1, 8), 'yyyyMMdd') BETWEEN to_date({{start_date}}, 'yyyyMMdd') AND to_date({{end_date}}, 'yyyyMMdd')
  AND ts IS NOT NULL
  AND eventName IS NOT NULL
  AND eventProps IS NOT NULL
  AND profile:identity IS NOT NULL
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY ts, eventName, eventProps, profile:identity
    ORDER BY deviceInfo DESC NULLS LAST
) = 1;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_events')
(events_hashkey, ts, eventName, eventProps, identity, source_event_date, record_source, load_timestamp)
WITH deduped AS (SELECT * FROM tmp_events QUALIFY ROW_NUMBER() OVER (PARTITION BY events_hashkey ORDER BY data_date) = 1)
SELECT
    d.events_hashkey AS events_hashkey,
    d.ts AS ts,
    d.eventName AS eventName,
    d.eventProps AS eventProps,
    d.profile:identity AS identity,
    d.source_event_date AS source_event_date,
    'clevertap__events' AS record_source,
    current_timestamp() AS load_timestamp
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_events') t
    ON t.events_hashkey = d.events_hashkey;


INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_events_information')
(events_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 profile, deviceInfo)
WITH deduped AS (SELECT * FROM tmp_events QUALIFY ROW_NUMBER() OVER (PARTITION BY events_hashkey, hd_events_information ORDER BY data_date) = 1)
SELECT
    d.events_hashkey AS events_hashkey,
    d.hd_events_information AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'clevertap__events' AS record_source,
    CAST(d.profile AS STRING) AS profile,
    CAST(d.deviceInfo AS STRING) AS deviceInfo
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_events_information') t
    ON t.events_hashkey = d.events_hashkey AND t.hashdiff = d.hd_events_information;

-- [sts_hub_events] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_events')
(events_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_events
),
present_per_date AS (
    SELECT DISTINCT events_hashkey, source_event_date FROM tmp_events
),
full_timeline AS (
    SELECT DISTINCT h.events_hashkey, d.source_event_date,
           CASE WHEN p.events_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_events') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.events_hashkey = h.events_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT events_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY events_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT events_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_events')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_events)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY events_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.events_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.events_hashkey = t.events_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.events_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.events_hashkey = t.events_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.events_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_events') t
    ON t.events_hashkey = sc.events_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

DROP TEMPORARY TABLE IF EXISTS tmp_events;
