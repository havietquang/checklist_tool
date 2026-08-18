-- ============================================================================
-- BO QUERY KIEM CHUNG GOP Y CUA OCB (anh Long / chi Ha)
--   1) Bang transaction: 1 hashkey co dung 1 dong trong 1 ngay khong?
--      -> neu dung, max_by la thua, bo di ket qua KHONG doi.
--   2) sat_crb_balance (multiactive): 1 hashkey nhieu dong theo ma_key
--      -> GROUP BY thieu ma_key la MAT SO DU, phai them ma_key va SUM cot tien.
--
-- CACH DUNG: thay 2 cho sau roi chay tung query
--   <CAT>  = ocb_datavault_dev_cleaned   (hoac _pilot / _prod)
--   <DT>   = ngay du lieu can kiem, dang yyyyMMdd, vd 20260813
-- ============================================================================


-- ############################################################################
-- PHAN 1 - BANG TRANSACTION THUONG: max_by co thua khong?
-- ############################################################################

-- Q1.1  Dem so dong tren moi hashkey trong DUNG 1 ngay.
--       KY VONG: so_dong_max = 1  -> max_by khong chon gi -> thua.
--       Neu so_dong_max > 1 thi max_by DANG co tac dung, BAO LAI truoc khi bo.
SELECT
    COUNT(*)                                   AS tong_dong,
    COUNT(DISTINCT funds_transfer_hashkey)     AS so_hashkey,
    MAX(so_dong)                               AS so_dong_max_tren_1_hashkey,
    SUM(CASE WHEN so_dong > 1 THEN 1 ELSE 0 END) AS so_hashkey_bi_trung
FROM (
    SELECT funds_transfer_hashkey, COUNT(*) AS so_dong
    FROM   <CAT>.raw_vault.sat_funds_transfer_system
    WHERE  source_event_date = TO_DATE('<DT>', 'yyyyMMdd')
    GROUP BY funds_transfer_hashkey
);


-- Q1.2  Chay 1 lan cho NHIEU bang, ra bang tong hop de doc nhanh.
--       Cot 'loai' phan biet 2 nhom - doc ket qua theo dung nhom:
--         SAT THUONG    : ky vong so_dong_max = 1 -> bo max_by duoc.
--         MULTIACTIVE   : ky vong so_dong_max > 1 (nhieu ma_key) -> KHONG duoc bo max_by,
--                         va GROUP BY BAT BUOC phai co ma_key.
SELECT 'sat_funds_transfer_system' AS bang, 'SAT THUONG' AS loai, * FROM (
    SELECT COUNT(*) AS so_hashkey, MAX(n) AS so_dong_max,
           CASE WHEN MAX(n) > 1 THEN 'CAN KIEM TRA' ELSE 'max_by thua -> bo duoc' END AS ket_luan
    FROM (SELECT funds_transfer_hashkey, COUNT(*) n
          FROM <CAT>.raw_vault.sat_funds_transfer_system
          WHERE source_event_date = TO_DATE('<DT>','yyyyMMdd')
          GROUP BY funds_transfer_hashkey))
UNION ALL
SELECT 'sat_stmt_entry_information', 'SAT THUONG', * FROM (
    SELECT COUNT(*), MAX(n), CASE WHEN MAX(n) > 1 THEN 'CAN KIEM TRA' ELSE 'max_by thua -> bo duoc' END
    FROM (SELECT stmt_entry_hashkey, COUNT(*) n
          FROM <CAT>.raw_vault.sat_stmt_entry_information
          WHERE source_event_date = TO_DATE('<DT>','yyyyMMdd')
          GROUP BY stmt_entry_hashkey))
UNION ALL
SELECT 'sat_giaodich_sla', 'SAT THUONG', * FROM (
    SELECT COUNT(*), MAX(n), CASE WHEN MAX(n) > 1 THEN 'CAN KIEM TRA' ELSE 'max_by thua -> bo duoc' END
    FROM (SELECT giao_dich_hashkey, COUNT(*) n
          FROM <CAT>.raw_vault.sat_giaodich_sla
          WHERE source_event_date = TO_DATE('<DT>','yyyyMMdd')
          GROUP BY giao_dich_hashkey))
