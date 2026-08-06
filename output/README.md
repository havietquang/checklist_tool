# output/ — kết quả do tool sinh ra

**Không sửa tay các file ở đây** — mỗi lần chạy `run_check.py` là ghi đè lại toàn bộ.
Muốn giữ một bản để gửi thì copy ra chỗ khác trước.

| File | Nội dung |
|---|---|
| `Checklist_Review_AUTOFILLED.xlsx` | **File chính để xem và gửi OCB** |
| `recon/<TÊN_OBJECT>_recon.sql` | Cặp SQL đối chiếu số liệu cho tiêu chí 1.3 — chạy tay |

---

## Checklist_Review_AUTOFILLED.xlsx

Bản copy của file checklist trong `input/checklist/`, đã điền sẵn. Gồm 5 sheet:

| Sheet | Xem gì |
|---|---|
| **Review theo bảng** | Sheet chính. Mỗi object 1 dòng từ **dòng 4** (dòng 3 là ví dụ của OCB, giữ nguyên) |
| **Auto-check chi tiết** | Sheet tool tự thêm. Mỗi dòng = 1 object × 1 tiêu chí, đầy đủ bằng chứng + cách sửa |
| Tổng hợp Dashboard | Tự cộng số bảng Đạt/Không đạt theo Batch (công thức của OCB) |
| Hướng dẫn / Checklist tiêu chí | Nội dung gốc của OCB, không đổi |

### Sheet "Review theo bảng" — đọc thế nào

| Cột | Nội dung |
|---|---|
| `B` | Tên object Gold |
| `C` `D` `E` | Batch / PIC / Ngày review |
| `F`–`H` | Nhóm 1 Mapping (1.1, 1.3, 1.4) |
| `I`–`T` | Nhóm 2 Logic (2.1 → 2.12) |
| `U`–`Z` | Nhóm 3 Optimization (3.1 → 3.6) |
| `AA`–`AF` | Tỷ lệ lỗi + Kết luận — **công thức của OCB, tự tính khi mở Excel** |
| `AG` | **Ghi chú / Bằng chứng lỗi** — note chi tiết |

Các ô tiêu chí chỉ có **2 giá trị**:

| Giá trị | Ô | Nghĩa |
|---|---|---|
| `Pass` | trắng | Đạt, hoặc tiêu chí không áp dụng cho object này |
| `Pass` | (liệt kê ở cột Ghi chú) | **Chưa có số liệu** — sẽ có sau UAT test, đang ghi Pass tạm. Cập nhật lại ô sau khi có số |
| `Fail` | trắng | Không đạt, hoặc có dấu hiệu nghi vấn cần giải trình |

Nhóm `X.*` (bổ sung Raffles) không có cột riêng để không phá công thức của OCB — kết quả ghi
vào cột `AG` và sheet chi tiết.

### Cột AG — 3 khối

```
╔══ FAIL: 2 tiêu chí — 2.12, X.8

▼ 2.12 — Build Gold từ CTE snapshot Silver, không build nhiều tầng chồng chéo
   • Lý do: bảng bị đọc lại nhiều lần, xét gom thành 1 CTE: calendar x4
   → Cách sửa: Mỗi bảng Silver chỉ đọc MỘT lần, snapshot vào một CTE ở đầu script...

╔══ CHƯA CÓ SỐ LIỆU: 1 tiêu chí — 1.3
    (chưa có con số để kết luận, sẽ có sau khi UAT test; đang ghi tạm Pass)
▼ 1.3 — Đối chiếu tổng số dòng và tổng SUM cột số với hệ thống cũ
   • Hiện trạng: thực hiện ở bước UAT test

╔══ KHÔNG ÁP DỤNG (ghi Pass): 2.1, 2.2, 2.4, ...
   • 2.1 — Chỉ lấy bản ghi active...: không áp dụng cho profile GOLD_DERIVED
```

Mỗi tiêu chí Fail đều có **tên tiêu chí → lý do kèm số dòng code → cách sửa**.

## recon/ — SQL đối chiếu (tiêu chí 1.3)

Mỗi object 1 file, gồm 2 câu đã bọc `NVL` / `ISNULL` sẵn 2 phía:

```sql
-- [1] GOLD mới - Databricks SQL
SELECT COUNT(*) AS ROW_CNT, SUM(NVL(YR_AMT_LCY,0)) AS SUM_YR_AMT_LCY
FROM ocb_datavault_dev_curated.tckh.PL_CUST_RM_FCT WHERE CDR_DT_ID = :DATADT;

-- [2] HỆ THỐNG CŨ - MSSQL on-prem
SELECT COUNT(*) AS ROW_CNT, SUM(ISNULL(YR_AMT_LCY,0)) AS SUM_YR_AMT_LCY
FROM dbo.PL_CUST_RM_FCT WHERE CDR_DT_ID = @DATADT;
```

Chạy 2 câu cho cùng kỳ dữ liệu, dán kết quả vào ô `AG` của object đó. Lệch phải giải trình được.
