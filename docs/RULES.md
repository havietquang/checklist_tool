# Cách chấm từng tiêu chí — máy đọc gì, kết luận thế nào

File này trả lời đúng một câu hỏi: **với mỗi tiêu chí, tool nhìn vào cái gì và dựa vào đâu để
ghi Pass / Fail?** Mỗi tiêu chí có: nguồn dữ liệu máy đọc, luật kết luận, một ví dụ FAIL và một
ví dụ PASS, và dòng code thực thi luật đó.

- Danh sách tiêu chí và cách sửa (tiếng Việt, ghi vào Excel): [engine/rule_text.py](../engine/rule_text.py)
- Code chấm: [engine/rules.py](../engine/rules.py) — mỗi tiêu chí là một hàm
- Input/output và cách chạy: [USAGE.md](USAGE.md)

---

## 0. Ba khái niệm phải hiểu trước khi đọc bảng

### 0.1 Năm trạng thái nội bộ → hai giá trị trong ô Excel

Excel chỉ nhận `Pass` / `Fail` (công thức `COUNTIF(...,"Fail")` đã thống nhất với OCB), nhưng
máy phân biệt 5 trạng thái để note giải trình được:

| Trạng thái | Ghi vào Excel | Nghĩa | Ghi chú |
|---|---|---|---|
| `PASS` | `Pass` | Máy kết luận đạt | không |
| `N-A` | `Pass` | Tiêu chí không áp dụng cho object này → không có gì để sai | không |
| `MANUAL` | `Pass` | **Chưa có số liệu để kết luận**, sẽ có sau UAT test. Ghi tạm Pass | **có** — cập nhật lại sau khi có số |
| `WARN` | `Fail` | Có dấu hiệu nghi vấn, DE phải giải trình hoặc sửa | không |
| `FAIL` | `Fail` | Máy kết luận không đạt | không |

Quy đổi ở [engine/report.py](../engine/report.py) (`CELL`) và [run_check.py](../run_check.py)
(`score`) — sửa một chỗ phải sửa chỗ kia.

Console in ký hiệu phản ánh đúng giá trị vào Excel:
`FAIL` → `FAIL`, `WARN` → `FAIL~`, `PASS` → `pass`, `MANUAL` → `pass?`, `N-A` → ẩn.

### 0.2 Ba kiểu chấm

| Kiểu | Nghĩa | Vì sao chọn kiểu này |
|---|---|---|
| **AUTO** | Máy kết luận Pass hoặc Fail | Tiêu chí chỉ có **một** đáp án đúng (tài liệu đã chốt pattern, hoặc so khớp cơ học được) |
| **WARN** | Máy **đo và liệt kê**, quy ra `Fail` để buộc người xem, nhưng không khẳng định sai | Có nhiều lựa chọn kỹ thuật hợp lệ tùy ngữ cảnh — tự quyết sẽ tạo "Pass giả" hoặc "Fail oan" |
| **MANUAL** | Chưa có số liệu để kết luận (đối chiếu 2 hệ thống, so nhánh CASE với job on-prem) — có sau UAT test | Ghi tạm `Pass`, được **liệt kê ở cột Ghi chú** để không âm thầm bỏ qua |

### 0.3 Máy đọc từ ba nguồn

| Nguồn | Là gì | Dùng cho |
|---|---|---|
| **AST** | Cây cú pháp `sqlglot` (dialect `databricks`) của file SQL | Cấu trúc: JOIN, ON, WHERE, CTE, aggregate, INSERT/DELETE |
| **Text gốc** | Chính nội dung file (`ctx.raw`) + regex | Những gì AST không giữ: **số dòng**, comment `--`, tên catalog, `max_by(cdc_status,…)` |
| **Workbook thiết kế** | `input/mapping/*.xlsx`, ghép với file SQL theo tên object | Block `FIELD MAPPING` (1.1), block `JOIN SCHEMA` (X.8) |

`sqlglot` không giữ vị trí ký tự, nên **mọi số dòng trong bằng chứng đều lấy bằng regex trên text
gốc** (`lines_of`, `first_line` ở [engine/core.py](../engine/core.py)). Số dòng là chỉ dẫn để mở
đúng chỗ, không phải kết quả parse.

### 0.4 Profile — vì sao một tiêu chí tự `N-A`

Máy tự phân loại object theo bảng nguồn nó đọc ([core.py](../engine/core.py) `_fill`):

| Profile | Điều kiện | Ví dụ trong batch |
|---|---|---|
| `SILVER_CONSUMER` | Đọc trực tiếp `*.raw_vault.*` / `*.business_vault.*` | `HOLIDAY`, `WORKING_DAY` |
| `GOLD_DERIVED` | Chỉ đọc `*_curated.*` (Gold trên Gold) | `V_CDTK_DAILY`, `TB_CDKT_DAILY_DTL` |
| `UPLOAD_VIEW` | Còn placeholder `<...>` hoặc có `upload` / `_upl` | view trên bảng upload |
| `LEGACY_TSQL` / `SCRIPT_ONLY` | Code cũ on-prem, hoặc script không tạo object Gold | **không chấm**, in ở mục "Bỏ qua" |

Tiêu chí khai báo `profiles=(P_SILVER,)` thì object `GOLD_DERIVED` tự nhận `N-A` — ví dụ 2.1
(lọc `sts_hub`) không có nghĩa với view chỉ đọc Gold.

---

## 1. Bảng tổng — 21 tiêu chí OCB + 9 tiêu chí Raffles

`Cột` = cột trên sheet `Review theo bảng` của file checklist.

### Nhóm 1 — Mapping (trọng số 10%)

| Mã | Cột | Kiểu | Máy đọc | Fail khi |
|---|---|---|---|---|
| 1.1 | F | AUTO | Workbook `FIELD MAPPING` + cột output SQL | Còn placeholder, hoặc lệch danh sách cột |
| 1.2 | G | AUTO | Tên object trong `CREATE` vs tên file vs tên trong workbook; `--gold-list` | Lệch tên giữa 3 nơi, hoặc object không có trong danh sách / không có workbook |

### Nhóm 2 — Logic (trọng số 80%, quyết định Đạt / Không đạt)

| Mã | Cột | Kiểu | Máy đọc | Fail khi |
|---|---|---|---|---|
| 2.1 | H | AUTO | Tên bảng `hub_*`/`sts_hub_*` + regex `max_by(cdc_status,…)='D'` | Thiếu `sts_hub_*`, thiếu anti-join, hoặc lọc `cdc_status` trong satellite |
| 2.2 | I | AUTO | Chữ ký lấy bản ghi mới nhất, so trong file và toàn batch | Bất nhất trong 1 file, hoặc lệch chuẩn `MAX_BY` khi batch bất nhất |
| 2.3 | J | AUTO | Mệnh đề `ON` của mọi JOIN | `cdc_status`/`rn`/`ROW_NUMBER` trong `ON` của OUTER JOIN → FAIL; INNER JOIN → WARN |
| 2.4 | K | AUTO | Điều kiện `source_event_date` quanh mỗi satellite | Sai dạng `<=` / `=` theo loại bảng, thiếu điều kiện, hoặc có cận dưới `>=` |
| 2.5 | L | AUTO | `known_issues.json` (trích từ Iss log của DA Data Vault) | Trùng ≥ 1 lỗi DA đã nêu → FAIL |
| 2.6 | M | AUTO | Object có đuôi `_DIM` | `MAX(ID)+ROW_NUMBER`, hoặc không SCD2 và không có cột hiệu lực |
| 2.7 | N | MANUAL | Số `CASE` và số `CASE` thiếu `ELSE` | *(cần job on-prem để so từng nhánh)* |
| 2.8 | O | MANUAL | `SUM`/`COUNT` chưa bọc `COALESCE` | *(giữ nguyên logic cũ là hợp lệ → không tự Fail)* |
| 2.9 | P | MANUAL | Điều kiện `LIKE` + scalar subquery | *(ý nghĩa nghiệp vụ máy không kiểm được)* |
| 2.10 | Q | WARN | Mọi khối có aggregate / `GROUP BY` | Không có điều kiện theo ngày hoặc tham số |
| 2.11 | R | WARN | `UNION` + `EXISTS`; JOIN không có `=` | Có một trong hai |
| 2.12 | S | AUTO | Số **khối SELECT** đọc cùng một bảng (self-join không tính) | Bảng `raw_vault` đọc ở > 1 khối → FAIL; bảng khác → WARN |

