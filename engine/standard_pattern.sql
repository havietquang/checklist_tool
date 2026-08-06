-- =============================================================================
-- PATTERN CHUAN doc Silver (Data Vault 2.0) len Gold - ZONE C OCB
-- Nguon: OCB_DBX_ZONEC - Technical_Document_v1.1, muc III.4.2
--        "Quy tac khi xu li cac bang tu Silver"
-- Day la goc cham cac tieu chi 2.1 / 2.2 / 2.3 / 2.4 / 3.5 / X.1 / X.6.
-- =============================================================================

-- [III.4.2.1] STS HUB - lay danh sach khoa Hub DANG CO HIEU LUC
-- Trang thai xoa duoc loc O DAY, khong loc trong satellite.
{{ent}}_sts_del AS (
    SELECT {{hk}}
    FROM IDENTIFIER(:cleaned || '.raw_vault.sts_hub_{{ent}}')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY {{hk}}
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
{{ent}}_active AS (
    SELECT h.{{hk}}, h.business_key, h.source_event_date
    FROM IDENTIFIER(:cleaned || '.raw_vault.hub_{{ent}}') h
    LEFT JOIN {{ent}}_sts_del d ON d.{{hk}} = h.{{hk}}
    WHERE h.source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
      AND d.{{hk}} IS NULL
)

-- [III.4.2.2] SATELLITE - lam giau thuoc tinh, ban ghi moi nhat den ngay xu ly
-- Single-active:
, {{ent}}_sat AS (
    SELECT {{hk}},
           max_by(<col_1>, source_event_date) AS <col_1>,
           max_by(<col_2>, source_event_date) AS <col_2>
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_{{sat_name}}')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY {{hk}}
)
-- Multi-active (nhieu dong hop le cung luc: nhieu SDT/dia chi) -> THEM sub-key:
, {{ent}}_sat_ma AS (
    SELECT {{hk}}, {{subseq_key}},
           max_by(<col_1>, source_event_date) AS <col_1>
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_{{sat_name}}')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY {{hk}}, {{subseq_key}}
)

-- [III.4.2.3] LINK - rut ve quan he HIEN HANH truoc khi join vao fact/dim
-- Quan he 1:N -> partition theo driving key (ben chi duoc co 1 doi tac tai 1 thoi diem):
, {{link}}_cur AS (
    SELECT {{driving_hk}},
           max_by({{target_hk}}, source_event_date) AS {{target_hk}}
    FROM IDENTIFIER(:cleaned || '.raw_vault.link_{{link}}')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY {{driving_hk}}
)
-- Quan he M:N -> KHONG partition theo mot phia, khu trung o muc cap (link_hashkey):
, {{link}}_cur_mn AS (
    SELECT {{link_hk}},
           max_by({{hk1}}, source_event_date) AS {{hk1}},
           max_by({{hk2}}, source_event_date) AS {{hk2}}
    FROM IDENTIFIER(:cleaned || '.raw_vault.link_{{link}}')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY {{link_hk}}
)

-- [III.4.2.5] EFFSAT LINK - chi giu quan he con hieu luc (active_flag = 1)
, {{link}}_active AS (
    SELECT l.<hk_1>, l.<hk_2>
    FROM IDENTIFIER(:cleaned || '.raw_vault.link_{{link}}') l
    JOIN (
        SELECT link_{{link}}_hashkey
        FROM IDENTIFIER(:cleaned || '.raw_vault.effsat_link_{{link}}')
        WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
        GROUP BY link_{{link}}_hashkey
        HAVING max_by(active_flag, source_event_date) = 1
    ) e ON e.link_{{link}}_hashkey = l.link_{{link}}_hashkey
)

-- [III.4.2.4] PIT - snapshot point-in-time; source_event_date DUOC PHEP nam trong ON
-- vi la equi-join voi cot *_src_ev_dt cua PIT.
SELECT ...
FROM IDENTIFIER(:cleaned || '.business_vault.pit_{{ent}}') p
LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.sat_{{sat_1}}') s1
       ON s1.{{hk}} = p.{{hk}}
      AND s1.source_event_date = p.{{sat_1}}_src_ev_dt
LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.sat_{{sat_2}}') s2
       ON s2.{{hk}} = p.{{hk}}
      AND s2.source_event_date = p.{{sat_2}}_src_ev_dt
WHERE p.snapshot_date = TO_DATE(:DATADT, 'yyyyMMdd');
-- pit_loan / pit_customer: LEFT JOIN thang PIT voi sat la du.
-- pit_account / pit_acnt_contract: VAN phai join sts_hub de loc ban ghi co hieu luc.

-- [LDP] SCD TYPE 2 cho bang DIM - dung APPLY CHANGES, khong tu sinh surrogate key
-- CREATE OR REFRESH STREAMING TABLE {{alias}}_scd;
-- APPLY CHANGES INTO {{alias}}_scd
--   FROM STREAM(stg_{{ent}}_changes)
--   KEYS ({{hk}})
--   SEQUENCE BY source_event_date
--   STORED AS SCD TYPE 2
--   TRACK HISTORY ON (<col_1>, <col_2>);

-- =============================================================================
-- QUY TAC BAT BUOC (rut tu muc "Nguyen tac" cua tai lieu)
--   1. CHI chan tren source_event_date <= :DATADT. KHONG dat can duoi (>= start_date)
--      -> can duoi lam bo sot ban ghi trang thai moi nhat nam truoc khoang thoi gian.
--   2. Rieng 49 bang transaction (muc "Cac truong hop dac biet", xem doc_standard.py)
--      PHAI loc source_event_date = :DATADT.
--   3. Satellite luon LEFT JOIN. INNER JOIN lam mat ban ghi Hub dang song ma chua co
--      dong satellite.
--   4. KHONG loc cdc_status trong satellite - da loc o sts_hub. Chi xu ly rieng khi
--      satellite mang ngu nghia delete rieng, va phai co chu dich.
--   5. Multi-active satellite phai GROUP BY {{hk}}, {{subseq_key}}. Chi GROUP BY hashkey
--      se gom nham con 1 dong va mat cac dong khac.
--   6. Chon dung driving key cho link 1:N. Chon sai -> lay nham quan he hoac nhan ban dong.
--   7. Tiebreaker khi trung source_event_date theo driving key:
--      ORDER BY source_event_date DESC, <load_dts> DESC.
--   8. Chi SELECT hashkey va dung cac cot thuoc tinh can dung.
--   9. Dung IDENTIFIER(:cleaned || '...') hoac ${cleaned_catalog}/${curated_catalog},
--      khong hard-code ten catalog.
--
-- KHONG DUOC LAM:
--   ROW_NUMBER() OVER (...) + WHERE/QUALIFY rn = 1        -> dung max_by (Issue log #5)
--   LEFT JOIN ... ON a.rn = 1 / ON a.cdc_status <> 'D'    -> 2.3 SAI (Issue log #3)
--   MAX(DIM_ID) + ROW_NUMBER() sinh surrogate key         -> 2.6 SAI (Issue log #4)
--   Join link_* truc tiep khi chua rut ve current         -> X.1 nhan doi so dong
--   Doc cung 1 sat o 2 cho khac nhau trong 1 script       -> 2.12 SAI
-- =============================================================================
