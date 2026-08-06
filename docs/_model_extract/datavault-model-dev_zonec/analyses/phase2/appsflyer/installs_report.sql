-- ============================================================
-- Source  : .appsflyer.installs_report
-- Targets : hub_appsflyer
--           sat_installs_report_event
--           sat_installs_report_device
-- Range   : 20250101 -> 20250131
-- ============================================================
DROP TEMPORARY TABLE IF EXISTS tmp_installs_report; CREATE TEMPORARY TABLE tmp_installs_report AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(appsflyer_id AS string))), ''), 256) AS appsflyer_hashkey,
    sha2(
        COALESCE(UPPER(TRIM(CAST(install_time                   AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(event_time                     AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(event_name                     AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(event_value                    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(event_revenue                  AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(event_revenue_currency         AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(event_revenue_usd              AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(event_source                   AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(is_receipt_validated           AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(attributed_touch_type          AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(attributed_touch_time          AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(partner                        AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(media_source                   AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(channel                        AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(keywords                       AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(campaign                       AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(campaign_id                    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(adset                          AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(adset_id                       AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(ad                             AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(ad_id                          AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(ad_type                        AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(site_id                        AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(sub_site_id                    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(sub_param_1                    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(sub_param_2                    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(sub_param_3                    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(sub_param_4                    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(sub_param_5                    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(carrier                        AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(cost_model                     AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(cost_value                     AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(cost_currency                  AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(contributor_1_partner          AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(contributor_1_media_source     AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(contributor_1_campaign         AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(contributor_1_touch_type       AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(contributor_1_touch_time       AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(contributor_2_partner          AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(contributor_2_media_source     AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(contributor_2_campaign         AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(contributor_2_touch_type       AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(contributor_2_touch_time       AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(contributor_3_partner          AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(contributor_3_media_source     AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(contributor_3_campaign         AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(contributor_3_touch_type       AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(contributor_3_touch_time       AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(is_retargeting                 AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(retargeting_conversion_type    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(attribution_lookback           AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(reengagement_window            AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(is_primary_attribution         AS string))), ''), 256) AS hd_installs_report_event,
    sha2(
        COALESCE(UPPER(TRIM(CAST(city           AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(wifi           AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(operator       AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(language       AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(advertising_id AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(idfa           AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(android_id     AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(customer_user_id AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(imei           AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(idfv           AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(platform       AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(device_type    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(os_version     AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(app_version    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(sdk_version    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(app_id         AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(app_name       AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(bundle_id      AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(country_code   AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(dma            AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(ip             AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(postal_code    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(region         AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(state          AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(user_agent     AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(http_referrer  AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(original_url   AS string))), ''), 256) AS hd_installs_report_device,
    to_date(data_date, 'yyyyMMdd') AS source_event_date,
    appsflyer_id,
    install_time, event_time, event_name, event_value, event_revenue, event_revenue_currency,
    event_revenue_usd, event_source, is_receipt_validated, attributed_touch_type, attributed_touch_time,
    partner, media_source, channel, keywords, campaign, campaign_id, adset, adset_id, ad, ad_id, ad_type,
    site_id, sub_site_id, sub_param_1, sub_param_2, sub_param_3, sub_param_4, sub_param_5,
    carrier, cost_model, cost_value, cost_currency,
    contributor_1_partner, contributor_1_media_source, contributor_1_campaign, contributor_1_touch_type, contributor_1_touch_time,
    contributor_2_partner, contributor_2_media_source, contributor_2_campaign, contributor_2_touch_type, contributor_2_touch_time,
    contributor_3_partner, contributor_3_media_source, contributor_3_campaign, contributor_3_touch_type, contributor_3_touch_time,
    is_retargeting, retargeting_conversion_type, attribution_lookback, reengagement_window, is_primary_attribution,
    city, wifi, operator, language, advertising_id, idfa, android_id, customer_user_id, imei, idfv,
    platform, device_type, os_version, app_version, sdk_version, app_id, app_name, bundle_id,
    country_code, dma, ip, postal_code, region, state, user_agent, http_referrer, original_url
FROM IDENTIFIER({{catalog_sourcing}} || '.appsflyer.installs_report')
WHERE
    data_date BETWEEN {{start_date}} AND {{end_date}}
  AND appsflyer_id IS NOT NULL;

-- [hub_appsflyer] Consolidated insert from ALL appsflyer sources to avoid Delta version conflicts.
-- Hub da nguon: gom union 8 temp view nguon, dedup, INSERT duoi catalog cleaned.
-- Cac file appsflyer khac chay song song => khong INSERT hub_appsflyer nua (xem comment trong tung file).
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_appsflyer')
(appsflyer_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH all_sources AS (
    SELECT sha2(COALESCE(UPPER(TRIM(CAST(appsflyer_id AS string))), ''), 256) AS appsflyer_hashkey,
           CAST(appsflyer_id AS STRING) AS business_key,
           data_date,
           'appsflyer__installs_report' AS record_source
    FROM IDENTIFIER({{catalog_sourcing}} || '.appsflyer.installs_report')
    WHERE appsflyer_id IS NOT NULL
    UNION
    SELECT sha2(COALESCE(UPPER(TRIM(CAST(appsflyer_id AS string))), ''), 256),
           CAST(appsflyer_id AS STRING), data_date, 'appsflyer__in_app_events_report'
    FROM IDENTIFIER({{catalog_sourcing}} || '.appsflyer.in_app_events_report') WHERE appsflyer_id IS NOT NULL
    UNION
    SELECT sha2(COALESCE(UPPER(TRIM(CAST(appsflyer_id AS string))), ''), 256),
           CAST(appsflyer_id AS STRING), regexp_replace(substr(event_time, 1, 10), '-', '') as data_date, 'appsflyer__organic_installs_report'
    FROM IDENTIFIER({{catalog_sourcing}} || '.appsflyer.organic_installs_report') WHERE appsflyer_id IS NOT NULL
    UNION
    SELECT sha2(COALESCE(UPPER(TRIM(CAST(appsflyer_id AS string))), ''), 256),
           CAST(appsflyer_id AS STRING), regexp_replace(substr(event_time, 1, 10), '-', '') as data_date, 'appsflyer__organic_in_app_events_report'
    FROM IDENTIFIER({{catalog_sourcing}} || '.appsflyer.organic_in_app_events_report') WHERE appsflyer_id IS NOT NULL
    UNION
    SELECT sha2(COALESCE(UPPER(TRIM(CAST(appsflyer_id AS string))), ''), 256),
           CAST(appsflyer_id AS STRING), regexp_replace(substr(event_time, 1, 10), '-', '') as data_date, 'appsflyer__organic_uninstall_events_report'
    FROM IDENTIFIER({{catalog_sourcing}} || '.appsflyer.organic_uninstall_events_report') WHERE appsflyer_id IS NOT NULL
    UNION
    SELECT sha2(COALESCE(UPPER(TRIM(CAST(appsflyer_id AS string))), ''), 256),
           CAST(appsflyer_id AS STRING), data_date, 'appsflyer__reinstalls'
    FROM IDENTIFIER({{catalog_sourcing}} || '.appsflyer.reinstalls') WHERE appsflyer_id IS NOT NULL
    UNION
    SELECT sha2(COALESCE(UPPER(TRIM(CAST(appsflyer_id AS string))), ''), 256),
           CAST(appsflyer_id AS STRING), regexp_replace(substr(event_time, 1, 10), '-', '') as data_date, 'appsflyer__reinstalls_organic'
    FROM IDENTIFIER({{catalog_sourcing}} || '.appsflyer.reinstalls_organic') WHERE appsflyer_id IS NOT NULL
    UNION
    SELECT sha2(COALESCE(UPPER(TRIM(CAST(appsflyer_id AS string))), ''), 256),
           CAST(appsflyer_id AS STRING), regexp_replace(substr(event_time, 1, 10), '-', '') as data_date, 'appsflyer__uninstall_events_report'
    FROM IDENTIFIER({{catalog_sourcing}} || '.appsflyer.uninstall_events_report') WHERE appsflyer_id IS NOT NULL
),
hub_rows AS (
SELECT
    appsflyer_hashkey,
    business_key,
    to_date(data_date, 'yyyyMMdd') AS source_event_date,
    record_source
FROM all_sources
WHERE
    data_date BETWEEN {{start_date}} AND {{end_date}}
),
deduped AS (
    SELECT appsflyer_hashkey, business_key, source_event_date, record_source FROM hub_rows
    QUALIFY ROW_NUMBER() OVER (PARTITION BY appsflyer_hashkey ORDER BY source_event_date) = 1
)
SELECT
    d.appsflyer_hashkey AS appsflyer_hashkey,
    d.business_key AS business_key,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    d.record_source AS record_source
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_appsflyer') t
    ON t.appsflyer_hashkey = d.appsflyer_hashkey;

-- Satellite: installs_report_event
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_installs_report_event')
(appsflyer_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 install_time, event_time, event_name, event_value, event_revenue, event_revenue_currency,
 event_revenue_usd, event_source, is_receipt_validated, attributed_touch_type, attributed_touch_time,
 partner, media_source, channel, keywords, campaign, campaign_id, adset, adset_id, ad, ad_id, ad_type,
 site_id, sub_site_id, sub_param_1, sub_param_2, sub_param_3, sub_param_4, sub_param_5,
 carrier, cost_model, cost_value, cost_currency,
 contributor_1_partner, contributor_1_media_source, contributor_1_campaign, contributor_1_touch_type, contributor_1_touch_time,
 contributor_2_partner, contributor_2_media_source, contributor_2_campaign, contributor_2_touch_type, contributor_2_touch_time,
 contributor_3_partner, contributor_3_media_source, contributor_3_campaign, contributor_3_touch_type, contributor_3_touch_time,
 is_retargeting, retargeting_conversion_type, attribution_lookback, reengagement_window, is_primary_attribution)
WITH deduped AS (
    SELECT * FROM tmp_installs_report
    QUALIFY ROW_NUMBER() OVER (PARTITION BY appsflyer_hashkey, hd_installs_report_event, source_event_date ORDER BY source_event_date) = 1
)
SELECT
    d.appsflyer_hashkey AS appsflyer_hashkey,
    d.hd_installs_report_event AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'appsflyer__installs_report' AS record_source,
    d.install_time AS install_time,
    d.event_time AS event_time,
    d.event_name AS event_name,
    d.event_value AS event_value,
    d.event_revenue AS event_revenue,
    d.event_revenue_currency AS event_revenue_currency,
    d.event_revenue_usd AS event_revenue_usd,
    d.event_source AS event_source,
    d.is_receipt_validated AS is_receipt_validated,
    d.attributed_touch_type AS attributed_touch_type,
    d.attributed_touch_time AS attributed_touch_time,
    d.partner AS partner,
    d.media_source AS media_source,
    d.channel AS channel,
    d.keywords AS keywords,
    d.campaign AS campaign,
    d.campaign_id AS campaign_id,
    d.adset AS adset,
    d.adset_id AS adset_id,
    d.ad AS ad,
    d.ad_id AS ad_id,
    d.ad_type AS ad_type,
    d.site_id AS site_id,
    d.sub_site_id AS sub_site_id,
    d.sub_param_1 AS sub_param_1,
    d.sub_param_2 AS sub_param_2,
    d.sub_param_3 AS sub_param_3,
    d.sub_param_4 AS sub_param_4,
    d.sub_param_5 AS sub_param_5,
    d.carrier AS carrier,
    d.cost_model AS cost_model,
    d.cost_value AS cost_value,
    d.cost_currency AS cost_currency,
    d.contributor_1_partner AS contributor_1_partner,
    d.contributor_1_media_source AS contributor_1_media_source,
    d.contributor_1_campaign AS contributor_1_campaign,
    d.contributor_1_touch_type AS contributor_1_touch_type,
    d.contributor_1_touch_time AS contributor_1_touch_time,
    d.contributor_2_partner AS contributor_2_partner,
    d.contributor_2_media_source AS contributor_2_media_source,
    d.contributor_2_campaign AS contributor_2_campaign,
    d.contributor_2_touch_type AS contributor_2_touch_type,
    d.contributor_2_touch_time AS contributor_2_touch_time,
    d.contributor_3_partner AS contributor_3_partner,
    d.contributor_3_media_source AS contributor_3_media_source,
    d.contributor_3_campaign AS contributor_3_campaign,
    d.contributor_3_touch_type AS contributor_3_touch_type,
    d.contributor_3_touch_time AS contributor_3_touch_time,
    d.is_retargeting AS is_retargeting,
    d.retargeting_conversion_type AS retargeting_conversion_type,
    d.attribution_lookback AS attribution_lookback,
    d.reengagement_window AS reengagement_window,
    d.is_primary_attribution AS is_primary_attribution
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_installs_report_event') t
    ON t.appsflyer_hashkey = d.appsflyer_hashkey AND t.hashdiff = d.hd_installs_report_event
   AND t.source_event_date = d.source_event_date;

-- Satellite: installs_report_device
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_installs_report_device')
(appsflyer_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 city, wifi, operator, language, advertising_id, idfa, android_id, customer_user_id, imei, idfv,
 platform, device_type, os_version, app_version, sdk_version, app_id, app_name, bundle_id,
 country_code, dma, ip, postal_code, region, state, user_agent, http_referrer, original_url)
WITH deduped AS (
    SELECT * FROM tmp_installs_report
    QUALIFY ROW_NUMBER() OVER (PARTITION BY appsflyer_hashkey, hd_installs_report_device, source_event_date ORDER BY source_event_date) = 1
)
SELECT
    d.appsflyer_hashkey AS appsflyer_hashkey,
    d.hd_installs_report_device AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'appsflyer__installs_report' AS record_source,
    d.city AS city,
    d.wifi AS wifi,
    d.operator AS operator,
    d.language AS language,
    d.advertising_id AS advertising_id,
    d.idfa AS idfa,
    d.android_id AS android_id,
    d.customer_user_id AS customer_user_id,
    d.imei AS imei,
    d.idfv AS idfv,
    d.platform AS platform,
    d.device_type AS device_type,
    d.os_version AS os_version,
    d.app_version AS app_version,
    d.sdk_version AS sdk_version,
    d.app_id AS app_id,
    d.app_name AS app_name,
    d.bundle_id AS bundle_id,
    d.country_code AS country_code,
    d.dma AS dma,
    d.ip AS ip,
    d.postal_code AS postal_code,
    d.region AS region,
    d.state AS state,
    d.user_agent AS user_agent,
    d.http_referrer AS http_referrer,
    d.original_url AS original_url
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_installs_report_device') t
    ON t.appsflyer_hashkey = d.appsflyer_hashkey AND t.hashdiff = d.hd_installs_report_device
   AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_installs_report;
