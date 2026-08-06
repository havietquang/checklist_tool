-- Source: bpm.ttd_giao_dich_igen | Target: sat_giao_dich_ttd_igen
-- Full load init | Date col: null
DROP TEMPORARY TABLE IF EXISTS tmp_ttd_giao_dich_igen; CREATE TEMPORARY TABLE tmp_ttd_giao_dich_igen AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(refnewfo                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(khach_hang_id                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tenkhachhang                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cif                           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngaysinh                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gioitinh                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sogiaytotuythan               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngaycap                       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(noicap                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sodienthoai                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(email                         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(quoctich                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hokhauthuongtru               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(noiohientai                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(xhtd                          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nhomcskhomni                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hanmucdexuat                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hanmucpheduyet                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tenintrenthe                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(chiphisinhhoat                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(chiphitranotctdkhac           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tinhtrangnghenghiep           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(chucvu                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ascore                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bscore                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loaithechitietdexuat          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loaithedexuat                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nghiepvuchitiet               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(doituongkh                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nhomcskhchung                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nhomcskhchitiet               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(user_tao                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hinhthucbaodam                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tinhtranghonnhan              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngaykhdexuat                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngaypheduyetyeccaumothe       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(giatritsbd                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trangthaithe                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(matsbd                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngaybatdauhm                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngayketthuchm                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(mahm                          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hmthe                         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(donvitiente                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sothe                         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sanphamthe                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngoithamdinh                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(donvipht                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loaithew4                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tenkhachhangdoitac            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gtttdoitac                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sdtdoitac                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thunhapchiuthuedoitac         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loaikhomni                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gtttcu                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(banghoitin                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hinhanh                       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hanmuckhhh                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hm_thethamchieu               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dunobinhquan_6t               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tyleduno_thoidiemxetcap       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(solantongduno                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tong_hm_the                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_chi_nhanh                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(source                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tong_thu_nhap                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loaithepheduyet               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loaithechitietpheduyet        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ketquaaml                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thethamchieu                  AS string))), ''), 256) AS hd_giao_dich_ttd_igen,
    to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
    gd_id, refnewfo, khach_hang_id, tenkhachhang, cif, ngaysinh, gioitinh, sogiaytotuythan,
    ngaycap, noicap, sodienthoai, email, quoctich, hokhauthuongtru, noiohientai, xhtd,
    nhomcskhomni, hanmucdexuat, hanmucpheduyet, tenintrenthe, chiphisinhhoat,
    chiphitranotctdkhac, tinhtrangnghenghiep, chucvu, ascore, bscore, loaithechitietdexuat,
    loaithedexuat, nghiepvuchitiet, doituongkh, nhomcskhchung, nhomcskhchitiet, ngay_tao,
    user_tao, trang_thai, hinhthucbaodam, tinhtranghonnhan, ngaykhdexuat, ngaypheduyetyeccaumothe,
    giatritsbd, trangthaithe, matsbd, ngaybatdauhm, ngayketthuchm, mahm, hmthe, donvitiente,
    sothe, sanphamthe, ngoithamdinh, donvipht, loaithew4, tenkhachhangdoitac, gtttdoitac,
    sdtdoitac, thunhapchiuthuedoitac, loaikhomni, gtttcu, banghoitin, hinhanh, hanmuckhhh,
    hm_thethamchieu, dunobinhquan_6t, tyleduno_thoidiemxetcap, solantongduno, tong_hm_the,
    ma_chi_nhanh, source, tong_thu_nhap, loaithepheduyet, loaithechitietpheduyet, ketquaaml, thethamchieu
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.ttd_giao_dich_igen')
WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_ttd_igen')
(
 giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source, refnewfo,
 khach_hang_id, tenkhachhang, cif, ngaysinh, gioitinh, sogiaytotuythan, ngaycap, noicap,
 sodienthoai, email, quoctich, hokhauthuongtru, noiohientai, xhtd, nhomcskhomni, hanmucdexuat,
 hanmucpheduyet, tenintrenthe, chiphisinhhoat, chiphitranotctdkhac, tinhtrangnghenghiep, chucvu,
 ascore, bscore, loaithechitietdexuat, loaithedexuat, nghiepvuchitiet, doituongkh, nhomcskhchung,
 nhomcskhchitiet, ngay_tao, user_tao, trang_thai, hinhthucbaodam, tinhtranghonnhan, giatritsbd,
 trangthaithe, matsbd, mahm, hmthe, donvitiente, sothe, sanphamthe, ngoithamdinh, donvipht,
 loaithew4, tenkhachhangdoitac, gtttdoitac, sdtdoitac, thunhapchiuthuedoitac, loaikhomni, gtttcu,
 hanmuckhhh, hm_thethamchieu, dunobinhquan_6t, tyleduno_thoidiemxetcap, solantongduno,
 tong_hm_the, ma_chi_nhanh, ngaykhdexuat, ngaypheduyetyeccaumothe, ngaybatdauhm, ngayketthuchm,
 banghoitin, hinhanh, source, tong_thu_nhap, loaithepheduyet, loaithechitietpheduyet, ketquaaml,
 thethamchieu
)
WITH deduped AS (SELECT * FROM tmp_ttd_giao_dich_igen QUALIFY ROW_NUMBER() OVER (PARTITION BY giao_dich_hashkey, hd_giao_dich_ttd_igen ORDER BY 1) = 1)
SELECT d.giao_dich_hashkey, d.hd_giao_dich_ttd_igen, d.source_event_date, current_timestamp(),
       'bpm__ttd_giao_dich_igen', d.refnewfo, d.khach_hang_id, d.tenkhachhang, d.cif, d.ngaysinh,
       d.gioitinh, d.sogiaytotuythan, d.ngaycap, d.noicap, d.sodienthoai, d.email, d.quoctich,
       d.hokhauthuongtru, d.noiohientai, d.xhtd, d.nhomcskhomni, d.hanmucdexuat, d.hanmucpheduyet,
       d.tenintrenthe, d.chiphisinhhoat, d.chiphitranotctdkhac, d.tinhtrangnghenghiep, d.chucvu,
       d.ascore, d.bscore, d.loaithechitietdexuat, d.loaithedexuat, d.nghiepvuchitiet,
       d.doituongkh, d.nhomcskhchung, d.nhomcskhchitiet, d.ngay_tao, d.user_tao, d.trang_thai,
       d.hinhthucbaodam, d.tinhtranghonnhan, d.giatritsbd, d.trangthaithe, d.matsbd, d.mahm,
       d.hmthe, d.donvitiente, d.sothe, d.sanphamthe, d.ngoithamdinh, d.donvipht, d.loaithew4,
       d.tenkhachhangdoitac, d.gtttdoitac, d.sdtdoitac, d.thunhapchiuthuedoitac, d.loaikhomni,
       d.gtttcu, d.hanmuckhhh, d.hm_thethamchieu, d.dunobinhquan_6t, d.tyleduno_thoidiemxetcap,
       d.solantongduno, d.tong_hm_the, d.ma_chi_nhanh, d.ngaykhdexuat, d.ngaypheduyetyeccaumothe,
       d.ngaybatdauhm, d.ngayketthuchm, d.banghoitin, d.hinhanh, d.source, d.tong_thu_nhap,
       d.loaithepheduyet, d.loaithechitietpheduyet, d.ketquaaml, d.thethamchieu
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_ttd_igen') t
    ON t.giao_dich_hashkey = d.giao_dich_hashkey AND t.hashdiff = d.hd_giao_dich_ttd_igen;

DROP TEMPORARY TABLE IF EXISTS tmp_ttd_giao_dich_igen;
