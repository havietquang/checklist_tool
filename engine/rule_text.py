# -*- coding: utf-8 -*-
"""Tiêu đề tiếng Việt + hướng dẫn sửa cho từng tiêu chí, dùng để ghi note vào Excel.

Mỗi mã tiêu chí -> (tên tiêu chí, cách sửa). Note trong cột "Ghi chú / Bằng chứng lỗi"
được ghép từ: tên tiêu chí + bằng chứng máy tìm được (kèm số dòng) + cách sửa.
"""

TEXT = {
    # ---------------------------------------------------------- Nhóm 1 – Mapping
    "1.1": (
        "Đầy đủ mapping từ Silver/manual sang Gold",
        "Mở workbook thiết kế, đối chiếu block FIELD MAPPING với danh sách cột trong câu "
        "SELECT/INSERT của file SQL. Cột nào thiếu thì bổ sung vào SQL; cột nào SQL có mà "
        "thiết kế không có thì bổ sung vào workbook hoặc bỏ khỏi SQL.",
    ),
    # 1.3 (doi soat so dong & SUM voi he thong cu) DA BO khoi pham vi tu cham - chi
    # lam duoc khi co du lieu that o buoc UAT test, khong suy tu code duoc.
    "1.2": (
        "Danh sách bảng/view Gold khớp tài liệu thiết kế đã duyệt",
        "Đảm bảo object có workbook thiết kế tương ứng trong thư mục --mapping-dir. "
        "Muốn đối chiếu với danh sách đã duyệt thì chạy thêm tham số "
        '--gold-list "<file danh sách Gold>.xlsx".',
    ),

    # ---------------------------------------------------------- Nhóm 2 – Logic
    "2.1": (
        "Chỉ lấy bản ghi active, loại bản ghi đã xóa (qua sts_hub)",
        "Theo Technical Document mục III.4.2.1: với mỗi hub_<ent> phải thêm 2 CTE — "
        "(1) <ent>_sts_del đọc sts_hub_<ent>, GROUP BY hashkey, "
        "HAVING max_by(cdc_status, source_event_date) = 'D'; "
        "(2) <ent>_active đọc hub_<ent> LEFT JOIN <ent>_sts_del rồi lọc "
        "d.<hashkey> IS NULL. Tuyệt đối KHÔNG lọc cdc_status trong satellite — "
        "trạng thái xóa chỉ lọc ở sts_hub.",
    ),
    "2.2": (
        "Thống nhất MỘT pattern duy nhất xác định bản ghi active mới nhất",
        "Toàn bộ script trong batch phải dùng cùng một cách lấy bản ghi mới nhất: "
        "max_by(<cột>, source_event_date) + GROUP BY hashkey. Không để file này dùng "
        "ROW_NUMBER, file kia dùng max_by. Hướng lọc cdc_status cũng phải nhất quán "
        "(luôn là loại 'D', không có chỗ nào giữ 'D').",
    ),
    "2.3": (
        "Điều kiện lọc trạng thái đặt SAU khi xác định bản ghi mới nhất",
        "Chuyển các điều kiện cdc_status / rn = 1 ra khỏi phần ON của LEFT JOIN, đưa vào "
        "WHERE hoặc QUALIFY của chính subquery/CTE lấy dữ liệu. Đặt trong ON của LEFT JOIN "
        "thì khi không match sẽ ra NULL âm thầm, sai kết quả (Issue log #3). "
        "Riêng pattern PIT (sat.source_event_date = p.<sat>_src_ev_dt) và 49 bảng "
        "transaction được phép đặt trong ON.",
    ),
    "2.4": (
        "source_event_date áp dụng đúng dạng theo loại bảng",
        "Bảng thường: WHERE source_event_date <= TO_DATE(:DATADT,'yyyyMMdd') và KHÔNG đặt "
        "cận dưới (>= start_date) vì sẽ bỏ sót bản ghi mới nhất nằm trước khoảng thời gian. "
        "Riêng 49 bảng transaction ở mục 'Các trường hợp đặc biệt' của Technical Document "
        "(sat_stmt_entry_*, sat_categ_entry_*, sat_account_balance, sat_funds_transfer_*, "
        "sat_gl_trace_*, …) phải dùng source_event_date = :DATADT. "
        "Danh sách đầy đủ ở tools/gold_review/doc_standard.py.",
    ),
    "2.5": (
        "Không lặp lại lỗi logic cũ đã được DA Data Vault fix",
        "Sửa đúng các dòng được chỉ ra ở trên theo pattern chuẩn: lấy bản ghi mới nhất bằng "
        "max_by(<cột>, source_event_date) + GROUP BY hashkey; trạng thái xoá lọc ở sts_hub_* "
        "bằng HAVING max_by(cdc_status, source_event_date) = 'D' rồi anti-join IS NULL; "
        "không đặt cdc_status / rn = 1 trong ON hay trong subquery của JOIN; surrogate key "
        "DIM không sinh bằng MAX(<DIM_ID>) + ROW_NUMBER(). Danh sách lỗi lấy từ "
        "'ZoneC Mapping - Iss log.xlsx' sheet Issue; OCB trả lỗi mới thì thêm 1 regex vào "
        "tools/gold_review/engine/known_issues.json để lần sau tự bắt được.",
    ),
    "2.6": (
        "SCD Type 2 cho bảng DIM áp dụng đúng kỹ thuật đã thống nhất",
        "Dùng APPLY CHANGES INTO <bảng>_scd FROM STREAM(stg_<ent>_changes) KEYS (<hashkey>) "
        "SEQUENCE BY source_event_date STORED AS SCD TYPE 2 TRACK HISTORY ON (...) — "
        "Databricks tự quản __START_AT/__END_AT. Nếu tự quản thì phải có cột "
        "effective_date/end_date/current_flag. TUYỆT ĐỐI không sinh surrogate key bằng "
        "MAX(<DIM_ID>) + ROW_NUMBER() vì trùng khi chạy song song hoặc load lại lịch sử "
        "(Issue log #4).",
    ),
    "2.7": (
        "CASE WHEN cover đủ nhánh như job on-prem",
        "Mở job on-prem tương ứng (DataStage DSX hoặc SQL cũ), đối chiếu từng nhánh WHEN và "
        "cả nhánh ELSE. CASE không có ELSE sẽ trả NULL âm thầm — xác nhận đó là ý muốn hay "
        "thiếu nhánh.",
    ),
    "2.8": (
        "Cột SUM/COUNT được COALESCE/NVL hợp lý",
        "Bọc COALESCE(SUM(...), 0) cho các cột tổng hợp cần trả 0 khi không có dòng. "
        "Nếu code cũ không bọc thì giữ nguyên logic nhưng khi đối soát số liệu với hệ thống "
        "cũ phải bọc NVL/ISNULL ở CẢ HAI phía để không lệch khi trừ.",
    ),
    "2.9": (
        "Subquery / custom function / điều kiện LIKE đúng ý nghĩa nghiệp vụ",
        "Đọc lại từng điều kiện LIKE và từng subquery, đối chiếu ý nghĩa nghiệp vụ với "
        "on-prem — đúng cú pháp không đủ. Chú ý pattern LIKE có ký tự % ở đầu/cuối và "
        "phân biệt chữ hoa/thường.",
    ),
    "2.10": (
        "Aggregation kèm filter date range chính xác",
        "Mỗi khối SUM/COUNT/AVG phải có điều kiện lọc theo kỳ dữ liệu (CDR_DT_ID, DATA_DATE, "
        ":DATADT…). Nếu điều kiện nằm ở CTE nguồn thì ghi rõ trong comment để người review "
        "không phải truy ngược.",
    ),
    "2.11": (
        "Join dùng key hợp lý, không lạm dụng UNION ALL + EXISTS/NOT EXISTS",
        "Ưu tiên LEFT JOIN theo business key hoặc hashkey. Xem lại các chỗ dùng "
        "UNION ALL kết hợp EXISTS/NOT EXISTS — thường thay được bằng một LEFT JOIN. "
        "Join không có điều kiện bằng (=) dễ tạo tích Descartes.",
    ),
    "2.12": (
        "Build Gold từ CTE snapshot Silver, không build nhiều tầng chồng chéo",
        "Mỗi bảng Silver chỉ đọc MỘT lần, snapshot vào một CTE ở đầu script rồi dùng lại. "
        "Đọc trực tiếp cùng một bảng raw_vault ở 2 chỗ khác nhau làm lệch thời điểm dữ liệu "
        "giữa các phần của cùng một script.",
    ),

    # ---------------------------------------------------------- Nhóm 3 – Optimization
    "3.1": (
        "Không SELECT *",
        "Liệt kê tường minh các cột cần dùng, kể cả trong CTE trung gian. SELECT * làm tăng "
        "IO/memory và vỡ script khi bảng nguồn thêm cột.",
    ),
    "3.2": (
        "CTE không bị scan lại nhiều lần",
        "Với CTE nặng (đọc nhiều bảng Silver) bị tham chiếu từ 2 chỗ trở lên: gom lại còn "
        "một lần dùng, hoặc vật chất hóa (CACHE / bảng tạm). CTE nhẹ chỉ chứa tham số thì "
        "bỏ qua được — tự tick Pass.",
    ),
    "3.3": (
        "Filter trước khi join, tận dụng partition pruning",
        "Đưa điều kiện lọc (ngày dữ liệu, trạng thái) vào subquery của từng bảng TRƯỚC khi "
        "join, để tận dụng partition pruning. Bảng dim nhỏ không partition thì không cần — "
        "tự tick Pass.",
    ),
    "3.4": (
        "Sử dụng CACHE cho query lặp lại trong cùng luồng",
        "Nếu một kết quả nặng được dùng lại nhiều bước trong cùng luồng, thêm "
        "CACHE TABLE / CACHE SELECT. Kết quả nhỏ thì cache còn chậm hơn — tự tick Pass.",
    ),
    "3.5": (
        "Ưu tiên MAX_BY + QUALIFY thay ROW_NUMBER() + WHERE rn = 1",
        "Thay ROW_NUMBER() OVER (PARTITION BY hk ORDER BY source_event_date DESC) + "
        "WHERE rn = 1 bằng max_by(<cột>, source_event_date) + GROUP BY hk (Issue log #5). "
        "Nếu buộc phải lấy nhiều cột của CÙNG một dòng mới nhất thì dùng QUALIFY "
        "ROW_NUMBER() ... = 1 và ghi comment giải thích lý do.",
    ),
    "3.6": (
        "Không lạm dụng window function; có comment khi dùng",
        "Mỗi window function cần một comment ngay trên khối CTE chứa nó, nói rõ vì sao "
        "không dùng được max_by/QUALIFY đơn giản hơn.",
    ),

    # ---------------------------------------------------------- Nhóm X – bổ sung Raffles
    "X.1": (
        "[Bổ sung] Link phải rút về current trước khi join (chống fan-out)",
        "Theo Technical Document III.4.2.3: rút link về một dòng cho mỗi driving key trước "
        "khi join vào fact/dim — SELECT <driving_hk>, max_by(<target_hk>, source_event_date) "
        "FROM link_<x> WHERE source_event_date <= :DATADT GROUP BY <driving_hk>. "
        "Quan hệ M:N thì khử trùng ở mức link_hashkey, không partition theo một phía. "
        "Join link thô rồi SUM sẽ nhân đôi số tiền.",
    ),
    "X.2": (
        "[Bổ sung] Catalog/schema nhất quán theo môi trường",
        "Không trộn hai môi trường trong cùng một file (ví dụ vừa ocb_datavault_dev_* vừa "
        "ocb_datavault_pilotcloud_*). Chạy sai môi trường sẽ đọc/ghi sai dữ liệu.",
    ),
    "X.3": (
        "[Bổ sung] INSERT INTO phải liệt kê cột khớp DDL",
        "Viết INSERT INTO <bảng> (COT_1, COT_2, ...) SELECT ... Nếu không liệt kê cột, chỉ "
        "cần thêm một cột vào DDL là toàn bộ dữ liệu lệch cột mà không có lỗi nào báo ra.",
    ),
    "X.4": (
        "[Bổ sung] Idempotent: có DELETE/TRUNCATE khớp khóa trước INSERT",
        "Trước INSERT phải có DELETE theo đúng khóa kỳ dữ liệu (hoặc TRUNCATE / INSERT "
        "OVERWRITE) để chạy lại không nhân đôi dữ liệu. Chú ý khóa DELETE phải là khóa thực "
        "sự phân vùng dữ liệu — ví dụ RT_PL_DTL_ADJ đổi CDR_DT_ID nên phải DELETE theo "
        "PST_ENTR_DT.",
    ),
    "X.5": (
        "[Bổ sung] Join key NULL-safe",
        "Cột có thể NULL (CST_ID, OFCR_ID…) nếu join bằng dấu = sẽ mất dòng âm thầm vì "
        "NULL = NULL trả FALSE. Dùng NVL/COALESCE cả hai phía, hoặc toán tử NULL-safe <=>.",
    ),
    "X.6": (
        "[Bổ sung] Satellite phải LEFT JOIN, không INNER JOIN",
        "Technical Document III.4.2.2 nguyên tắc 1: làm giàu thuộc tính luôn dùng LEFT JOIN. "
        "INNER JOIN satellite sẽ loại mất bản ghi Hub đang còn hiệu lực nhưng chưa có dòng "
        "satellite.",
    ),
    "X.7": (
        "[Bổ sung] Không hard-code catalog, dùng biến môi trường",
        "Thay tên catalog cứng bằng IDENTIFIER(:cleaned || '.raw_vault.<bảng>') / "
        "IDENTIFIER(:curated || '.tckh.<bảng>'), hoặc ${cleaned_catalog} / "
        "${curated_catalog} trong Lakeflow Declarative Pipeline. Hard-code thì deploy sang "
        "môi trường khác phải sửa tay từng file.",
    ),
    "X.9": (
        "[Bổ sung] Mọi bảng phải dev lại từ Silver",
        "Quy định đã chốt: tất cả bảng Gold đều dev lại từ Silver. Script phải đọc "
        "raw_vault/business_vault, hoặc đọc bảng Gold khác mà bảng đó cũng dev từ Silver "
        "(tool truy theo chuỗi, ví dụ v_cdtk_daily → holiday → calendar). Bảng upload/thủ "
        "công (có DDL + data nạp tay) LÀ nguồn hợp lệ, nhưng phải khai rõ ở cột NOTE của "
        'dòng JOIN SCHEMA tương ứng, ví dụ "TABLE upload thu cong (khong qua ETL/Silver)" — '
        "khai rồi thì tool tự chấp nhận. Không khai thì tool không phân biệt được với "
        "trường hợp quên dev từ Silver. Lưu ý tên bảng trong SQL phải khớp tên khai ở "
        "JOIN SCHEMA, lệch một ký tự là không ghép được.",
    ),
    "X.8": (
        "[Bổ sung] JOIN SCHEMA trong thiết kế khớp bảng nguồn trong SQL",
        "Bảng khai báo ở block JOIN SCHEMA của workbook phải xuất hiện trong SQL và ngược "
        "lại. Lệch tên (thiếu tiền tố TB_, sai chính tả) nghĩa là thiết kế và code đi hai "
        "đường — phải xác nhận tên bảng thật rồi sửa một trong hai bên.",
    ),
}


def title(rid: str, fallback: str = "") -> str:
    return TEXT.get(rid, (fallback, ""))[0] or fallback


def fix(rid: str) -> str:
    return TEXT.get(rid, ("", ""))[1]
