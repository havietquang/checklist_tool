# Backfill Satellites — T24 Big Tables

**Mục đích:** Load dữ liệu lịch sử vào 10 satellite tables trong `ocb_datavault_dev_cleaned.raw_vault`
**Range:** `20230209` -> `20260602` (3.3 nam)
**Platform:** Databricks SQL Warehouse Serverless — 8 vCPU / 61 GB RAM moi cluster
**Nguon:** `ocb_datavault_dev_sourcing.t24`

---

## Cau truc thu muc

```
backfill_satellites/
├── 1__pre_run_capture_versions.sql
├── 2a__categ_20230209_20260602.sql
├── 2b__reconsol_20230209_20260602.sql
├── 2c__linemvmt_20230209_20260602.sql
├── 2d_option1_seq__stmt/
│   ├── s1_20230209_20231231.sql
│   ├── s2_20240101_20241231.sql
│   └── s3_20250101_20260602.sql
├── 2d_option2_parallel_stmt/
│   ├── s1_20230209_20231231.sql
│   ├── s2_20240101_20241231.sql
│   ├── s3_20250101_20260602.sql
│   └── dedup_after_parallel.sql
├── 4__rollback_to_captured_versions.sql
└── README.md
```

---

## Thu tu thuc hien

```
Buoc 1  1__pre_run_capture_versions.sql     Lay Delta version hien tai, dien vao rollback script
Buoc 2  2a / 2b / 2c                        Chay song song (3 cluster)
        + chon 1 trong 2 option cho stmt:
        Option 1  2d_option1_seq__stmt/     Chay tuan tu s1 -> s2 -> s3
        Option 2  2d_option2_parallel_stmt/ Chay dong thoi s1 + s2 + s3
Buoc 3  dedup_after_parallel.sql            Chi can neu chon Option 2
Rollback  4__rollback_to_captured_versions.sql
```

---

## Giai thich thuat ngu

**Spill (disk spill):** Xay ra khi du lieu dang xu ly vuot qua RAM cua cluster. Photon se ghi tam phan du lieu xuong local SSD de tiep tuc xu ly thay vi bao loi. Ket qua la query van chay duoc nhung cham hon do phai doc/ghi SSD. Muc do anh huong phu thuoc vao luong spill: spill nho (< 30 GB) thay doi thoi gian khong dang ke, spill lon (> 100 GB) co the lam cham gap 2-4 lan so voi chay hoan toan trong RAM.

**In-memory expansion:** Du lieu tren disk o dinh dang Parquet (nen). Khi Photon doc vao bo nho, no giai nen sang dinh dang columnar de tinh toan — thuong lon gap ~2.5 lan so voi kich co tren disk.

---

## Dung luong thuc te 4 bang nguon

Gia tri duoi day do truc tiep tu DESCRIBE DETAIL tren cum du lieu thuc te.

| Source table | 1 nam (thuc te) | 1.5 nam (thuc te) | Full 3.3 nam (uoc tinh) |
|---|---|---|---|
| t24_categ_entry | 10.51 GB | 12.93 GB | ~35 GB |
| t24_re_consol_spec_entry | 13.40 GB | 16.44 GB | ~45 GB |
| t24_stmt_entry | 61.02 GB | 81.43 GB | ~203 GB |
| t24_line_mvmt_toanhang | 19.31 GB | 24.67 GB | ~64 GB |
| **Tong** | **~104 GB** | **~136 GB** | **~347 GB** |

> Full 3.3 nam = uoc tinh tuyen tinh tu so lieu 1 nam thuc te.

---

## Du lieu nguon & Resource estimate

> In-memory expansion: Photon doc Parquet columnar ~ x2.5 so voi disk
> Spill = In-mem - 61 GB RAM (am = khong spill)