### Nhóm 3 — Optimization (trọng số 10%)

| Mã | Cột | Kiểu | Máy đọc | Fail khi |
|---|---|---|---|---|
| 3.1 | T | AUTO | Danh sách biểu thức của mọi `SELECT` | Có `SELECT *` hoặc `alias.*` |
| 3.2 | U | WARN | Số lần mỗi CTE "nặng" bị tham chiếu lại | Từ 2 lần trở lên |
| 3.3 | V | WARN | `WHERE` của SELECT chứa JOIN **và** `ON` của chính JOIN đó | Bảng join không có điều kiện lọc riêng ở cả hai chỗ |
| 3.4 | W | WARN | CTE dùng lại ≥ 2 lần + `CACHE` | Có CTE nặng dùng lại mà không `CACHE` |
| 3.5 | X | AUTO | `ROW_NUMBER` / `MAX_BY` | Lấy dòng mới nhất bằng `ROW_NUMBER … = 1` |
| 3.6 | Y | WARN | Dòng có `OVER (` + comment `--` quanh đó | Window function không có comment giải thích |

### Nhóm X — bổ sung Raffles (không chiếm cột nào của OCB, chỉ ghi vào note)

| Mã | Kiểu | Máy đọc | Fail khi |
|---|---|---|---|
| X.1 | AUTO | JOIN vào bảng `link_*` | Chưa rút về current (`GROUP BY` + `max_by`) trước khi join |
| X.2 | AUTO | Tên môi trường trong catalog | Trộn ≥ 2 môi trường trong 1 file |
| X.3 | AUTO | Câu `INSERT` | `INSERT INTO <bảng> SELECT …` không liệt kê cột |
| X.4 | AUTO | `INSERT` / `DELETE` / `TRUNCATE` | Có INSERT mà không có DELETE/TRUNCATE; khóa DELETE lạ → WARN |
| X.5 | WARN | Cột từng được `NVL` ở chỗ khác | Cột đó join bằng `=` mà không NULL-safe |
| X.6 | AUTO | Kiểu JOIN vào bảng `sat_*` | Dùng INNER JOIN |
| X.7 | WARN | Tên catalog trong text | Hard-code `ocb_datavault_*_cleaned/curated` |
| X.8 | AUTO | Workbook `JOIN SCHEMA` vs bảng trong SQL | Bảng trong thiết kế không có trong SQL → FAIL; ngược lại → WARN |
| X.9 | AUTO | `raw_vault`/`business_vault` + chuỗi truy nguồn toàn batch + cột `NOTE` của JOIN SCHEMA | Không truy được về Silver và không khai là bảng upload/thủ công |

---

## 2. Chi tiết từng tiêu chí

Ký hiệu: **Đọc** = nguồn dữ liệu · **Luật** = điều kiện → trạng thái · **Code** = vị trí thực thi.

---

### 1.1 — Đủ mapping Silver → Gold