UNION ALL
SELECT 'sat_categ_entry_information', 'SAT THUONG', * FROM (
    SELECT COUNT(*), MAX(n), CASE WHEN MAX(n) > 1 THEN 'CAN KIEM TRA' ELSE 'max_by thua -> bo duoc' END
    FROM (SELECT categ_entry_hashkey, COUNT(*) n
          FROM <CAT>.raw_vault.sat_categ_entry_information
          WHERE source_event_date = TO_DATE('<DT>','yyyyMMdd')
          GROUP BY categ_entry_hashkey))
UNION ALL
SELECT 'sat_lich_su_giao_dich', 'MULTIACTIVE', * FROM (
    SELECT COUNT(*), MAX(n), CASE WHEN MAX(n) > 1 THEN 'phai GROUP BY kem ma_key' ELSE 'kiem lai' END
    FROM (SELECT giao_dich_hashkey, COUNT(*) n
          FROM <CAT>.raw_vault.sat_lich_su_giao_dich
          WHERE source_event_date = TO_DATE('<DT>','yyyyMMdd')
          GROUP BY giao_dich_hashkey))
UNION ALL
SELECT 'sat_h_pdtd_gdich_ctiet_pduyet', 'MULTIACTIVE', * FROM (
    SELECT COUNT(*), MAX(n), CASE WHEN MAX(n) > 1 THEN 'phai GROUP BY kem ma_key' ELSE 'kiem lai' END
    FROM (SELECT pdtd_nhom_giao_dich_hashkey, COUNT(*) n
          FROM <CAT>.raw_vault.sat_h_pdtd_gdich_ctiet_pduyet
          WHERE source_event_date = TO_DATE('<DT>','yyyyMMdd')
          GROUP BY pdtd_nhom_giao_dich_hashkey))
UNION ALL
SELECT 'sat_crb_balance', 'MULTIACTIVE', * FROM (
    SELECT COUNT(*), MAX(n), CASE WHEN MAX(n) > 1 THEN 'phai GROUP BY kem ma_key' ELSE 'kiem lai' END
    FROM (SELECT crb_hashkey, COUNT(*) n
          FROM <CAT>.raw_vault.sat_crb_balance
          WHERE source_event_date = TO_DATE('<DT>','yyyyMMdd')
          GROUP BY crb_hashkey))
ORDER BY 2, 1;


-- Q1.3  Bang chung TRUC TIEP: ban co max_by va ban KHONG max_by ra ket qua giong het.
--       KY VONG: ca 2 dong deu = 0. Neu > 0 la co lech, KHONG duoc bo max_by.
WITH co_maxby AS (
    SELECT funds_transfer_hashkey,
           max_by(t_user_input, source_event_date) AS t_user_input,
           max_by(t_inputter,   source_event_date) AS t_inputter,
           max_by(t_user_auth,  source_event_date) AS t_user_auth,
           max_by(t_authoriser, source_event_date) AS t_authoriser
    FROM   <CAT>.raw_vault.sat_funds_transfer_system
    WHERE  source_event_date = TO_DATE('<DT>','yyyyMMdd')
    GROUP BY funds_transfer_hashkey
),
khong_maxby AS (
    SELECT funds_transfer_hashkey, t_user_input, t_inputter, t_user_auth, t_authoriser
    FROM   <CAT>.raw_vault.sat_funds_transfer_system
    WHERE  source_event_date = TO_DATE('<DT>','yyyyMMdd')
)
SELECT 'co_maxby TRU khong_maxby' AS chieu_so_sanh, COUNT(*) AS so_dong_lech
FROM   (SELECT * FROM co_maxby EXCEPT SELECT * FROM khong_maxby)
UNION ALL
SELECT 'khong_maxby TRU co_maxby', COUNT(*)
FROM   (SELECT * FROM khong_maxby EXCEPT SELECT * FROM co_maxby);


