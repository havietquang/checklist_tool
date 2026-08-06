# Hướng dẫn sử dụng — INPUT gì, OUTPUT gì

## 1. Sơ đồ tổng

```
INPUT                                    OUTPUT
──────────────────────────────────       ─────────────────────────────────────────────
input/sql/*.sql          ┐               (A) Bảng kết quả in ra console
   code SQL Gold         │                   từng tiêu chí + tỷ lệ lỗi + Đạt/Không đạt
                         │
input/mapping/*.xlsx     ├─ run_check ─► (B) output/Checklist_Review_AUTOFILLED.xlsx
   workbook thiết kế     │                   sheet "Review theo bảng"    - 1 dòng / object
                         │                   sheet "Auto-check chi tiết" - bằng chứng đầy đủ
input/checklist/*.xlsx   ┘
   template checklist
[tùy chọn] --gold-list "<danh sách Gold đã duyệt>.xlsx"
```

Ghép cặp SQL ↔ workbook **tự động theo tên object**: `FTP_FACT.sql` ↔ `FTP_FACT_Silver_to_Gold.xlsx`.
Tool tự bỏ các hậu tố `_Silver_to_Gold`, `_mapping`, `_v2`, `_backup`, `(1)`, `_20260717`.

---

## 2. Lệnh chạy

```bash
# Lần đầu
pip install sqlglot

# Chạy đủ: 19 file SQL trong 8_VIE/SQL_curated_tckh + workbook mapping trong 8_VIE
python tools/gold_review/run_check.py --batch "Batch 2" --pic QuangHV
```

Đổi thư mục input:

```bash
python tools/gold_review/run_check.py \
    --dir 8_VIE/SQL_curated_tckh \        # nơi chứa .sql
    --mapping-dir 8_VIE \                 # nơi chứa workbook mapping
    --batch "Batch 2" --pic QuangHV
```

Soi 1 object hoặc 1 tiêu chí (không xuất Excel):

```bash
python tools/gold_review/run_check.py --file 8_VIE/SQL_curated_tckh/FTP_FACT.sql --no-excel
python tools/gold_review/run_check.py --rule 2.4 --no-excel          # 1 tiêu chí, toàn bộ file
python tools/gold_review/run_check.py --rule "3.*" --no-excel        # cả nhóm Optimization
```

---

## 2b. Nguồn code: sheet `Script SQL` (mặc định) hay file `.sql`

**Mặc định** tool lấy code từ sheet `Script SQL` của workbook thiết kế — khỏi phải đồng bộ hai nơi:

```bash
python tools/gold_review/run_check.py --batch "Batch 2" --pic QuangHV            # workbook
python tools/gold_review/run_check.py --from-sql --batch "Batch 2" --pic QuangHV # input/sql/*.sql
```

Dòng đầu console luôn ghi rõ nguồn đang dùng và số object đọc được.

Sheet phải ở dạng bảng, tool nhận cột theo tên (không phân biệt hoa thường, có dấu hay không):

```
 Type      | View / Table         | Script SQL
 Code cũ   | V_CDTK_DAILY_1       | CREATE VIEW [dbo].[V_CDTK_DAILY_1] AS ...   <- BỎ QUA
 Code mới  | V_CDTK_DAILY_1 (Gold)| CREATE OR REPLACE VIEW ... AS ...           <- CHẤM DÒNG NÀY
```

- Chỉ lấy dòng có `Type` chứa `mới` / `new` / `gold` / `dbx` / `databricks` — `Code cũ` là T-SQL
  on-prem, không phải thứ cần chấm.
- Tên object lấy từ cột `View / Table` (bỏ hậu tố `(Gold)`).
- Tiêu chí 1.2 **không** so tên file ở chế độ workbook vì không có file `.sql` để đối chiếu.
- Object nào workbook chưa khai dòng `Code mới` thì **không được chấm** — kiểm số object ở dòng
  đầu console, thiếu thì bổ sung vào sheet hoặc chạy `--from-sql`.

> **Hai nguồn có thể lệch nhau.** Mặc định chấm code trong workbook; `--from-sql` chấm file
> `.sql`. Chạy cả hai rồi so kết quả là cách nhanh nhất để phát hiện thiết kế đã cũ hơn code thật
> (hoặc ngược lại).

---

## 3. Ví dụ đầy đủ — object `FTP_FACT`

### INPUT 1 — code SQL: `8_VIE/SQL_curated_tckh/FTP_FACT.sql`