**Cột F** · AUTO · áp dụng `SILVER_CONSUMER`, `GOLD_DERIVED`, `UPLOAD_VIEW` ·
**Code** [rules.py:114](../engine/rules.py#L114)

**Đọc**
- Cột đầu ra của SQL (`ctx.out_columns`): ưu tiên danh sách cột của `INSERT INTO … (A, B, C)`;
  không có thì lấy alias của `SELECT` ngoài cùng ([core.py](../engine/core.py) `_out_columns`).
- Block `FIELD MAPPING` trong workbook thiết kế đã ghép với file SQL.

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Còn placeholder dạng `<upload_catalog>` trong file | `FAIL` |
| Không tìm thấy workbook thiết kế | `MANUAL` |
| Có workbook nhưng không đọc được block `FIELD MAPPING` | `FAIL` |
| Có cột trong thiết kế mà SQL thiếu, **hoặc** SQL có cột thiết kế không khai | `FAIL` |
| Khớp hoàn toàn | `PASS` |

So khớp theo **tên cột, không phân biệt hoa thường, không xét thứ tự**.

**Ví dụ FAIL** — thiết kế có 4 field `CDR_DT_ID, AR_ID, OU_ID, AMT_LCY`, SQL chỉ select 3:

```sql
INSERT INTO ocb_datavault_dev_curated.tckh.FTP_FACT (CDR_DT_ID, AR_ID, AMT_LCY)
SELECT ...
```

> `workbook FTP_FACT_Silver_to_Gold.xlsx: thiết kế 4 field, SQL có 3 cột; SQL THIẾU 1 cột có trong thiết kế: ['OU_ID']`

**Ví dụ FAIL (placeholder)**

```sql
CREATE OR REPLACE VIEW <upload_catalog>.tckh.v_rate AS SELECT ...
```

> `còn placeholder chưa thay: <upload_catalog> tại dòng [1]`

**Ví dụ PASS**

```sql
INSERT INTO ocb_datavault_dev_curated.tckh.FTP_FACT (CDR_DT_ID, AR_ID, OU_ID, AMT_LCY)
SELECT ...
```

---

### ~~1.3~~ — Đối chiếu số dòng / SUM với hệ thống cũ — **ĐÃ BỎ khỏi checklist**

Đối chiếu số bản ghi và `SUM` cột số giữa Gold (Databricks) và data mart cũ (MSSQL – Tableau) cần
**dữ liệu thật trên cả hai hệ thống**, không suy được từ code, nên tiêu chí này **không còn được
máy chấm**: cột `G` để **trống** cho người review tự điền sau khi đối soát ở bước UAT, và không có
dòng nào về nó trong cột Ghi chú. Cột `1.3` cũng đã được **bỏ khỏi file checklist**;
nhóm 1 đánh số lại liền mạch còn **1.1** và **1.2** (1.2 trước đây mang mã 1.4).

Khi đối soát thủ công, lưu ý bọc `NVL` / `ISNULL` **cả hai phía** cho các cột số để hai bên cùng
cơ sở so sánh (Checklist RVN-OCB #11).

---

### 1.2 — Danh sách bảng/view khớp tài liệu thiết kế  *(trước đây là mã 1.4)*

**Cột G** · AUTO · **Code** [rules.py:152](../engine/rules.py#L152)

**Đọc** — tên object lấy từ câu `CREATE`/`INSERT`, đối chiếu với:
1. **tên file `.sql`** (chỉ khi target lấy được từ AST — có câu `CREATE`/`INSERT` thật);
2. **tên object khai trong workbook** thiết kế đã ghép;
3. danh sách Gold đã duyệt, nếu chạy kèm `--gold-list "<file>.xlsx"`;
4. nếu không có tham số đó: sự tồn tại của workbook thiết kế trong `input/mapping/`.

**Luật** — kiểm lệch tên trước, rồi mới đối chiếu danh sách:

| Điều kiện | Trạng thái |
|---|---|
| Tên object trong SQL ≠ tên file `.sql` | `FAIL` |
| Tên object trong SQL ≠ tên object khai trong workbook | `FAIL` |
| Có `--gold-list` và tên object nằm trong danh sách | `PASS` |
| Có `--gold-list` và tên object **không** nằm trong danh sách | `FAIL` |
| Không có `--gold-list`, có workbook thiết kế | `PASS` |
| Không có `--gold-list`, không có workbook | `FAIL` |

> **Vì sao phải kiểm tên ở 3 nơi.** `attach_mapping` ghép workbook theo tên object **trước**, không
> khớp thì fallback theo **tên file**. Nên một object viết sai tên bên trong câu `CREATE` vẫn ghép
> được workbook qua tên file và lọt hết các tiêu chí còn lại. Ví dụ thật:
> file `tb_cdkt_daily_dtl.sql` nhưng bên trong là `CREATE TABLE tb_cdtk_daily_dtl` — deploy ra sẽ
> tạo một bảng khác, còn view đọc `tb_cdkt_daily_dtl` thì không tìm thấy bảng.

**Ví dụ FAIL**

> `lệch tên: SQL tạo object TB_CDTK_DAILY_DTL nhưng file đặt tên tb_cdkt_daily_dtl.sql (TB_CDKT_DAILY_DTL)`
> `lệch tên: thiết kế khai object TB_CDKT_DAILY_DTL còn SQL tạo TB_CDTK_DAILY_DTL (ghép cặp được nhờ tên file nên dễ bị bỏ qua)`

**Ví dụ FAIL** — `input/sql/v_cdtk_daily_2.sql` mà `input/mapping/` không có workbook nào tên
`V_CDTK_DAILY_2`:

> `V_CDTK_DAILY_2 không có workbook thiết kế tương ứng trong thư mục mapping`

**Lưu ý**: bản không có `--gold-list` chỉ chứng minh "có tài liệu", không chứng minh "đã được
OCB duyệt". Muốn chấm đúng nghĩa tiêu chí thì phải truyền `--gold-list`.

---

### 2.1 — Chỉ lấy bản ghi active, loại bản ghi đã xóa (qua `sts_hub`)

**Cột H** · AUTO · chỉ `SILVER_CONSUMER` · **Căn cứ** Technical Document III.4.2.1 ·
**Code** [rules.py:165](../engine/rules.py#L165)

**Đọc**
- Tên bảng thật (đã trừ CTE): bảng `hub_*` và bảng `sts_hub_*`.
- Regex trên text gốc: `max_by(cdc_status, source_event_date) = 'D'`, và `IS NULL`.
- AST: satellite nào có `cdc_status` trong điều kiện lọc bao quanh nó.

**Luật** — cộng dồn bằng chứng, có bằng chứng nào là `FAIL`:

| Điều kiện | Kết quả |
|---|---|
| Script không đọc bảng `hub_*` lẫn `sat_*` | `N-A` |
| Có `hub_<ent>` mà không có `sts_hub_<ent>` tương ứng | bằng chứng → `FAIL` |
| Có đọc `sts_hub_*` nhưng không thấy `HAVING max_by(cdc_status, source_event_date) = 'D'` | bằng chứng → `FAIL` |
| Có đọc `sts_hub_*` nhưng cả file không có `IS NULL` (thiếu anti-join) | bằng chứng → `FAIL` |
| Lọc `cdc_status` **ngay trong satellite** | bằng chứng → `FAIL` (sai tầng) |
| Đọc satellite mà không qua CTE `<ent>_active` của hub | `WARN` |
| Không có bằng chứng nào | `PASS` |

**Ví dụ FAIL** — hub không lọc bản ghi đã xóa, lại lọc `cdc_status` ở satellite:

```sql
SELECT h.customer_hashkey, s.cst_nm
FROM   ocb_dv_cleaned.raw_vault.hub_customer h
LEFT JOIN ocb_dv_cleaned.raw_vault.sat_customer s
       ON s.customer_hashkey = h.customer_hashkey
WHERE  s.cdc_status <> 'D'                      -- SAI TẦNG
```

> `1 hub KHÔNG lọc bản ghi đã xóa qua sts_hub_*: hub_customer ở dòng 3 (thiếu CTE đọc sts_hub_customer); lọc cdc_status ngay trong satellite là SAI TẦNG (phải lọc ở sts_hub): ['sat_customer']`

**Ví dụ PASS** — đúng pattern III.4.2.1:

```sql
WITH cst_sts_del AS (
    SELECT customer_hashkey
    FROM   ocb_dv_cleaned.raw_vault.sts_hub_customer
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP  BY customer_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
cst_active AS (
    SELECT h.customer_hashkey, h.business_key
    FROM   ocb_dv_cleaned.raw_vault.hub_customer h
    LEFT   JOIN cst_sts_del d ON d.customer_hashkey = h.customer_hashkey
    WHERE  d.customer_hashkey IS NULL            -- anti-join
)
SELECT ... FROM cst_active a LEFT JOIN ...
```

---

### 2.2 — Thống nhất MỘT pattern xác định bản ghi active

**Cột I** · AUTO · chỉ `SILVER_CONSUMER` · **Code** [rules.py:211](../engine/rules.py#L211)

**Đọc** — với mỗi `SELECT` có đọc satellite, máy nhận diện **chữ ký** cách lấy bản ghi mới nhất
(`active_signatures`, [rules.py:89](../engine/rules.py#L89)):

| Chữ ký | Nhận diện bằng |
|---|---|
| `MAX_BY` | node `ArgMax` hoặc regex `MAX_BY(` — **pattern chuẩn đã chốt** |
| `QUALIFY_RN` | có `QUALIFY` chứa `ROW_NUMBER` |
| `SUBQ_RN` | có `ROW_NUMBER` ở chỗ khác |
| `MAX_SUBQ` | `MAX(<alias>.source_event_date)` trong subquery |

Đồng thời ghi hướng lọc `cdc_status`: `<>` / `!=` / `NOT IN` → `EXCLUDE_D`; `=` / `IN` → `INCLUDE_D`.

**Luật** — có cả chiều trong-file và chiều toàn-batch (`repo`):

| Điều kiện | Trạng thái |
|---|---|
| Một file dùng ≥ 2 chữ ký khác nhau | `FAIL` |
| Toàn batch có cả `EXCLUDE_D` và `INCLUDE_D`, mà file này có lọc `cdc_status` | `FAIL` (Issue log #2) |
| Toàn batch bất nhất (≥ 2 chữ ký) và file này **không** theo `MAX_BY` | `FAIL` |
| File không có bước lấy bản ghi mới nhất từ satellite | `N-A` |
| Còn lại | `PASS` |

**Ví dụ FAIL** — trong cùng một file, CTE này dùng `max_by`, CTE kia dùng `ROW_NUMBER`:

```sql
WITH a AS (SELECT hk, max_by(nm, source_event_date) nm FROM ... sat_x GROUP BY hk),
     b AS (SELECT hk, nm FROM ... sat_y QUALIFY ROW_NUMBER() OVER (PARTITION BY hk ORDER BY source_event_date DESC) = 1)
```

> `file này dùng: ['MAX_BY', 'QUALIFY_RN']; toàn batch dùng: ['MAX_BY', 'QUALIFY_RN']; BẤT NHẤT trong cùng 1 file, dùng 2 cách khác nhau: ['MAX_BY', 'QUALIFY_RN']`

**Ví dụ PASS** — cả hai CTE dùng `max_by`.

> Tiêu chí này phụ thuộc **toàn batch**: chấm một file lẻ bằng `--file` có thể ra `PASS` trong
> khi chấm cả batch ra `FAIL`, vì lúc đó máy mới thấy file khác lệch pattern.

---

### 2.3 — Điều kiện lọc đặt SAU `rn=1`, không lồng trong `JOIN … ON`

**Cột J** · AUTO · `SILVER_CONSUMER`, `GOLD_DERIVED` · **Code** [rules.py:228](../engine/rules.py#L228)

**Đọc** — mệnh đề `ON` của **mọi** JOIN trong file; tìm cột `cdc_status`, `rn`, `rnk`,
`row_num`, `ROW_NUMBER`, và `source_event_date`.

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Cột trạng thái nằm trong `ON` của **LEFT / RIGHT / FULL JOIN** | `FAIL` (Issue log #3) |
| Cột trạng thái nằm trong `ON` của **INNER JOIN** | `WARN` — tương đương WHERE nên chưa sai kết quả |
| `ON` sạch | `PASS` |

**Hai ngoại lệ được miễn cho `source_event_date`** (`_sed_in_on_allowed`):
1. **Pattern PIT**: `sat.source_event_date = p.<sat>_src_ev_dt` (III.4.2.4);
2. bảng nằm trong danh sách **bảng transaction** (221 bảng) ([doc_standard.py](../engine/doc_standard.py)).

**Ví dụ FAIL**

```sql
LEFT JOIN (SELECT hk, nm, ROW_NUMBER() OVER (PARTITION BY hk ORDER BY source_event_date DESC) rn
           FROM ... sat_customer) a
       ON a.hk = h.customer_hashkey
      AND a.rn = 1                              -- không match -> NULL âm thầm
```

> `đặt trong ON của OUTER JOIN sẽ ra NULL âm thầm khi không match (Issue log #3): ['rn'] nằm trong ON của LEFT JOIN a`

**Ví dụ PASS** — lọc `rn = 1` trong chính subquery, `ON` chỉ còn điều kiện khóa:

```sql
LEFT JOIN (SELECT hk, nm FROM ... sat_customer
           QUALIFY ROW_NUMBER() OVER (PARTITION BY hk ORDER BY source_event_date DESC) = 1) a
       ON a.hk = h.customer_hashkey
```

---

### 2.4 — `source_event_date` đúng dạng `<=` / `=` theo loại bảng

**Cột K** · AUTO · chỉ `SILVER_CONSUMER` · **Căn cứ** Technical Document III.4.2 + mục "Các
trường hợp đặc biệt" · **Code** [rules.py:265](../engine/rules.py#L265)

**Đọc** — với mỗi bảng được kiểm, máy quét **mọi lớp SELECT bao quanh** nó
(`WHERE` / `QUALIFY` / `HAVING` / `ON`) tìm:
- `has_le`: có `source_event_date <=` hoặc `<`;
- `has_eq`: có `source_event_date =`.

Phạm vi bảng được kiểm:

| Bảng | Có kiểm? | Ghi chú |
|---|---|---|
| `sat_*`, `csat_*` | có | qua `sat_refs()` |
| `hub_*`, `link_*`, `effsat_*` | **không** | xem ô cảnh báo bên dưới |
| `sts_hub_*` | **không** | `sts_hub_crb` có trong danh sách transaction nhưng buộc dùng `<=` — rule 2.1 cần toàn bộ lịch sử để lấy `max_by(cdc_status,…)='D'` |

> **Có mặt trong `TRANSACTION_SATS` không có nghĩa là phải dùng `=`.** Danh sách đó chỉ nói bảng
> nạp kiểu APPEND. Dạng điều kiện phụ thuộc **tầng bảng**: satellite của bảng transaction dùng
> `=`, còn `hub_*` / `link_*` của chính bảng đó dùng `<=` (vẫn phải lấy hết key đã phát sinh đến
> ngày chạy). Ví dụ nhóm CRB (OCB chốt 2026-08-13): `sat_crb_*` / `csat_crb_balance` dùng `=`,
> `hub_crb` và `link_crb_*` dùng `<=`, dù cả ba đều nằm trong danh sách.
>
> Cờ `CHECK_TXN_HUBS` trong `rules.py` để `False` vì lý do này. Bật lên sẽ báo sai cho đúng
> những chỗ đang làm đúng — chỉ bật khi có danh sách riêng "hub nào phải dùng `=`" từ OCB.

**Luật** — phụ thuộc bảng đó có nằm trong danh sách transaction hay không:

| Loại bảng | Điều kiện | Trạng thái |
|---|---|---|
| Transaction (221 bảng) | `= :DATADT` | đúng |
| Transaction | `<= :DATADT` | `FAIL` — sai dạng |
| Thường | `<= :DATADT` | đúng |
| Thường | `=` kèm pattern PIT (`= p.<sat>_src_ev_dt`) | đúng |
| Thường | `= :DATADT` mà không phải PIT | `FAIL` — bỏ sót bản ghi mới nhất nằm trước ngày chạy (Issue log #1) |
| Bất kỳ | không có điều kiện `source_event_date` nào | `FAIL` |
| Bất kỳ | có cận dưới `source_event_date >=` ở đâu đó | `FAIL` — tài liệu yêu cầu **chỉ chặn trên** |
| — | script không đọc satellite nào | `N-A` |

**Ví dụ FAIL** — bảng thường nhưng lọc `=`:

```sql
FROM ocb_dv_cleaned.raw_vault.sat_customer_classification s
WHERE s.source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
```

> `sat_customer_classification (dong 12): dùng = :DATADT nhưng KHÔNG thuộc danh sách bảng transaction, sẽ bỏ sót bản ghi mới nhất nằm trước ngày chạy (Issue log #1)`

**Ví dụ FAIL** — đặt thêm cận dưới:

```sql
WHERE s.source_event_date >= ADD_MONTHS(TO_DATE(:DATADT,'yyyyMMdd'), -1)
  AND s.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
```

> `có đặt cận dưới source_event_date >= ở dòng [18] — tài liệu yêu cầu CHỈ chặn trên, cận dưới làm bỏ sót bản ghi mới nhất`

**Ví dụ PASS** — mỗi loại một dạng, đúng theo tài liệu:

```sql
-- bảng thường: chặn trên
FROM ... sat_customer_classification s WHERE s.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
-- bảng transaction: lấy đúng ngày
FROM ... sat_account_balance b        WHERE b.source_event_date  = TO_DATE(:DATADT,'yyyyMMdd')
```

---

### 2.5 — Không lặp lại lỗi logic cũ đã fix

**Cột L** · AUTO · **Code** [rules.py:323](../engine/rules.py#L323)

**Đọc** — mỗi entry trong [engine/known_issues.json](../engine/known_issues.json) là một cặp
`"tên lỗi": "regex"`, trích từ **`ZoneC Mapping - Iss log.xlsx` sheet `Issue`** — danh sách lỗi
DA Data Vault đã nêu ở batch 1. Máy chạy từng regex trên text gốc. Khoá bắt đầu bằng `_` là
metadata, bỏ qua.

**Luật** — nhị phân:

| Điều kiện | Trạng thái |
|---|---|
| Khớp ≥ 1 lỗi trong Issue log | `FAIL` — in tên lỗi + số dòng |
| Không khớp lỗi nào | `PASS` |

Các lỗi đang bắt được:

| Issue log | Bắt bằng |
|---|---|
| #2 lọc `cdc_status = 'D'` (giữ bản ghi đã xoá) | `cdc_status = 'D'` ngoài ngữ cảnh `max_by(...)='D'` |
| #2 lấy trạng thái mới nhất bằng `ROW_NUMBER` trên `sts_hub_*` | `ROW_NUMBER() OVER (PARTITION BY … ORDER BY source_event_date)` |
| #3 `rn = 1` + `cdc_status` trong subquery của JOIN | `WHERE … rn = 1 AND … cdc_status` |
| #3 `rn = 1` đặt trong `JOIN … ON` | `ON … rn = 1` |
| #3 anti-join `IS NULL` trên tập `cdc_status = 'D'` (đảo nghĩa) | `cdc_status = 'D'` … `IS NULL` |
| #4 surrogate key `MAX(<DIM_ID>) + ROW_NUMBER` | `MAX(…ID) … + ROW_NUMBER` |
| #4 `COALESCE(MAX(<DIM_ID>),0)` làm mốc tăng dần | `COALESCE(MAX(…ID),0)` |
| #5 `ROW_NUMBER()+WHERE rn=1` thay `MAX_BY` | `WHERE … rn = 1` |
| TDD III.4.2 cận dưới `source_event_date >=` | `source_event_date >=` |

**Cách mở rộng**: OCB trả lỗi mới → thêm một regex vào `known_issues.json`, lần sau tự bắt được.
Đây là tiêu chí duy nhất "học" được từ lịch sử review.

> **Issue #1 đã bắt được** (từ 2026-08-12): "bảng transaction như `T24_CRB` vẫn dùng
> `source_event_date <=`". Việc này thuộc rule 2.4. Danh sách ở
> [doc_standard.py](../engine/doc_standard.py) có `hub_crb` và `csat_crb_balance`, nhưng trước
> đây rule 2.4 chỉ quét `sat_*` / `csat_*` nên `hub_crb` không đi qua tiêu chí nào — cả hai bản
> `T24_CRB` (`hub_crb =` và `hub_crb <=`) đều `pass`. Nay rule quét cả `hub_*` thuộc danh sách
> transaction, `<=` là `FAIL`.

---

### 2.6 — SCD Type 2 dùng kỹ thuật đã thống nhất

**Cột M** · AUTO · **Căn cứ** Technical Document mục LDP + Issue log #4 ·
**Code** [rules.py:336](../engine/rules.py#L336)

**Đọc** — chỉ chạy khi tên object kết thúc bằng `_DIM`. Quét text gốc tìm
`STORED AS SCD TYPE 2`, `MAX(<...>ID)`, `ROW_NUMBER`, và danh sách cột output.

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Object không phải `*_DIM` | `N-A` |
| Có `MAX(<...>_ID)` **và** `ROW_NUMBER` (tự sinh surrogate key) | `FAIL` (Issue log #4) |
| Có `APPLY CHANGES … STORED AS SCD TYPE 2` và không có antipattern trên | `PASS` |
| Không có SCD2 **và** output không có cột `EFF*_DT` / `END_DT` / `CURRENT_FLAG` / `IS_CURRENT` / `START_AT` | `FAIL` |
| Không có SCD2 nhưng có cột hiệu lực tự quản | `PASS` |

**Ví dụ FAIL**

```sql
INSERT INTO ...CB_OU_DIM (OU_ID, OU_CD, OU_NM)
SELECT (SELECT MAX(OU_ID) FROM ...CB_OU_DIM)
       + ROW_NUMBER() OVER (ORDER BY s.ou_cd), s.ou_cd, s.ou_nm
FROM ...
```

> `dùng antipattern MAX(ID) + ROW_NUMBER để sinh surrogate key ở dòng [7] (Issue log #4); không dùng APPLY CHANGES ... SCD TYPE 2 và cũng không có cột effective_date/end_date/current_flag để tự quản hiệu lực`

**Ví dụ PASS**

```sql
APPLY CHANGES INTO cb_ou_dim_scd
FROM STREAM(stg_ou_changes) KEYS (ou_hashkey)
SEQUENCE BY source_event_date STORED AS SCD TYPE 2;
```

---

### 2.7 — `CASE WHEN` cover đủ nhánh như job on-prem

**Cột N** · MANUAL · **Code** [rules.py:355](../engine/rules.py#L355)

**Đọc** — AST: tổng số node `CASE`, và số `CASE` không có nhánh `ELSE`.

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Script không có `CASE` nào | `N-A` |
| Có `CASE` | `MANUAL` — luôn cần người, vì so từng nhánh phải mở job on-prem |

Bằng chứng máy ghi: `có 7 CASE, trong đó 3 CASE không có nhánh ELSE (trả NULL âm thầm)` +
`máy không đọc được job on-prem nên không so được từng nhánh WHEN`.

**Việc của người review** — mở DataStage DSX / SQL cũ tương ứng, so từng `WHEN` và nhánh `ELSE`.
`CASE` thiếu `ELSE` trả `NULL`: xác nhận đó là ý muốn hay là thiếu nhánh.

---

### 2.8 — Cột `SUM`/`COUNT` được `COALESCE`/`NVL` hợp lý

**Cột O** · MANUAL · **Code** [rules.py:370](../engine/rules.py#L370)

**Đọc** — mọi node `SUM` / `COUNT` (bỏ qua `COUNT(*)`). Một biểu thức được coi là **đã xử lý
NULL** nếu:
1. bên trong đã có `COALESCE`/`NVL`/`IFNULL`; hoặc
2. node cha là `COALESCE`; hoặc
3. alias của nó được `COALESCE` ở lớp ngoài (regex `COALESCE(<alias>`).

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Mọi `SUM`/`COUNT` đều đã coalesce | `PASS` |
| Còn biểu thức chưa coalesce | `MANUAL` — **không tự Fail** |

**Vì sao không tự Fail**: giữ nguyên logic code cũ (không bọc) là hợp lệ khi on-prem cũng không
bọc. Điều bắt buộc là khi đối soát số liệu với hệ thống cũ phải bọc `NVL` / `ISNULL` **cả hai
phía** để không lệch khi trừ.

**Ví dụ ra `MANUAL`**

```sql
SELECT SUM(b.balance) AS BAL_AMT_LCY, COUNT(a.ar_id) AS AR_CNT
```

> `2 biểu thức tổng hợp chưa coalesce: AR_CNT = COUNT(a.ar_id); BAL_AMT_LCY = SUM(b.balance)`

**Ví dụ `PASS`**

```sql
SELECT COALESCE(SUM(b.balance), 0) AS BAL_AMT_LCY
```

---

### 2.9 — Subquery / function / `LIKE` đúng nghĩa nghiệp vụ

**Cột P** · MANUAL · **Code** [rules.py:397](../engine/rules.py#L397)

**Đọc** — mọi node `LIKE`, và số subquery nằm trong điều kiện.

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Không có `LIKE` lẫn scalar subquery | `N-A` |
| Có | `MANUAL` — `máy chỉ kiểm được cú pháp, không kiểm được ý nghĩa nghiệp vụ` |

Máy liệt kê nguyên văn tối đa 4 điều kiện `LIKE` để người review soi nhanh — chú ý dấu `%` ở
đầu/cuối và phân biệt hoa thường.

---

### 2.10 — Aggregation kèm filter kỳ dữ liệu

**Cột Q** · WARN · **Code** [rules.py:412](../engine/rules.py#L412)

**Đọc** — mọi `SELECT` có aggregate (`SUM`/`COUNT`/`AVG`/`MIN`/`MAX`) **hoặc** có `GROUP BY`.
Khối đó coi là **đã filter theo kỳ** nếu ở bất kỳ lớp bao quanh nào có điều kiện chứa:
- tham số (`:DATADT`); hoặc
- cột khớp `DT_ID | DATA_DATE | DATE | _DT$ | MSR_PRD | source_event_date | YR_ID | MO_ID`; hoặc
- nó đọc từ **CTE đã filter sẵn** (truy xuống tối đa 2 tầng).

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Mọi khối tổng hợp đều có điều kiện theo kỳ | `PASS` |
| Còn khối không thấy filter | `WARN` + tên CTE / bảng của khối đó |

**Ví dụ WARN**

```sql
tong AS (SELECT ou_cd, SUM(amt) amt FROM ...tb_txn GROUP BY ou_cd)   -- không có điều kiện ngày
```

> `1 khối tổng hợp không thấy filter theo ngày/tham số: tong`

**Ví dụ PASS** — filter nằm ở CTE nguồn cũng được tính (máy truy xuống 2 tầng):

```sql
txn AS (SELECT * FROM ...tb_txn WHERE cdr_dt_id = CAST(:DATADT AS INT)),
tong AS (SELECT ou_cd, SUM(amt) amt FROM txn GROUP BY ou_cd)
```

---

### 2.11 — Join đúng key, không lạm dụng `UNION ALL` + `EXISTS`

**Cột R** · WARN · **Code** [rules.py:469](../engine/rules.py#L469)

**Đọc** — (a) file có đồng thời `UNION` và `EXISTS`; (b) JOIN không có mệnh đề `ON` (mà không
phải `CROSS JOIN`, không dùng `USING`), hoặc `ON` không chứa phép `=` nào.

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Có (a) hoặc (b) | `WARN` |
| Không | `PASS` |

**Ví dụ WARN**

```sql
LEFT JOIN cal c ON c.dt_id BETWEEN a.from_dt AND a.to_dt      -- không có điều kiện bằng
```

> `join không có điều kiện bằng (=): ['c']`

---

### 2.12 — Build Gold từ CTE snapshot Silver

**Cột S** · AUTO · `SILVER_CONSUMER`, `GOLD_DERIVED` · **Code** [rules.py:490](../engine/rules.py#L490)

**Đọc** — với mỗi tên bảng đầy đủ (`catalog.schema.table`, trừ CTE và trừ chính bảng đích), đếm
**số khối `SELECT` khác nhau** có đọc nó — không đếm số lần tên xuất hiện.

**Luật** — phân biệt theo mức thiệt hại:

| Điều kiện | Trạng thái | Vì sao |
|---|---|---|
| Bảng `*.raw_vault.*` bị đọc ở > 1 khối SELECT | `FAIL` | Hub/sat/link có lịch sử → hai khối có filter riêng, dễ lệch thời điểm dữ liệu trong cùng script |
| Bảng khác (calendar, dim nhỏ) bị đọc ở > 1 khối SELECT | `WARN` | Chỉ kém tối ưu, không sai kết quả |
| Mỗi bảng chỉ đọc trong 1 khối SELECT | `PASS` | |

**Self-join không bị tính là đọc nhiều lần.** Hai alias của cùng một bảng trong **cùng một**
`SELECT` đọc cùng một snapshot — không có gì để lệch:

```sql
-- 2.12 PASS: D và W là self-join trong 1 khối SELECT
FROM      IDENTIFIER(:cleaned || '.business_vault.calendar') D
LEFT JOIN IDENTIFIER(:cleaned || '.business_vault.calendar') W ON D.msr_prd_id > W.msr_prd_id
```

**Ví dụ WARN thật** — cùng một bảng đọc ở **hai CTE khác nhau** (`working_day.sql`):

```sql
WITH v_from_dt AS (SELECT ... FROM ...business_vault.calendar D LEFT JOIN ...calendar B ...),
     v_end_dt  AS (SELECT ... FROM ...business_vault.calendar D LEFT JOIN ...calendar E ...)
```

> `bảng bị đọc lại ở nhiều khối SELECT, xét gom thành 1 CTE: calendar ở 2 khối`

**Cách sửa**: snapshot vào một CTE ở đầu script rồi dùng lại ở cả hai chỗ.

---

### 3.1 — Không `SELECT *`

**Cột T** · AUTO · **Code** [rules.py:516](../engine/rules.py#L516)

**Đọc** — danh sách biểu thức của **mọi** `SELECT` (kể cả trong CTE trung gian), tìm node `Star`
hoặc `alias.*`.

**Luật** — có ≥ 1 → `FAIL` (kèm số dòng); không có → `PASS`. **Không có ngoại lệ hợp lệ**, nên
máy tự kết luận.

**Ví dụ FAIL**

```sql
txn AS (SELECT * FROM ocb_datavault_dev_curated.tckh.tb_txn WHERE cdr_dt_id = :DATADT)
```

> `có 1 lần SELECT * ở dòng [4]`

---

### 3.2 — CTE không bị scan lại nhiều lần

**Cột U** · WARN · **Code** [rules.py:529](../engine/rules.py#L529)

**Đọc** — với mỗi CTE **có đọc bảng thật** (CTE chỉ chứa tham số thì bỏ qua vì scan lại không
tốn kém), đếm số lần tên nó xuất hiện trong text gốc rồi trừ 1 lần định nghĩa.

**Luật** — CTE nào bị tham chiếu lại ≥ 2 lần → `WARN` + số đo; không có → `PASS`.

**Vì sao chỉ WARN**: "bao nhiêu lần là nhiều" tùy CTE nặng hay nhẹ. Máy in số đo, người quyết
trong vài giây:

> `CTE bị tham chiếu lại nhiều lần: forex x4, cal_prev x4`

`cal_prev x4` là CTE một dòng → tick `Pass`. `forex x4` là CTE join 8 bảng Silver → nên gom lại,
để `Fail`.

---

### 3.3 — Filter trước khi join, tận dụng partition pruning

**Cột V** · WARN · `SILVER_CONSUMER`, `GOLD_DERIVED` · **Code** [rules.py:551](../engine/rules.py#L551)

**Đọc** — mỗi JOIN vào một **bảng thật** (subquery và CTE bỏ qua vì đã có filter riêng). Máy quét
**cả `WHERE` của SELECT chứa JOIN, và cả `ON` của chính JOIN đó**, tìm **điều kiện lọc riêng** cho
alias của bảng.

"Điều kiện lọc riêng" = biểu thức so sánh mà alias đó là bảng **duy nhất** xuất hiện:

| Biểu thức | Có tính là filter riêng cho `W`? | Vì sao |
|---|---|---|
| `W.bsn_day_f = 1` | **có** | chỉ có `W`, so với hằng số → prune được partition |
| `D.msr_prd_id > W.msr_prd_id` | không | có 2 bảng → đây là điều kiện JOIN, không prune được |
| `W.dt <= :DATADT` | **có** | so với tham số |

**Luật** — bảng nào không có điều kiện riêng ở cả `WHERE` lẫn `ON` → `WARN` + danh sách; không có
→ `PASS`.

**Vì sao phải quét cả `ON`**: với `LEFT JOIN`, điều kiện lọc bảng phải **bắt buộc** nằm trong `ON`
— chuyển ra `WHERE` sẽ biến nó thành `INNER JOIN` và mất dòng. Spark vẫn đẩy được predicate trong
`ON` xuống scan để prune partition, nên đặt ở `ON` là **đúng**, không phải thiếu filter:

```sql
-- 3.3 PASS: filter riêng của W nằm trong ON, đúng chỗ cho LEFT JOIN
LEFT JOIN IDENTIFIER(:cleaned || '.business_vault.calendar') W
       ON  D.msr_prd_id > W.msr_prd_id      -- điều kiện join
       AND W.bsn_day_f = 1                  -- filter riêng của W
```

**Ví dụ WARN**

```sql
LEFT JOIN ocb_datavault_dev_curated.tckh.cb_ou_dim d ON d.ou_cd = a.ou_cd   -- không lọc gì cho d
```

> `1 bảng join trực tiếp mà không có filter riêng: cb_ou_dim (d)`

**Vì sao chỉ WARN**: bảng dim nhỏ không partition thì không cần filter trước — tick `Pass`.

---

### 3.4 — Dùng `CACHE` cho query lặp lại trong cùng luồng

**Cột W** · WARN · **Code** [rules.py:574](../engine/rules.py#L574)

**Đọc** — cùng số đo CTE dùng lại của 3.2, cộng regex `CACHE TABLE` / `CACHE SELECT`.

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Không có CTE nào dùng lại ≥ 2 lần | `N-A` — chưa cần CACHE |
| Có, và trong file có `CACHE` | `PASS` |
| Có, không có `CACHE` | `WARN` |

**Vì sao chỉ WARN**: cache một kết quả nhỏ còn chậm hơn không cache.

---

### 3.5 — Ưu tiên `MAX_BY` thay `ROW_NUMBER() + WHERE rn = 1`

**Cột X** · AUTO · **Căn cứ** Issue log #5 (pattern đã chốt) · **Code** [rules.py:584](../engine/rules.py#L584)

**Đọc** — regex `ROW_NUMBER`, `MAX_BY(`, và dạng chọn dòng mới nhất
(`ROW_NUMBER…) = 1` hoặc `rn|rnk|row_num = 1`).

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Script không dùng `ROW_NUMBER` | `N-A` |
| Có dùng `MAX_BY` | `PASS` |
| Có `ROW_NUMBER` nhưng **không** phải dạng lấy dòng mới nhất (ví dụ đánh số thứ tự báo cáo) | `WARN` — cần xác nhận |
| Lấy dòng mới nhất bằng `ROW_NUMBER … = 1` | `FAIL` |

**Ví dụ FAIL**

```sql
SELECT hk, nm FROM (
  SELECT hk, nm, ROW_NUMBER() OVER (PARTITION BY hk ORDER BY source_event_date DESC) rn
  FROM ... sat_customer) WHERE rn = 1
```

> `lấy bản ghi mới nhất bằng ROW_NUMBER = 1 ở dòng [3], pattern chuẩn đã chốt là MAX_BY (Issue log #5)`

**Ví dụ PASS**

```sql
SELECT hk, max_by(nm, source_event_date) nm FROM ... sat_customer GROUP BY hk
```

Nếu buộc phải lấy nhiều cột của **cùng một dòng** mới nhất thì dùng
`QUALIFY ROW_NUMBER() … = 1` và ghi comment giải thích (khi đó 3.6 mới `PASS`).

---

### 3.6 — Không lạm dụng window function; có comment khi dùng

**Cột Y** · WARN · **Code** [rules.py:597](../engine/rules.py#L597)

**Đọc** — các dòng chứa `OVER (`. Với mỗi dòng đó, máy lùi lên tìm dòng mở đầu CTE chứa nó
(`^ ,? <tên> AS (`) rồi kiểm tra trong khoảng *(đầu CTE − 3 dòng) → dòng window* có ký tự `--`
nào không.

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Không có window function | `N-A` |
| Có window function không có comment nào trong khối của nó | `WARN` + số dòng |
| Mọi window function đều có comment | `PASS` |

**Ví dụ WARN → PASS** — chỉ cần một comment ngay trên khối:

```sql
-- lấy 1 dòng mới nhất của sat: cần đồng thời nm + addr nên không dùng được max_by
, cst AS (
    SELECT hk, nm, addr FROM ... sat_customer
    QUALIFY ROW_NUMBER() OVER (PARTITION BY hk ORDER BY source_event_date DESC) = 1
)
```

---

### X.1 — Link phải rút về current trước khi join (chống fan-out)

Nhóm X · AUTO · chỉ `SILVER_CONSUMER` · **Căn cứ** Technical Document III.4.2.3 ·
**Code** [rules.py:624](../engine/rules.py#L624)

**Đọc** — mỗi JOIN vào bảng `link_*`: xét `SELECT` chứa nó có `GROUP BY` kèm `max_by(`, hoặc có
`DISTINCT`, hoặc có `QUALIFY` không.

**Luật** — không có dấu hiệu rút current nào → `FAIL` (nhân đôi số dòng); có → `PASS`.

**Ví dụ FAIL**

```sql
LEFT JOIN ocb_dv_cleaned.raw_vault.link_account_customer lc
       ON lc.account_hashkey = a.account_hashkey     -- link thô: 1 account nhiều dòng lịch sử
```

> `1 bảng link_* join trực tiếp mà chưa rút về current, sẽ nhân đôi số dòng: link_account_customer (dong 22)`

**Ví dụ PASS** — rút về 1 dòng / driving key trước:

```sql
lc_cur AS (
    SELECT account_hashkey, max_by(customer_hashkey, source_event_date) customer_hashkey
    FROM   ocb_dv_cleaned.raw_vault.link_account_customer
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP  BY account_hashkey
)
```

Quan hệ M:N thì khử trùng ở mức `link_hashkey`, **không** partition theo một phía.

---

### X.2 — Catalog/schema nhất quán theo môi trường

Nhóm X · AUTO · **Code** [rules.py:749](../engine/rules.py#L749)

**Đọc** — regex `ocb_datavault_([a-z0-9]+)_` trên text gốc → tập tên môi trường.

**Luật** — ≥ 2 môi trường trong cùng 1 file → `FAIL`; còn lại → `PASS`.

**Ví dụ FAIL**

```sql
FROM ocb_datavault_dev_cleaned.raw_vault.hub_customer h
JOIN ocb_datavault_pilotcloud_curated.tckh.cb_ou_dim d ON ...
```

> `trộn 2 môi trường trong cùng 1 file: ['dev', 'pilotcloud'], sẽ chạy sai môi trường`

---

### X.3 — `INSERT INTO` phải liệt kê cột khớp DDL

Nhóm X · AUTO · **Code** [rules.py:757](../engine/rules.py#L757)

**Đọc** — mọi câu `INSERT`; kiểm tra có danh sách cột hay không.

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| File không có `INSERT` (là view hoặc `CREATE TABLE AS`) | `N-A` |
| Có `INSERT` không liệt kê cột | `FAIL` |
| Mọi `INSERT` đều liệt kê cột | `PASS` |

**Ví dụ FAIL** → `INSERT INTO ...FTP_FACT SELECT ...` — thêm một cột vào DDL là toàn bộ dữ liệu
lệch cột mà **không có lỗi nào báo ra**.

---

### X.4 — Idempotent: có `DELETE`/`TRUNCATE` khớp khóa trước `INSERT`

Nhóm X · AUTO · **Code** [rules.py:768](../engine/rules.py#L768)

**Đọc** — các câu `INSERT`, `DELETE` (kèm `WHERE`), và regex `TRUNCATE` / `OVERWRITE`.

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Không có `INSERT` | `N-A` |
| Có `INSERT` mà không có `DELETE` lẫn `TRUNCATE`/`OVERWRITE` | `FAIL` — chạy lại lần 2 nhân đôi dữ liệu |
| Có `DELETE` nhưng khóa trong `WHERE` không nằm trong danh sách cột output | `WARN` — cần xác nhận xóa đúng phạm vi |
| Còn lại | `PASS` |

**Chú ý nghiệp vụ**: khóa `DELETE` phải là khóa thực sự phân vùng dữ liệu — ví dụ `RT_PL_DTL_ADJ`
đổi `CDR_DT_ID` nên phải `DELETE` theo `PST_ENTR_DT`.

---

### X.5 — Join key NULL-safe

Nhóm X · WARN · **Code** [rules.py:789](../engine/rules.py#L789)

**Đọc** — tập cột từng được bọc `NVL`/`COALESCE`/`IFNULL` **ở bất kỳ đâu trong file** (dấu hiệu
DE biết cột đó nullable). Sau đó xét mọi `ON … =`: cột thuộc tập đó mà biểu thức so sánh không có
`NVL`/`COALESCE`/`IFNULL`/`<=>`.

**Luật** — có → `WARN`; không → `PASS`.

**Ví dụ WARN**

```sql
SELECT NVL(a.cst_id, -1) AS CST_ID          -- chỗ này biết cst_id nullable
FROM   ... a
LEFT   JOIN ... c ON c.cst_id = a.cst_id    -- chỗ này lại join thẳng -> NULL = NULL là FALSE
```

> `cột được NVL ở chỗ khác nhưng join lại không NULL-safe: ['cst_id @ c']`

---

### X.6 — Satellite phải `LEFT JOIN`, không `INNER JOIN`

Nhóm X · AUTO · chỉ `SILVER_CONSUMER` · **Căn cứ** Technical Document III.4.2.2 nguyên tắc 1 ·
**Code** [rules.py:650](../engine/rules.py#L650)

**Đọc** — kiểu JOIN của mọi bảng `sat_*`.

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Có `sat_*` dùng INNER JOIN (không phải LEFT/RIGHT/FULL/CROSS) | `FAIL` |
| Script không join satellite trực tiếp | `N-A` |
| Mọi satellite đều LEFT JOIN | `PASS` |

**Vì sao FAIL cứng**: `INNER JOIN` satellite làm **mất** bản ghi Hub đang còn hiệu lực nhưng chưa
có dòng satellite — làm giàu thuộc tính luôn phải `LEFT JOIN`.

---

### X.7 — Không hard-code catalog, dùng biến môi trường

Nhóm X · WARN · `SILVER_CONSUMER`, `GOLD_DERIVED` · **Code** [rules.py:737](../engine/rules.py#L737)

**Đọc** — regex `ocb_datavault_[a-z0-9]+_(cleaned|curated)` (catalog cứng), và
`IDENTIFIER(` / `${cleaned_catalog}` / `${curated_catalog}` (biến môi trường).

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Không có catalog cứng | `PASS` |
| Có cả catalog cứng **và** biến môi trường | `WARN` — dùng lẫn |
| Chỉ có catalog cứng | `WARN` — deploy môi trường khác phải sửa tay từng file |

**Ví dụ PASS**

```sql
FROM IDENTIFIER(:cleaned || '.raw_vault.sat_customer') s
```

---

### X.8 — `JOIN SCHEMA` trong thiết kế khớp bảng nguồn trong SQL

Nhóm X · AUTO · **Code** [rules.py:703](../engine/rules.py#L703)

**Đọc** — block `JOIN SCHEMA` của workbook thiết kế, so hai chiều với tên bảng trong SQL.

Xử lý các biến thể ghi trong thiết kế:
- một dòng ghi nhiều bảng (`LINK_X + HUB_Y`) → tách theo `+ , /`;
- dòng ghi **cả đoạn SQL inline** (dài > 60 ký tự, hoặc chứa `SELECT`/`WITH`) → không đối chiếu
  được theo dòng, nhưng máy **bóc tên bảng ra khỏi đoạn SQL đó** (lấy tên sau `FROM`/`JOIN`,
  hiểu cả `IDENTIFIER(:cleaned || '.schema.table')`) rồi coi là đã khai báo — nếu không sẽ báo
  oan "SQL đọc bảng mà JOIN SCHEMA không khai báo";
- so theo tên ngắn (bỏ `catalog.schema`), không phân biệt hoa thường.

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Workbook không có block `JOIN SCHEMA` | `N-A` |
| Bảng khai trong thiết kế mà **không** thấy trong SQL | `FAIL` — thiết kế và code đi hai đường |
| SQL đọc bảng mà thiết kế **không** khai (trừ `PIT_*` và chính bảng đích) | `WARN` |
| Khớp hai chiều | `PASS` |

**Ví dụ WARN** (thực tế trong batch hiện tại)

> `SQL đọc 1 bảng mà JOIN SCHEMA không khai báo: ['CALENDAR']`

---

### X.9 — Mọi bảng phải dev lại từ Silver

Nhóm X · AUTO · **Căn cứ** quy định đã chốt · **Code** [rules.py:673](../engine/rules.py#L673)

**Đọc** — ba nguồn:
1. bảng `*.raw_vault.*` / `*.business_vault.*` mà file đọc trực tiếp;
2. **chuỗi truy nguồn toàn batch** (`repo["silver_chain"]`, [run_check.py](../run_check.py)
   `_silver_chain`): object nào đọc Silver trực tiếp thì `True`, object nào đọc một object đã
   `True` cũng thành `True`, lặp lan truyền (ví dụ `v_cdtk_daily → holiday → calendar`).
   Object mà **mọi** nguồn đều là bảng upload đã khai báo cũng thành `True`, để cả chuỗi phía
   sau không bị báo lây (`tb_cdkt_daily_dtl` upload → `v_cdtk_daily_1` đạt → `v_cdtk_daily` đạt);
3. **cột `NOTE` của block `JOIN SCHEMA`** trong workbook — nơi khai báo bảng upload/thủ công.

**Ngoại lệ bảng upload/thủ công.** Bảng có DDL + data nạp tay (CSV) **là nguồn hợp lệ**, không
phải lỗi. Nhưng máy không tự phân biệt được "bảng upload đúng thiết kế" với "quên dev từ Silver",
nên phải **khai rõ ở cột `NOTE`** của dòng JOIN SCHEMA tương ứng. Nhận các từ khoá:
`upload`, `thủ công` / `thu cong`, `manual`, `nhập tay`, `không qua ETL/Silver`.

```
JOIN SCHEMA — V_CDTK_DAILY_1
 # | Table / View        | Alias | JOIN Type | ON | NOTE
 1 | TB_CDKT_DAILY_DTL   | u     | BASE      |    | TABLE upload thu cong (khong qua ETL/Silver)
                                                    ↑ khai ở đây thì X.9 chấp nhận là nguồn hợp lệ
```

**Luật**

| Điều kiện | Trạng thái |
|---|---|
| Đọc trực tiếp Silver | `PASS` |
| Script không đọc bảng nguồn nào (file chỉ có DDL) | `N-A` |
| Mọi nguồn đều truy được về Silver, **hoặc** là bảng upload đã khai ở `NOTE` | `PASS` |
| Nguồn **có trong lượt chạy** mà không truy được, nhưng có nguồn khác truy được / có upload đã khai | `WARN` |
| Nguồn **có trong lượt chạy** mà không truy được, không có gì truy được | `FAIL` |
| Nguồn **không có trong lượt chạy** (chưa chấm object đó) | `MANUAL` |

> **Phân biệt "không truy được" với "chưa chấm".** Máy chỉ truy được chuỗi qua các object *có mặt
> trong lượt chạy*. Chấm ở chế độ Excel mà workbook chưa khai `HOLIDAY` / `WORKING_DAY` thì
> `V_CDTK_DAILY` đọc 2 bảng đó sẽ không có gì để truy — đó là **thiếu dữ liệu**, không phải lỗi
> code, nên ghi `MANUAL` chứ không `Fail`. Chấm cả các object đó cùng lượt là hết.

> **Bảng đích không bị tính là nguồn của chính nó.** File DDL viết tên trần
> (`CREATE TABLE tb_x`) trong khi máy bổ sung `catalog.schema` từ `USE CATALOG`/`USE SCHEMA` —
> so tên đầy đủ sẽ lệch. `core.same_object` xử lý việc này.

> Tiêu chí này cũng phụ thuộc toàn batch: chấm một file lẻ bằng `--file` sẽ không có chuỗi truy
> nguồn nên dễ ra `FAIL` oan. Chấm cả `input/sql/` mới đúng.

---

## 3. Tự kiểm chứng luật chấm

Chấm bằng rule chưa kiểm chứng thì kết quả vô nghĩa, nên `run_check.py` **chạy self-test trước**
mỗi lần chấm:

```bash
python tools/gold_review/tests/test_rules.py
```

- `tests/fixtures/bad_fct.sql` — cố tình sai 12 tiêu chí, kỳ vọng đúng 12 `FAIL`
- `tests/fixtures/good_fct.sql` — viết đúng pattern tài liệu, kỳ vọng `PASS` / `N-A`
- `tests/fixtures/cb_ou_dim.sql` — `MAX(ID)+ROW_NUMBER`, kỳ vọng 2.6 `FAIL`
- `tests/fixtures/holiday_fx.sql` — self-join + filter trong `ON`, kỳ vọng 2.12 và 3.3
  `PASS` (chống **báo lỗi oan**)
- `tests/fixtures/bad_two_cte.sql` — cùng bảng `raw_vault` đọc ở 2 CTE, kỳ vọng 2.12 `FAIL`
- `tests/fixtures/name_mismatch.sql` — tên object trong `CREATE` khác tên file, kỳ vọng 1.2 `FAIL`
- `tests/fixtures/v_unknown_src.sql` — đọc bảng không có trong lượt chạy, kỳ vọng X.9 `MANUAL`
- `tests/fixtures/upl_fct.sql` — đọc bảng upload đã khai ở `NOTE`, kỳ vọng X.9 và X.8 `PASS`
- `tests/fixtures/ddl_only_table.sql` — file chỉ có DDL, kỳ vọng X.9 `N-A` (bảng đích không phải
  nguồn của chính nó)

Kỳ vọng khai ở `EXPECT` trong [tests/test_rules.py](../tests/test_rules.py). Self-test trượt →
`run_check.py` trả **exit code 3** và in cảnh báo: sửa rule trước, đừng tin kết quả chấm.

**Sửa hoặc thêm một tiêu chí** → bắt buộc thêm case tương ứng vào `tests/fixtures/` + `EXPECT`,
rồi chạy lại self-test.