| Script | Source table | Range | Disk | In-mem (x2.5) | Spill | Est. thoi gian |
|---|---|---|---|---|---|---|
| 2a | t24_categ_entry | Full 3.3 nam | ~35 GB | ~88 GB | ~27 GB | 30-60 min |
| 2b | t24_re_consol_spec_entry | Full 3.3 nam | ~45 GB | ~113 GB | ~52 GB | 40-75 min |
| 2c | t24_line_mvmt_toanhang | Full 3.3 nam | ~64 GB | ~160 GB | ~99 GB | 60-120 min |
| 2d stmt s1 | t24_stmt_entry | 0.9 nam | ~55 GB | ~138 GB | ~77 GB | 1.5-3 gio |
| 2d stmt s2 | t24_stmt_entry | 1 nam | 61 GB | ~153 GB | ~92 GB | 2-4 gio |
| 2d stmt s3 | t24_stmt_entry | 1.5 nam | ~91 GB | ~228 GB | ~167 GB | 3-6 gio |

### Ly do chia stmt_entry theo nam

| Source | 1 nam disk | 3.3 nam disk | In-mem 3.3 nam | Chay full duoc? |
|---|---|---|---|---|
| t24_categ_entry | 10.51 GB | ~35 GB | ~88 GB | Duoc |
| t24_re_consol_spec_entry | 13.40 GB | ~45 GB | ~113 GB | Duoc |
| t24_line_mvmt_toanhang | 19.31 GB | ~64 GB | ~160 GB | Duoc, spill chap nhan |
| t24_stmt_entry | 61.02 GB | ~203 GB | ~508 GB | Khong — spill 447 GB |

---

## So sanh 2 option cho stmt_entry

| Tieu chi | Option 1 — Sequential | Option 2 — Parallel |
|---|---|---|
| Thu tu chay | s1 xong -> s2 xong -> s3 | s1 + s2 + s3 dong thoi |
| Cluster dung (stmt) | 1 | 3 |
| Can dedup | Khong — LEFT ANTI JOIN tu loc ky truoc | Co — chay dedup_after_parallel.sql |
| Wall-clock stmt | 6-13 gio | 3-6 gio |
| Rui ro | Thap | Trung binh |
| Phu hop khi | An toan la uu tien, it cluster du dung | Muon nhanh, chap nhan quan ly them dedup |

**Wall-clock tong the (2a/2b/2c chay song song voi stmt):**
- Option 1: bi gia han boi stmt sequential — ~6-13 gio
- Option 2: bi gia han boi stmt s3 — ~3-6 gio

---

## Mo ta tung script

| Script | Noi dung | Satellite targets |
|---|---|---|
| `2a__categ_20230209_20260602.sql` | t24_categ_entry, full range | sat_categ_entry_audit / information / classification |
| `2b__reconsol_20230209_20260602.sql` | t24_re_consol_spec_entry, full range | sat_re_consol_spec_entry_audit / information / classification |
| `2c__linemvmt_20230209_20260602.sql` | t24_line_mvmt_toanhang, full range | sat_line_movement_toanhang |
| `stmt/s1` | t24_stmt_entry, nam 1 | sat_stmt_entry_audit / information / classification |
| `stmt/s2` | t24_stmt_entry, nam 2 | sat_stmt_entry_audit / information / classification |
| `stmt/s3` | t24_stmt_entry, nam 3 (1.5 nam) | sat_stmt_entry_audit / information / classification |

---

## Dedup (Option 2)

Chi ap dung cho stmt_entry. 3 bang con lai chay full range 1 script — khong co race condition.

Dedup quet window 1 thang tai 2 ranh gioi:
- Ranh gioi 1: `2024-01-01` -> `2024-01-31` (s1 <-> s2)
- Ranh gioi 2: `2025-01-01` -> `2025-01-31` (s2 <-> s3)

---

## Rollback

Delta Time Travel retention mac dinh: 7 ngay (data files) / 30 ngay (log).
Phai rollback trong vong 7 ngay ke tu khi chay.

```
1. Chay 1__pre_run_capture_versions.sql  ->  copy cot delta_version
2. Dien version vao DECLARE trong 4__rollback_to_captured_versions.sql
3. Chay rollback script
```

---

## Luu y van hanh

- Tat hoac pause Daily DBT pipeline truoc khi chay de tranh xung dot write
- Submit 2a, 2b, 2c cung luc voi stmt scripts (tuy option)
- Neu stmt s3 (91 GB) bi OOM: chia tiep thanh `20250101-20251231` va `20260101-20260602`
- RESTORE la DML operation — neu co Structured Streaming doc cac satellite tables, can tat truoc khi rollback