```sql
DELETE FROM ocb_datavault_dev_curated.tckh.FTP_FACT WHERE CDR_DT_ID = CAST(:DATADT AS INT);
INSERT INTO ocb_datavault_dev_curated.tckh.FTP_FACT
WITH ... SELECT CDR_DT_ID, AR_ID, OU_ID, ... FROM ...
```

### INPUT 2 — workbook thiết kế: `8_VIE/FTP_FACT_Silver_to_Gold.xlsx`

Sheet `FTP_FACT` — tool đọc **2 block**:

```
JOIN SCHEMA  —  các bảng nguồn
 # | TABLE / VIEW                | ALIAS | JOIN TYPE | ON / CONDITIONS
 1 | V_PRI_FTP_FACT              | p     | BASE      |
 2 | HUB_BRANCH                  | hb    | LEFT JOIN | hb.business_key = p.BRANCH_CODE
 6 | SAT_CUSTOMER_CLASSIFICATION | sc    | LEFT JOIN | sc.customer_hashkey = lc.cst_hk
                                    ↑ dùng cho tiêu chí X.8 (thiết kế khớp SQL?)

FIELD MAPPING  —  FTP_FACT (18 cột)
 STT | FIELD      | DATA TYPE     | TYPE      | TRANSFORM              | TABLE / VIEW SOURCE
 1   | CDR_DT_ID  | INT           | Transform | string_from_date(...)  | V_PRI_FTP_FACT
 7   | AMT_LCY    | DECIMAL(20,4) | 1:1       | AMT_LCY                | V_PRI_FTP_FACT
                                    ↑ dùng cho tiêu chí 1.1 (SQL đủ cột chưa?)
```

Sheet `SQL` / `Script` / `Code` chỉ là dump code — tool **bỏ qua** khi đọc đặc tả.
File mẫu đầy đủ 2 block: `tests/fixtures/mapping/GOOD_FCT_Silver_to_Gold.xlsx` (sinh lại bằng
`python tools/gold_review/tests/make_fixture_mapping.py`).

### OUTPUT A — console

```
TCKH.FTP_FACT   [SILVER_CONSUMER]   8_VIE/SQL_curated_tckh/FTP_FACT.sql
  ty le loi = 90%  (N1=0 N2=1 N3=1)   nguong 20%   -> KHONG DAT   | chua xac minh: 6
    pass   1.1   Du mapping Silver->Gold
    FAIL   2.1   Chi lay ban ghi active, loai ban ghi da xoa (qua sts_hub)
             - 4 hub khong loc ban ghi da xoa qua sts_hub_*: hub_branch (thieu sts_hub_branch, dong 31) ...
    WARN   3.3   Filter truoc khi join, tan dung partition pruning
             - 3 bang join truc tiep khong co filter rieng: cb_ofcr_dim (ofd), hub_customer (hc) ...
```

Mỗi dòng FAIL/WARN đều kèm **tên đối tượng + số dòng code** để mở đúng chỗ mà sửa.

### OUTPUT B — Excel `out/Checklist_Review_AUTOFILLED.xlsx`

Sheet `Review theo bảng`, mỗi object 1 dòng từ dòng 4 (dòng 3 ví dụ giữ nguyên):

| B (Object) | C | D | E | F (1.1) | G (1.2) | H (2.1) | … | AF (Ghi chú) |
|---|---|---|---|---|---|---|---|---|
| OCB…TCKH.FTP_FACT | Batch 2 | QuangHV | 2026-07-28 | Pass | Pass | **Fail** | … | CHƯA CÓ SỐ LIỆU (1): 2.7 \| [2.1] thiếu sts_hub… |

- Ô `Pass` / `Fail` → máy điền.
- Tiêu chí **chưa có số liệu** để kết luận (có sau UAT test) vẫn ghi `Pass`, nhưng được liệt kê rõ ở cột `AF` (mục "CHƯA CÓ SỐ LIỆU") và sheet `Auto-check chi tiết` — cập nhật lại ô sau khi có số.
- Công thức `AA:AF` (tỷ lệ lỗi, Kết luận) **giữ nguyên** → mở Excel là tự tính, Dashboard tự tổng hợp.

---

## 3b. Chạy trên bộ test có sẵn

```bash
python tools/gold_review/run_check.py \
    --dir         tools/gold_review/input_test/sql \
    --mapping-dir tools/gold_review/input_test \
    --out         tools/gold_review/input_test/out \
    --batch "Batch 2" --pic QuangHV
```