-- ############################################################################
-- PHAN 2 - sat_crb_balance: vi sao PHAI co ma_key va PHAI sum
-- ############################################################################

-- Q2.1  Chung minh 1 crb_hashkey co NHIEU dong trong cung 1 ngay (theo ma_key).
--       KY VONG: so_dong_max > 1 va so_ma_key_max > 1.
SELECT
    COUNT(*)                                     AS so_crb_hashkey,
    MAX(so_dong)                                 AS so_dong_max,
    MAX(so_ma_key)                               AS so_ma_key_max,
    SUM(CASE WHEN so_dong > 1 THEN 1 ELSE 0 END) AS so_hashkey_nhieu_dong
FROM (
    SELECT crb_hashkey, COUNT(*) AS so_dong, COUNT(DISTINCT ma_key) AS so_ma_key
    FROM   <CAT>.raw_vault.sat_crb_balance
    WHERE  source_event_date = TO_DATE('<DT>','yyyyMMdd')
    GROUP BY crb_hashkey
);


-- Q2.2  Xem tan mat 1 hashkey bi anh huong nang nhat: no co bao nhieu dong, moi dong bao nhieu tien.
--       Doc de thay ro "GROUP BY thieu ma_key" dang vut di nhung dong nao.
WITH nang_nhat AS (
    SELECT crb_hashkey
    FROM   <CAT>.raw_vault.sat_crb_balance
    WHERE  source_event_date = TO_DATE('<DT>','yyyyMMdd')
    GROUP BY crb_hashkey
    ORDER BY COUNT(*) DESC
    LIMIT 1
)
SELECT s.crb_hashkey, s.ma_key, s.ngoaite, s.ngoaite1, s.noite, s.category, s.hashdiff
FROM   <CAT>.raw_vault.sat_crb_balance s
JOIN   nang_nhat n ON n.crb_hashkey = s.crb_hashkey
WHERE  s.source_event_date = TO_DATE('<DT>','yyyyMMdd')
ORDER BY s.ma_key;


-- Q2.3  DO CHENH LECH TIEN giua 3 cach viet. Day la con so de bao cao.
--       cach_A = code hien tai (GROUP BY thieu ma_key, dung max_by)  -> nghi ngo THIEU tien
--       cach_B = them ma_key vao GROUP BY, van max_by
--       cach_C = them ma_key + SUM cot tien  (OCB de xuat)
WITH cach_A AS (
    SELECT SUM(CAST(ngoaite  AS DECIMAL(31,4))) AS tong_ngoaite,
           SUM(CAST(ngoaite1 AS DECIMAL(31,4))) AS tong_ngoaite1
    FROM ( SELECT crb_hashkey,
                  max_by(ngoaite,  source_event_date) AS ngoaite,
                  max_by(ngoaite1, source_event_date) AS ngoaite1
           FROM   <CAT>.raw_vault.sat_crb_balance
           WHERE  source_event_date = TO_DATE('<DT>','yyyyMMdd')
           GROUP BY crb_hashkey )
),
cach_B AS (
    SELECT SUM(CAST(ngoaite  AS DECIMAL(31,4))) AS tong_ngoaite,
           SUM(CAST(ngoaite1 AS DECIMAL(31,4))) AS tong_ngoaite1
    FROM ( SELECT crb_hashkey, ma_key,
                  max_by(ngoaite,  source_event_date) AS ngoaite,
                  max_by(ngoaite1, source_event_date) AS ngoaite1
           FROM   <CAT>.raw_vault.sat_crb_balance
           WHERE  source_event_date = TO_DATE('<DT>','yyyyMMdd')
           GROUP BY crb_hashkey, ma_key )
),
cach_C AS (
    SELECT SUM(CAST(ngoaite  AS DECIMAL(31,4))) AS tong_ngoaite,
           SUM(CAST(ngoaite1 AS DECIMAL(31,4))) AS tong_ngoaite1
    FROM ( SELECT crb_hashkey, ma_key,
                  SUM(CAST(ngoaite  AS DECIMAL(31,4))) AS ngoaite,
                  SUM(CAST(ngoaite1 AS DECIMAL(31,4))) AS ngoaite1
           FROM   <CAT>.raw_vault.sat_crb_balance
           WHERE  source_event_date = TO_DATE('<DT>','yyyyMMdd')
           GROUP BY crb_hashkey, ma_key )
)
SELECT 'A. code hien tai - thieu ma_key, max_by' AS cach_viet, * FROM cach_A
UNION ALL SELECT 'B. them ma_key, van max_by',              * FROM cach_B
UNION ALL SELECT 'C. them ma_key + SUM (OCB de xuat)',      * FROM cach_C;


