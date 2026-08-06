-- ============================================================
-- Source table  : .callcenter.callcenter
-- Target tables : hub_callcenter
--                 sat_callcenter_information
--                 sat_callcenter_outcome
--                 link_callcenter_customer
-- Date range    : 20250101 -> 20250131 (str+date on calldatetime)
-- ============================================================

DROP TEMPORARY TABLE IF EXISTS tmp_callcenter;
CREATE TEMPORARY TABLE tmp_callcenter AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(_id AS string))), ''), 256) AS callcenter_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(uniqueid          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gcalluuid         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(accountcode       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dialid            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sipserver         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(src               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dst               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(channel           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dstchannel        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(queue             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(in_out            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(did_number        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(prefix_detail     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(carrier           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(callername        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(customer_id       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(customer_code     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(customername      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(customercif       AS string))), ''), 256) AS hd_callcenter_information,
    sha2(COALESCE(UPPER(TRIM(CAST(calldate              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(calldatetime          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(createtime            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(duration              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(billsec              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(billtime             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(holdtime             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(talktime             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(waitingtime          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(moh_time             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(disposition           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(system_disposition    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(extension_disposition AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(calltype              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hangup_by             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(connected             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(not_connected         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(processed             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(filename              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(moh_log              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(moh_log_process      AS string))), ''), 256) AS hd_callcenter_outcome,
    to_date(regexp_replace(substr(calldatetime, 1, 10), '-', ''), 'yyyyMMdd') AS source_event_date,
    _id,
    uniqueid,
    gcalluuid,
    accountcode,
    dialid,
    sipserver,
    src,
    dst,
    channel,
    dstchannel,
    queue,
    in_out,
    did_number,
    prefix_detail,
    carrier,
    callername,
    customer_id,
    customer_code,
    customername,
    customercif,
    calldate,
    calldatetime,
    createtime,
    duration,
    billsec,
    billtime,
    holdtime,
    talktime,
    waitingtime,
    moh_time,
    disposition,
    system_disposition,
    extension_disposition,
    calltype,
    hangup_by,
    connected,
    not_connected,
    processed,
    filename,
    moh_log,
    moh_log_process
FROM IDENTIFIER({{catalog_sourcing}} || '.callcenter.callcenter')
WHERE to_date(regexp_replace(substr(calldatetime, 1, 10), '-', ''), 'yyyyMMdd') BETWEEN to_date({{start_date}}, 'yyyyMMdd') AND to_date({{end_date}}, 'yyyyMMdd')
  AND _id IS NOT NULL;

-- ============================================================
-- INSERT HUB
-- Ghi chu: hub_callcenter chi co 1 nguon (callcenter__callcenter),
-- khong phai hub da nguon -> khong can script hub rieng union/source_priority.
-- ============================================================
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_callcenter')
(callcenter_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (
    SELECT * FROM tmp_callcenter
    QUALIFY ROW_NUMBER() OVER (PARTITION BY callcenter_hashkey ORDER BY source_event_date) = 1
)
SELECT
    d.callcenter_hashkey AS callcenter_hashkey,
    CAST(d._id AS STRING) AS business_key,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'callcenter__callcenter' AS record_source
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_callcenter') t
    ON t.callcenter_hashkey = d.callcenter_hashkey;

-- ============================================================
-- INSERT SATELLITE: sat_callcenter_information
-- ============================================================
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_callcenter_information')
(callcenter_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 uniqueid, gcalluuid, accountcode, dialid, sipserver, src, dst, channel, dstchannel,
 queue, in_out, did_number, prefix_detail, carrier, callername, customer_id,
 customer_code, customername, customercif)
WITH deduped AS (
    SELECT * FROM tmp_callcenter
    QUALIFY ROW_NUMBER() OVER (PARTITION BY callcenter_hashkey, hd_callcenter_information ORDER BY source_event_date) = 1
)
SELECT
    d.callcenter_hashkey AS callcenter_hashkey,
    d.hd_callcenter_information AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'callcenter__callcenter' AS record_source,
    d.uniqueid AS uniqueid,
    d.gcalluuid AS gcalluuid,
    d.accountcode AS accountcode,
    d.dialid AS dialid,
    d.sipserver AS sipserver,
    d.src AS src,
    d.dst AS dst,
    d.channel AS channel,
    d.dstchannel AS dstchannel,
    d.queue AS queue,
    d.in_out AS in_out,
    d.did_number AS did_number,
    d.prefix_detail AS prefix_detail,
    d.carrier AS carrier,
    d.callername AS callername,
    d.customer_id AS customer_id,
    d.customer_code AS customer_code,
    d.customername AS customername,
    d.customercif AS customercif
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_callcenter_information') t
    ON t.callcenter_hashkey = d.callcenter_hashkey AND t.hashdiff = d.hd_callcenter_information;

-- ============================================================
-- INSERT SATELLITE: sat_callcenter_outcome
-- ============================================================
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_callcenter_outcome')
(callcenter_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 calldate, calldatetime, createtime, duration, billsec, billtime, holdtime, talktime,
 waitingtime, moh_time, disposition, system_disposition, extension_disposition,
 calltype, hangup_by, connected, not_connected, processed, filename, moh_log, moh_log_process)
WITH deduped AS (
    SELECT * FROM tmp_callcenter
    QUALIFY ROW_NUMBER() OVER (PARTITION BY callcenter_hashkey, hd_callcenter_outcome ORDER BY source_event_date) = 1
)
SELECT
    d.callcenter_hashkey AS callcenter_hashkey,
    d.hd_callcenter_outcome AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'callcenter__callcenter' AS record_source,
    d.calldate AS calldate,
    d.calldatetime AS calldatetime,
    d.createtime AS createtime,
    d.duration AS duration,
    d.billsec AS billsec,
    d.billtime AS billtime,
    d.holdtime AS holdtime,
    d.talktime AS talktime,
    d.waitingtime AS waitingtime,
    d.moh_time AS moh_time,
    d.disposition AS disposition,
    d.system_disposition AS system_disposition,
    d.extension_disposition AS extension_disposition,
    d.calltype AS calltype,
    d.hangup_by AS hangup_by,
    d.connected AS connected,
    d.not_connected AS not_connected,
    d.processed AS processed,
    d.filename AS filename,
    d.moh_log AS moh_log,
    d.moh_log_process AS moh_log_process
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_callcenter_outcome') t
    ON t.callcenter_hashkey = d.callcenter_hashkey AND t.hashdiff = d.hd_callcenter_outcome;

-- ============================================================
-- INSERT LINK: link_callcenter_customer
-- Bung mang customercif (JSON array<string>) thanh tung cif,
-- link callcenter_hashkey (=hash _id) voi customer_hashkey (=hash cif).
-- ============================================================
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_callcenter_customer')
(link_callcenter_customer_hashkey, callcenter_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp)
WITH hash_multival AS (
    SELECT DISTINCT
        _id,
        explode(from_json(customercif, 'array<string>')) AS cif,
        callcenter_hashkey,
        source_event_date
    FROM tmp_callcenter
    WHERE customercif IS NOT NULL
),
link_rows AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(_id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(cif AS string))), ''), 256) AS link_callcenter_customer_hashkey,
        callcenter_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(cif AS string))), ''), 256) AS customer_hashkey,
        source_event_date,
        'callcenter__callcenter' AS record_source,
        current_timestamp() AS load_timestamp
    FROM hash_multival
    WHERE cif IS NOT NULL
      AND _id IS NOT NULL
),
dedup AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY link_callcenter_customer_hashkey
            ORDER BY source_event_date DESC, load_timestamp DESC
        ) AS rn
    FROM link_rows
)
SELECT
    d.link_callcenter_customer_hashkey AS link_callcenter_customer_hashkey,
    d.callcenter_hashkey AS callcenter_hashkey,
    d.customer_hashkey AS customer_hashkey,
    d.source_event_date AS source_event_date,
    d.record_source AS record_source,
    d.load_timestamp AS load_timestamp
FROM dedup d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_callcenter_customer') t
    ON t.link_callcenter_customer_hashkey = d.link_callcenter_customer_hashkey
WHERE d.rn = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_callcenter;