Xem [input_test/README.md](input_test/README.md) — bộ này gồm 4 file SQL + 1 workbook mô tả 5 object,
dùng `IDENTIFIER(:cleaned || …)` và `USE CATALOG`.

### Một workbook mô tả nhiều object

Tool index theo **tên object**, không theo tên file, nên 1 workbook chứa nhiều sheet
(`V_CDTK_DAILY`, `HOLIDAY`, `WORKING_DAY`, `TB_CDKT_DAILY_DTL`) vẫn ghép đúng với từng file `.sql`.

Nếu **2 object nằm cạnh nhau theo cột** trên cùng một sheet (LV0 ở cột A–F, LV1 ở cột G–L),
tool tách theo cột dựa vào tiêu đề block:

```
     A                            G
1  LV0 — VIEW đích (V_CDTK_DAILY)  LV1 — VIEW (V_CDTK_DAILY_1)
2  JOIN SCHEMA — V_CDTK_DAILY      JOIN SCHEMA — V_CDTK_DAILY_1     ← mỗi tiêu đề mở 1 vùng
7  FIELD MAPPING — V_CDTK_DAILY    FIELD MAPPING — V_CDTK_DAILY_1
```

Tên object lấy từ phần sau dấu `—` của tiêu đề block; không có thì lấy tên sheet.

---

## 4. Cách chấm từng tiêu chí

Chi tiết đầy đủ 29 tiêu chí — máy đọc gì, luật kết luận, ví dụ FAIL / PASS, dòng code thực thi —
nằm ở **[RULES.md](RULES.md)**.

Nguyên tắc chung: **chỉ chấm Pass/Fail khi tiêu chí có đúng một đáp án; còn lại máy đưa số đo,
người quyết.**

| Kiểu | Ví dụ | Vì sao |
|---|---|---|
| **AUTO** | 3.1 `SELECT *`, 3.5 `MAX_BY`, 2.1 `sts_hub`, 2.4 `source_event_date` | Chỉ có 1 cách đúng — tài liệu đã chốt pattern hoặc so khớp cơ học được |
| **WARN** (ghi `Fail`) | 3.2 CTE scan lại, 3.3 filter trước join, 3.4 CACHE, 3.6 comment window | Nhiều lựa chọn kỹ thuật hợp lệ tùy ngữ cảnh — máy in số đo để người quyết |
| **MANUAL** (ghi `Pass`, liệt kê ở cột Ghi chú) | 2.7 CASE vs on-prem, 2.9 nghiệp vụ LIKE | Chưa có số liệu — có sau UAT test |

Ví dụ 3.2 với `PL_CUST_RM_FCT` — máy in:

```
FAIL~ 3.2  CTE duoc tham chieu nhieu lan: forex x4, forex_rm x2, cal_prev x4, anl x2
```

Bạn nhìn số đo và quyết trong vài giây: `cal_prev x4` là CTE 1 dòng → tick Pass.
`forex x4` là CTE join 8 bảng Silver → nên gom, để Fail. Máy **không tự quyết** vì cả 2 đều là
lựa chọn kỹ thuật hợp lệ tùy ngữ cảnh — tự quyết thì sẽ tạo "Pass giả" hoặc "Fail oan".

---

## 5. Nhóm X — 9 tiêu chí bổ sung Raffles

`X.1` link rút current · `X.2` env nhất quán · `X.3` INSERT liệt kê cột · `X.4` idempotent ·
`X.5` join NULL-safe · `X.6` satellite LEFT JOIN · `X.7` không hard-code catalog ·
`X.8` JOIN SCHEMA khớp SQL · `X.9` mọi bảng dev lại từ Silver

Kết quả nhóm X ghi vào cột `Ghi chú` và sheet chi tiết, **không** chiếm cột nào của OCB →
không phá công thức đã thống nhất.

---

## 6. Đọc kết quả

```
ty le loi = 100%  (N1=1 N2=1 N3=1)   nguong 20%   -> KHONG DAT
```

- `N1/N2/N3` = nhóm đó có ít nhất 1 tiêu chí Fail hay không (1 = có).
- `tỷ lệ lỗi = 0.1×N1 + 0.8×N2 + 0.1×N3` — đúng công thức trong file checklist.
- Ngưỡng: Batch 1 ≤ 30%, Batch 2/3 ≤ 20%.
- **Chỉ cần 1 tiêu chí Nhóm 2 Fail → 80% → Không đạt ở mọi batch.** Ưu tiên sửa Nhóm 2 trước.

Exit code: `0` tất cả đạt · `1` còn object không đạt · `3` self-test rule trượt (đừng tin kết quả).