-- Q2.4  Kiem chung y "co the xuat hien 2 dong giong nhau hoan toan".
--       Neu ra dong nao -> dung la co ban ghi trung het moi cot -> phai SUM moi khong mat tien.
--       Neu KHONG ra dong nao -> hoi lai OCB y "2 dong giong nhau" la giong o muc nao.
SELECT crb_hashkey, ma_key, ngoaite, ngoaite1, noite, category, COUNT(*) AS so_dong_trung
FROM   <CAT>.raw_vault.sat_crb_balance
WHERE  source_event_date = TO_DATE('<DT>','yyyyMMdd')
GROUP BY crb_hashkey, ma_key, ngoaite, ngoaite1, noite, category
HAVING COUNT(*) > 1
ORDER BY so_dong_trung DESC
LIMIT 50;


-- ############################################################################
-- PHAN 3 - PIT: join hub_active co thua that khong
-- ############################################################################

-- Q3.1  So so dong truoc/sau khi join cust_active.
--       KY VONG: 2 so BANG NHAU -> join la thua, bo di khong doi ket qua.
SELECT
    (SELECT COUNT(*)
     FROM   <CAT>.business_vault.pit_customer
     WHERE  snapshot_date = TO_DATE('<DT>','yyyyMMdd'))                       AS chi_pit,
    (SELECT COUNT(*)
     FROM   <CAT>.business_vault.pit_customer p
     JOIN ( SELECT h.customer_hashkey
            FROM   <CAT>.raw_vault.hub_customer h
            LEFT JOIN ( SELECT customer_hashkey
                        FROM   <CAT>.raw_vault.sts_hub_customer
                        WHERE  source_event_date <= TO_DATE('<DT>','yyyyMMdd')
                        GROUP BY customer_hashkey
                        HAVING max_by(cdc_status, source_event_date) = 'D' ) d
                   ON d.customer_hashkey = h.customer_hashkey
            WHERE  d.customer_hashkey IS NULL
              AND  h.source_event_date <= TO_DATE('<DT>','yyyyMMdd')
            GROUP BY h.customer_hashkey ) a
       ON a.customer_hashkey = p.customer_hashkey
     WHERE  p.snapshot_date = TO_DATE('<DT>','yyyyMMdd'))                     AS pit_join_active;


-- Q3.2  Liet ke hashkey co trong PIT nhung KHONG con active (neu co dong nao thi join
--       KHONG thua - phai bao lai OCB).
SELECT p.customer_hashkey
FROM   <CAT>.business_vault.pit_customer p
LEFT JOIN ( SELECT h.customer_hashkey
            FROM   <CAT>.raw_vault.hub_customer h
            LEFT JOIN ( SELECT customer_hashkey
                        FROM   <CAT>.raw_vault.sts_hub_customer
                        WHERE  source_event_date <= TO_DATE('<DT>','yyyyMMdd')
                        GROUP BY customer_hashkey
                        HAVING max_by(cdc_status, source_event_date) = 'D' ) d
                   ON d.customer_hashkey = h.customer_hashkey
            WHERE  d.customer_hashkey IS NULL
              AND  h.source_event_date <= TO_DATE('<DT>','yyyyMMdd')
            GROUP BY h.customer_hashkey ) a
       ON a.customer_hashkey = p.customer_hashkey
WHERE  p.snapshot_date = TO_DATE('<DT>','yyyyMMdd')
  AND  a.customer_hashkey IS NULL
LIMIT 50;
