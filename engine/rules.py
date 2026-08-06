# -*- coding: utf-8 -*-
"""20 tieu chi checklist OCB + 9 tieu chi bo sung Raffles (nhom X, khong tinh diem OCB).

Trang thai noi bo -> gia tri ghi vao sheet ket qua (xem report.CELL, score()):
  PASS   -> Pass    may ket luan dat
  N-A    -> Pass    tieu chi khong ap dung cho profile nay (khong co gi de sai)
  WARN   -> WARN    logic dung nhung chua toi uu / nen xem lai - KHONG tinh loi, o vang nhat
  FAIL   -> Fail    may ket luan khong dat, tinh loi

KHONG con trang thai "chua co so lieu": moi tieu chi deu phai ket luan duoc tu code -
sai han thi FAIL, dung nhung chua toi uu thi WARN, con lai PASS.

Bang chung (evidence) viet tieng Viet co dau vi duoc ghi thang vao cot
"Ghi chu / Bang chung loi" cua file gui OCB. Huong dan sua nam o rule_text.py.
"""
from __future__ import annotations

import difflib
import os
import re
from dataclasses import dataclass, field

from sqlglot import exp

from doc_standard import TRANSACTION_SATS
from mapping import norm_key
from core import (
    LINK_RE,
    SAT_RE,
    NUMERIC_COL_RE,
    P_GOLD,
    P_SILVER,
    P_UPLOAD,
    PLACEHOLDER_RE,
    SILVER_SCHEMA_RE,
    SRC_FILE,
    Ctx,
    first_line,
    has_column,
    has_cutoff,
    in_scope,
    lines_of,
    predicates,
    pretty_fqn,
    same_object,
    sat_refs,
    scope_chain,
)

PASS, FAIL, NA, WARN = "PASS", "FAIL", "N-A", "WARN"

# pattern chuan da chot voi user: MAX_BY + QUALIFY
STANDARD_SIG = "MAX_BY"

G1, G2, G3, GX = "Nhom 1 - Mapping", "Nhom 2 - Logic", "Nhom 3 - Optimization", "Nhom X - Bo sung Raffles"


@dataclass
class Finding:
    status: str
    evidence: list = field(default_factory=list)

    def __post_init__(self):
        self.evidence = [e for e in self.evidence if e and e.strip()]

    def note(self) -> str:
        return "; ".join(self.evidence)


@dataclass
class Rule:
    id: str
    group: str
    title: str
    fn: object
    profiles: tuple = ()


RULES: dict[str, Rule] = {}


def rule(rid: str, group: str, title: str, profiles: tuple = ()):
    def deco(fn):
        RULES[rid] = Rule(rid, group, title, fn, profiles)
        return fn

    return deco


def _ok(*ev) -> Finding:
    return Finding(PASS, [e for e in ev if e])


# ============================================================ pattern active
def active_signatures(ctx: Ctx) -> dict:
    """Chu ky cach lay ban ghi moi nhat + huong loc cdc_status trong 1 file."""
    sigs, cdc_dirs = set(), set()

    for sat in sat_refs(ctx):
        sel = sat.parent_select
        if sel is None:
            continue
        if list(sel.find_all(exp.ArgMax)) or re.search(r"\bMAX_BY\s*\(", sel.sql(), re.I):
            sigs.add("MAX_BY")
        elif sel.args.get("qualify") is not None and re.search(r"ROW_NUMBER", sel.args["qualify"].sql(), re.I):
            sigs.add("QUALIFY_RN")
        elif re.search(r"ROW_NUMBER", sel.sql(), re.I):
            sigs.add("SUBQ_RN")
        elif re.search(r"MAX\s*\(\s*\w*\.?source_event_date", sel.sql(), re.I):
            sigs.add("MAX_SUBQ")

    for m in re.finditer(r"cdc_status\s*(<>|!=|=|IN|NOT\s+IN)\s*\(?\s*'([A-Z])'", ctx.raw, re.I):
        op = m.group(1).upper().replace(" ", "")
        cdc_dirs.add("EXCLUDE_D" if op in ("<>", "!=", "NOTIN") else "INCLUDE_D")

    return {"sigs": sigs, "cdc": cdc_dirs}


# ============================================================ NHOM 1
@rule("1.1", G1, "Du mapping Silver->Gold", (P_SILVER, P_GOLD, P_UPLOAD))
def r11(ctx: Ctx, repo: dict) -> Finding:
    """So cot dau ra cua SQL voi FIELD MAPPING trong workbook thiet ke."""
    ph = sorted({m.group(0) for m in PLACEHOLDER_RE.finditer(ctx.raw)})
    if ph:
        return Finding(FAIL, [f"còn placeholder chưa thay: {', '.join(ph)}"
                              f" tại dòng {lines_of(ctx.raw, '<[a-z][a-z0-9_]*>')}"])
    doc = ctx.mapping
    if doc is None:
        return Finding(WARN, [
            f"KHÔNG TÌM THẤY workbook thiết kế cho object {ctx.target.split('.')[-1]}"
            " nên không đối chiếu được danh sách cột"
            f" (SQL có {len(ctx.out_columns)} cột đầu ra)"])
    if not doc.fields:
        return Finding(FAIL, [f"workbook {os.path.basename(doc.path)} không có block"
                              " FIELD MAPPING đọc được nên thiếu đặc tả mapping cột"])

    # doc.field_names da chuan hoa (bo dau nhay, bo trung lap); phia SQL cung bo trung lap
    # de doi xung - SQL UNION ALL nhieu nhanh van chi co 1 tap cot dau ra.
    want = [f.upper() for f in doc.field_names]
    got = list(dict.fromkeys(c.upper() for c in ctx.out_columns))
    missing = [c for c in want if c not in got]
    extra = [c for c in got if c not in want]
    ev = [f"workbook {os.path.basename(doc.path)}: thiết kế {len(want)} field, SQL có {len(got)} cột"]
    if missing:
        ev.append(f"SQL THIẾU {len(missing)} cột có trong thiết kế: {missing[:10]}")
    if extra:
        ev.append(f"SQL có {len(extra)} cột KHÔNG có trong thiết kế: {extra[:10]}")
    return Finding(FAIL, ev) if missing or extra else _ok(*ev)


# Tieu chi 1.3 (doi soat so dong & SUM voi he thong cu) DA BO khoi pham vi tu cham:
# viec nay chi lam duoc khi co du lieu that o buoc UAT test, khong cham duoc tu code.
# Bo han -> khong ghi gi vao cot G, khong dua vao note.


@rule("1.2", G1, "Danh sach bang/view khop tai lieu thiet ke")
def r12(ctx: Ctx, repo: dict) -> Finding:
    """Ngoai viec doi chieu danh sach, kiem luon TEN OBJECT co khop 3 noi khong:
    ten trong cau CREATE/INSERT, ten file .sql, va ten object khai trong workbook.

    Lech ten la loi that: attach_mapping co fallback ghep theo TEN FILE, nen mot object
    viet sai ten ben trong van ghep duoc workbook va lot het cac tieu chi con lai."""
    short = ctx.target.split(".")[-1].upper()
    key = norm_key(short)
    ev = []

    # chi so voi ten file khi target lay tu cau CREATE/INSERT that (AST);
    # target suy tu comment/ten file thi khong co gi de doi chieu.
    if ctx.target_source == "AST" and ctx.source_kind == SRC_FILE:
        file_key = norm_key(ctx.path)
        if file_key and file_key != key:
            ev.append(f"lệch tên: SQL tạo object {short} nhưng file đặt tên"
                      f" {os.path.basename(ctx.path)} ({file_key})")

    if ctx.mapping is not None and norm_key(ctx.mapping.object_name) != key:
        ev.append(f"lệch tên: thiết kế khai object {ctx.mapping.object_name}"
                  f" còn SQL tạo {short} (ghép cặp được nhờ tên file nên dễ bị bỏ qua)")
    if ev:
        return Finding(FAIL, ev + ["xác nhận tên đúng rồi sửa cho khớp cả 3 nơi:"
                                   " câu CREATE, tên file, workbook thiết kế"])

    gold_list = repo.get("gold_list")
    if gold_list:
        return _ok(f"{short} có trong danh sách Gold đã duyệt") if short in gold_list \
            else Finding(FAIL, [f"{short} KHÔNG có trong danh sách Gold đã duyệt"])
    if ctx.mapping is not None:
        return _ok(f"{short} có workbook thiết kế: {os.path.basename(ctx.mapping.path)}")
    return Finding(FAIL, [f"{short} không có workbook thiết kế tương ứng trong thư mục mapping"])


# ============================================================ NHOM 2
@rule("2.1", G2, "Chi lay ban ghi active, loai ban ghi da xoa (qua sts_hub)", (P_SILVER,))
def r21(ctx: Ctx, repo: dict) -> Finding:
    """Tai lieu ky thuat, muc 'STS Hub' + 'Satellite' (chuong 'Quy tac khi xu ly cac bang
    tu Silver'): chi giu ban ghi da xoa KHI CO yeu cau nghiep vu (ghi ro trong mapping) -
    khong bat buoc moi hub_<ent> phai co sts_hub_<ent>. Neu CO doc sts_hub thi phai dung
    format: HAVING max_by(cdc_status, source_event_date) = 'D' roi anti-join (d.hk IS
    NULL). KHONG loc cdc_status trong satellite - trang thai xoa da duoc <ent>_active
    (sts_hub) loc (muc 'Satellite' - nguyen tac)."""
    sts = {t.name.lower() for t in _tables(ctx) if t.name.lower().startswith("sts_hub_")}
    ev = []

    if not _tables(ctx) or (not sts and not sat_refs(ctx)):
        return Finding(NA, ["script không đọc sts_hub/satellite nào nên không có bản ghi xóa để lọc"])

    for s in sts:
        if not re.search(r"max_by\s*\(\s*(?:\w+\.)?cdc_status\s*,\s*(?:\w+\.)?source_event_date\s*\)\s*=\s*'D'",
                          ctx.raw, re.I):
            ev.append(f"{s} có được đọc nhưng không thấy HAVING max_by(cdc_status, source_event_date) = 'D' —"
                      " đang lấy trạng thái mới nhất bằng cách khác")
            break
    if sts and not re.search(r"IS\s+NULL", ctx.raw, re.I):
        ev.append("có đọc sts_hub nhưng không thấy anti-join (d.<hashkey> IS NULL) nên chưa loại được khóa đã xóa")

    # loc cdc_status trong satellite la sai tang theo tai lieu
    wrong_layer = [sat.name for sat in sat_refs(ctx)
                   if in_scope(sat, lambda p: has_column(p, "cdc_status"))]
    if wrong_layer:
        ev.append(f"lọc cdc_status ngay trong satellite là SAI TẦNG (phải lọc ở sts_hub): {sorted(set(wrong_layer))}")

    return Finding(FAIL, ev) if ev else _ok(
        f"{len(sts)} sts_hub_* đọc đúng format" if sts else "không dùng sts_hub_* (không có yêu cầu nghiệp vụ giữ bản ghi đã xóa)")


def _tables(ctx: Ctx) -> list:
    out = []
    for st in ctx.statements:
        if isinstance(st, exp.Use):          # USE CATALOG/SCHEMA khong phai bang nguon
            continue
        for tbl in st.find_all(exp.Table):
            if tbl.name.lower() not in ctx.cte_aliases:
                out.append(tbl)
    return out


@rule("2.2", G2, "Thong nhat MOT pattern xac dinh ban ghi active", (P_SILVER,))
def r22(ctx: Ctx, repo: dict) -> Finding:
    mine = active_signatures(ctx)
    repo_sigs, repo_cdc = repo.get("sigs", set()), repo.get("cdc", set())
    ev = [f"file này dùng: {sorted(mine['sigs']) or ['(không có)']}; toàn batch dùng: {sorted(repo_sigs)}"]

    if len(mine["sigs"]) > 1:
        return Finding(FAIL, ev + [f"BẤT NHẤT trong cùng 1 file, dùng {len(mine['sigs'])} cách khác nhau: {sorted(mine['sigs'])}"])
    if len(repo_cdc) > 1 and mine["cdc"]:
        return Finding(FAIL, ev + [f"hướng lọc cdc_status bất nhất giữa các file trong batch: {sorted(repo_cdc)} (Issue log #2)"])
    if len(repo_sigs) > 1 and mine["sigs"] and mine["sigs"] != {STANDARD_SIG}:
        return Finding(FAIL, ev + [f"batch đang bất nhất mà file này không theo pattern chuẩn {STANDARD_SIG}"])
    if not mine["sigs"]:
        return Finding(NA, ["script không có bước lấy bản ghi mới nhất từ satellite"])
    return _ok(*ev)


@rule("2.3", G2, "Dieu kien loc dat SAU rn=1, khong long trong JOIN ... ON", (P_SILVER, P_GOLD))
def r23(ctx: Ctx, repo: dict) -> Finding:
    bad, soft = [], []
    for st in ctx.statements:
        for join in st.find_all(exp.Join):
            on = join.args.get("on")
            if on is None:
                continue
            hits = [c for c in ("cdc_status", "rn", "rnk", "row_num") if has_column(on, c)]
            # source_event_date trong ON: HOP LE voi PIT (= p.<sat>_src_ev_dt, III.4.2.4)
            # va voi 49 bang transaction (= :DATADT). Ngoai 2 truong hop do la sai.
            if has_column(on, "source_event_date") and not _sed_in_on_allowed(ctx, join, on):
                hits.append("source_event_date")
            if not re.search(r"ROW_NUMBER", on.sql(), re.I) and not hits:
                continue
            side = (join.side or "").upper() or ("INNER" if not join.args.get("kind") else join.args["kind"].upper())
            tgt = f"{hits or ['ROW_NUMBER']} nằm trong ON của {side} JOIN {_join_name(join)}"
            (bad if side in ("LEFT", "RIGHT", "FULL") else soft).append(tgt)
    if bad:
        return Finding(FAIL, ["đặt trong ON của OUTER JOIN sẽ ra NULL âm thầm khi không match (Issue log #3): " + "; ".join(bad)])
    if soft:
        return Finding(WARN, ["với INNER JOIN thì tương đương WHERE nên chưa sai kết quả, vẫn nên chuyển ra ngoài: " + "; ".join(soft)])
    return _ok("không có điều kiện trạng thái nào lồng trong JOIN ON")


def _join_name(join: exp.Join) -> str:
    tbl = join.this
    return tbl.alias_or_name if isinstance(tbl, (exp.Table, exp.Subquery)) else "?"


def _sed_in_on_allowed(ctx: Ctx, join: exp.Join, on: exp.Expression) -> bool:
    """source_event_date trong ON la HOP LE khi so sanh AS-OF voi cot cua BANG KHAC:
    PIT dang '=' (source_event_date = p.<sat>_src_ev_dt) hoac carry-forward dang '<='/'>='
    (s.source_event_date <= h.<ngay_snapshot>, vd V_CREDIT_LIMIT/v_sbv_1 join theo tung ngay
    calendar). Ca 2 deu BAT BUOC nam trong ON de LEFT JOIN giu duoc dong hub/calendar khi
    chua co ban ghi thoa dieu kien - khac voi loi Issue#3 thuc su (rn/cdc_status dung de
    dedup 1 dong duy nhat, khong phai bound theo ngay, nen KHONG duoc mien tru o day)."""
    if re.search(r"source_event_date\s*(?:=|<=|>=)\s*\w+\.\w+", on.sql(), re.I):
        return True
    tbl = join.this
    return isinstance(tbl, exp.Table) and tbl.name.lower() in TRANSACTION_SATS


@rule("2.4", G2, "source_event_date dung dang <= / = theo loai bang", (P_SILVER,))
def r24(ctx: Ctx, repo: dict) -> Finding:
    """Tai lieu III.4.2: bang thuong dung source_event_date <= :DATADT, KHONG dat can duoi.
    Rieng 49 bang transaction (muc 'Cac truong hop dac biet') PHAI dung = :DATADT."""
    ok, missing, wrong_form = [], [], []
    for sat in sat_refs(ctx):
        name = sat.name.lower()
        where = f"{sat.name} (dong {first_line(ctx.raw, sat.name)})"
        is_txn = name in TRANSACTION_SATS
        has_le = in_scope(sat, lambda p: has_cutoff(p, "source_event_date"))
        has_eq = in_scope(sat, lambda p: _has_eq_on(p, "source_event_date"))

        if is_txn:
            if has_eq:
                ok.append(where)
            elif has_le:
                wrong_form.append(f"{where}: là bảng transaction nên phải dùng source_event_date = :DATADT, đang dùng <=")
            else:
                missing.append(where)
        else:
            if has_le:
                ok.append(where)
            elif has_eq and _pit_join(ctx, sat):
                ok.append(where)      # PIT: s.source_event_date = p.<sat>_src_ev_dt
            elif has_eq:
                wrong_form.append(f"{where}: dùng = :DATADT nhưng KHÔNG thuộc danh sách 49 bảng transaction,"
                                  " sẽ bỏ sót bản ghi mới nhất nằm trước ngày chạy (Issue log #1)")
            else:
                missing.append(where)

    lower_bound = lines_of(ctx.raw, r"source_event_date\s*>=?")
    ev = []
    if wrong_form:
        ev += wrong_form
    if missing:
        ev.append(f"{len(missing)} satellite không có điều kiện source_event_date nào: " + ", ".join(sorted(set(missing))))
    if lower_bound:
        ev.append(f"có đặt cận dưới source_event_date >= ở dòng {lower_bound[:4]} —"
                  " tài liệu yêu cầu CHỈ chặn trên, cận dưới làm bỏ sót bản ghi mới nhất")
    if ev:
        return Finding(FAIL, ev)
    if not ok:
        return Finding(NA, ["script không đọc satellite nào"])
    return _ok(f"{len(ok)} satellite đều đúng dạng điều kiện source_event_date")


def _has_eq_on(node: exp.Expression, col: str) -> bool:
    for eq in node.find_all(exp.EQ):
        for side in (eq.this, eq.expression):
            if isinstance(side, exp.Column) and side.name.lower() == col.lower():
                return True
    return False


def _pit_join(ctx: Ctx, sat: exp.Table) -> bool:
    """Pattern PIT: LEFT JOIN sat ON sat.source_event_date = p.<sat>_src_ev_dt (III.4.2.4)."""
    return bool(re.search(r"source_event_date\s*=\s*\w+\.\w*_src_ev_dt", ctx.raw, re.I))


@rule("2.5", G2, "Khong lap lai loi logic cu da fix")
def r25(ctx: Ctx, repo: dict) -> Finding:
    """Nhi phan: trung 1 trong cac loi DA Data Vault da neu (known_issues.json) -> FAIL,
    khong trung -> PASS. Danh sach loi trich tu 'ZoneC Mapping - Iss log.xlsx' sheet Issue."""
    hits = []
    for issue, pattern in repo.get("known_issues", {}).items():
        if issue.startswith("_"):          # khoa metadata (_nguon...), khong phai regex
            continue
        ln = lines_of(ctx.raw, pattern)
        if ln:
            hits.append(f"{issue} @ dòng {ln[:5]}")
    if hits:
        return Finding(FAIL, [f"lặp lại {len(hits)} lỗi DA Data Vault đã nêu ở Issue log: " + "; ".join(hits)])
    return _ok("không trùng lỗi nào trong Issue log của DA Data Vault")


@rule("2.6", G2, "SCD Type 2 dung ky thuat da thong nhat")
def r26(ctx: Ctx, repo: dict) -> Finding:
    """Tai lieu muc LDP: SCD2 lam bang APPLY CHANGES INTO ... SEQUENCE BY source_event_date
    STORED AS SCD TYPE 2 (Databricks tu quan __START_AT/__END_AT). Cot eff/end tu quan la
    phuong an thay the. Cam MAX(ID)+ROW_NUMBER (Issue log #4)."""
    if not ctx.is_dim:
        return Finding(NA, ["object không phải bảng DIM nên không áp dụng SCD Type 2"])
    ev = []
    if re.search(r"MAX\s*\(\s*[\w.]*(_ID|ID)\s*\)", ctx.raw, re.I) and re.search(r"ROW_NUMBER", ctx.raw, re.I):
        ev.append(f"dùng antipattern MAX(ID) + ROW_NUMBER để sinh surrogate key ở dòng {lines_of(ctx.raw, r'ROW_NUMBER')[:5]} (Issue log #4)")
    if re.search(r"STORED\s+AS\s+SCD\s+TYPE\s*2", ctx.raw, re.I):
        return Finding(FAIL, ev) if ev else _ok("dùng APPLY CHANGES ... STORED AS SCD TYPE 2 đúng tài liệu")
    cols = " ".join(ctx.out_columns).upper()
    if not re.search(r"(EFF|EFFECTIVE|VALID).*(DT|DATE)|END_(DT|DATE)|CURRENT_FLAG|IS_CURRENT|START_AT", cols):
        ev.append("không dùng APPLY CHANGES ... SCD TYPE 2 và cũng không có cột"
                  " effective_date/end_date/current_flag để tự quản hiệu lực")
    return Finding(FAIL, ev) if ev else _ok("có cột hiệu lực và không dùng MAX(ID)+ROW_NUMBER")


@rule("2.7", G2, "CASE WHEN cover du nhanh nhu job on-prem")
def r27(ctx: Ctx, repo: dict) -> Finding:
    no_else = 0
    for st in ctx.statements:
        for case in st.find_all(exp.Case):
            if case.args.get("default") is None:
                no_else += 1
    total = sum(len(list(st.find_all(exp.Case))) for st in ctx.statements)
    if total == 0:
        return Finding(NA, ["script không có CASE WHEN nào"])
    if no_else:
        return Finding(FAIL, [
            f"{no_else}/{total} CASE KHÔNG có nhánh ELSE -> rơi ra ngoài mọi WHEN sẽ trả NULL"
            f" âm thầm, tại dòng {lines_of(ctx.raw, r'CASE')[:8]}",
            "bổ sung ELSE (giá trị mặc định hoặc giá trị nghiệp vụ đúng như job on-prem)"])
    return _ok(f"cả {total} CASE đều có nhánh ELSE")


@rule("2.8", G2, "Cot SUM/COUNT duoc COALESCE/NVL hop ly")
def r28(ctx: Ctx, repo: dict) -> Finding:
    naked = []
    for st in ctx.statements:
        for agg in list(st.find_all(exp.Sum)) + list(st.find_all(exp.Count)):
            arg = agg.this
            if isinstance(arg, exp.Star):
                continue
            if re.search(r"\b(COALESCE|NVL|IFNULL)\s*\(", arg.sql(), re.I):
                continue
            parent = agg.parent
            if isinstance(parent, exp.Coalesce) or (isinstance(parent, exp.Alias) and _alias_coalesced(ctx, parent.alias)):
                continue
            if isinstance(parent, exp.Alias):
                naked.append(f"{parent.alias} = {agg.sql()[:60]}")
            else:
                naked.append(agg.sql()[:60])
    if not naked:
        return Finding(PASS, ["mọi SUM/COUNT đều đã coalesce (trực tiếp hoặc ở lớp ngoài)"])
    return Finding(WARN, [f"{len(naked)} biểu thức tổng hợp chưa coalesce: " + "; ".join(sorted(set(naked))[:6]),
                          "khi đối soát với hệ thống cũ phải bọc NVL/ISNULL CẢ HAI phía để"
                          " không lệch khi trừ (Checklist RVN-OCB #11)"])


def _alias_coalesced(ctx: Ctx, alias: str) -> bool:
    return bool(alias) and bool(re.search(rf"(COALESCE|NVL|IFNULL)\s*\(\s*\w*\.?{re.escape(alias)}\b", ctx.raw, re.I))


@rule("2.9", G2, "Subquery / function / LIKE dung nghia nghiep vu")
def r29(ctx: Ctx, repo: dict) -> Finding:
    likes = sorted({lk.sql()[:70] for st in ctx.statements for lk in st.find_all(exp.Like)})
    subq = sum(1 for st in ctx.statements for s in st.find_all(exp.Subquery) if isinstance(s.parent, exp.Condition))
    if not likes and not subq:
        return Finding(NA, ["script không có điều kiện LIKE hay scalar subquery nào"])
    ev = []
    if likes:
        ev.append(f"{len(likes)} điều kiện LIKE: " + " | ".join(likes[:4]))
    if subq:
        ev.append(f"{subq} subquery nằm trong điều kiện")
    ev.append("cú pháp hợp lệ; ý nghĩa nghiệp vụ cần người review đối chiếu job on-prem")
    return _ok(*ev)


@rule("2.10", G2, "Aggregation kem filter date range chinh xac")
def r210(ctx: Ctx, repo: dict) -> Finding:
    bare = []
    cte_map = _cte_map(ctx)
    for st in ctx.statements:
        for sel in st.find_all(exp.Select):
            if not _has_agg(sel):
                continue
            if not _date_filtered(sel, cte_map):
                bare.append(_sel_label(sel))
    if not bare:
        return Finding(PASS, ["mọi khối tổng hợp đều có điều kiện theo kỳ dữ liệu"])
    return Finding(WARN, [f"{len(bare)} khối tổng hợp không thấy filter theo ngày/tham số: " + ", ".join(bare[:6])])


def _has_agg(sel: exp.Select) -> bool:
    return any(sel.find(k) for k in (exp.Sum, exp.Count, exp.Avg, exp.Min, exp.Max)) or bool(sel.args.get("group"))


DATE_COL_RE = re.compile(r"(DT_ID|DATA_DATE|DATE|_DT$|MSR_PRD|source_event_date|YR_ID|MO_ID)", re.I)


def _cte_map(ctx: Ctx) -> dict:
    out = {}
    for st in ctx.statements:
        for cte in st.find_all(exp.CTE):
            if cte.alias:
                out[cte.alias.lower()] = cte.this
    return out


def _date_filtered(sel: exp.Select, cte_map: dict, depth: int = 2) -> bool:
    for scope in [sel] + scope_chain(sel):
        for pred in predicates(scope):
            if pred.find(exp.Placeholder) or pred.find(exp.Parameter):
                return True
            if any(DATE_COL_RE.search(c.name) for c in pred.find_all(exp.Column)):
                return True
    if depth <= 0:
        return False
    # doc tu CTE da filter san (vd. forex_rm doc tu CTE forex co filter thang) -> coi la da filter
    for tbl in sel.find_all(exp.Table):
        src = cte_map.get(tbl.name.lower())
        if isinstance(src, (exp.Select, exp.Union)) and _date_filtered(
                src.left if isinstance(src, exp.Union) else src, cte_map, depth - 1):
            return True
    return False


def _sel_label(sel: exp.Select) -> str:
    cte = sel.parent
    if isinstance(cte, exp.CTE):
        return cte.alias
    tbls = [t.name for t in sel.find_all(exp.Table)][:1]
    return f"SELECT tu {tbls[0] if tbls else '?'}"


@rule("2.11", G2, "Join dung key hop ly, khong lam dung UNION ALL + EXISTS")
def r211(ctx: Ctx, repo: dict) -> Finding:
    ev = []
    has_union = any(st.find(exp.Union) for st in ctx.statements)
    has_exists = any(st.find(exp.Exists) for st in ctx.statements)
    if has_union and has_exists:
        ev.append(f"dùng đồng thời UNION ALL và EXISTS ở dòng {lines_of(ctx.raw, r'EXISTS')[:4]}, xét thay bằng LEFT JOIN")
    non_equi = []
    for st in ctx.statements:
        for join in st.find_all(exp.Join):
            on = join.args.get("on")
            if on is None:
                if join.args.get("kind", "").upper() != "CROSS" and not join.args.get("using"):
                    non_equi.append(_join_name(join))
            elif not list(on.find_all(exp.EQ)):
                non_equi.append(_join_name(join))
    if non_equi:
        ev.append(f"join không có điều kiện bằng (=): {sorted(set(non_equi))[:6]}")
    return Finding(WARN, ev) if ev else _ok("join đều theo điều kiện bằng, không lạm dụng UNION ALL + EXISTS")


@rule("2.12", G2, "Build Gold tu CTE snapshot Silver, khong query nhieu tang", (P_SILVER, P_GOLD))
def r212(ctx: Ctx, repo: dict) -> Finding:
    """Dem so KHOI SELECT khac nhau doc cung 1 bang, khong dem so lan xuat hien.

    Self-join (calendar D LEFT JOIN calendar W) nam trong CUNG mot SELECT -> doc cung mot
    snapshot, khong lech thoi diem du lieu -> khong tinh la doc nhieu lan.
    Doc cung 1 bang o 2 CTE khac nhau moi la van de: moi CTE co filter rieng."""
    scopes = {}
    for st in ctx.statements:
        for tbl in st.find_all(exp.Table):
            fqn = ".".join(p for p in [
                tbl.args["catalog"].name if tbl.args.get("catalog") else "",
                tbl.args["db"].name if tbl.args.get("db") else "",
                tbl.name] if p)
            if fqn.lower() in ctx.cte_aliases or same_object(fqn, ctx.target):
                continue
            scopes.setdefault(fqn, set()).add(id(tbl.parent_select))
    counts = {k: len(v) for k, v in scopes.items()}
    # chi raw_vault (hub/sat/link co lich su) moi lam lech thoi diem du lieu;
    # business_vault (calendar, dim nho) doc lai chi la kem toi uu -> WARN.
    silver_dup = {k: v for k, v in counts.items() if v > 1 and re.search(r"\.raw_vault\.", "." + k + ".", re.I)}
    gold_dup = {k: v for k, v in counts.items() if v > 1 and k not in silver_dup}
    if silver_dup:
        return Finding(FAIL, ["bảng Silver bị đọc ở nhiều khối SELECT khác nhau thay vì snapshot 1 CTE: "
                              + ", ".join(f"{pretty_fqn(k)} ở {v} khối" for k, v in silver_dup.items())])
    if gold_dup:
        return Finding(WARN, ["bảng bị đọc lại ở nhiều khối SELECT, xét gom thành 1 CTE: "
                              + ", ".join(f"{k.split('.')[-1]} ở {v} khối" for k, v in gold_dup.items())])
    return _ok("mỗi bảng nguồn chỉ đọc trong 1 khối SELECT")


# ============================================================ NHOM 3
@rule("3.1", G3, "Khong SELECT *")
def r31(ctx: Ctx, repo: dict) -> Finding:
    stars = 0
    for st in ctx.statements:
        for sel in st.find_all(exp.Select):
            for e in sel.expressions:
                if isinstance(e, exp.Star) or (isinstance(e, exp.Column) and isinstance(e.this, exp.Star)):
                    stars += 1
    if stars:
        return Finding(FAIL, [f"có {stars} lần SELECT * ở dòng {lines_of(ctx.raw, r'SELECT\s+\*|SELECT\s+\w+\.\*')[:6]}"])
    return _ok("không dùng SELECT * ở đâu")


@rule("3.2", G3, "CTE khong bi scan lai nhieu lan")
def r32(ctx: Ctx, repo: dict) -> Finding:
    reuse = _cte_reuse(ctx)
    heavy = {k: v for k, v in reuse.items() if v >= 2}
    if not heavy:
        return _ok("không có CTE nào bị gọi lại")
    return Finding(WARN, ["CTE bị tham chiếu lại nhiều lần: " + ", ".join(f"{k} x{v}" for k, v in heavy.items())])


def _cte_reuse(ctx: Ctx) -> dict:
    """So lan 1 CTE 'nang' bi tham chieu lai. CTE tham so (khong doc bang nao) bo qua."""
    out = {}
    for alias, src in _cte_map(ctx).items():
        reads = [t for t in src.find_all(exp.Table) if t.name.lower() not in ctx.cte_aliases]
        if not reads:
            continue  # vd. CTE prm chi chua tham so, scan lai khong ton kem
        n = len(re.findall(rf"(?<![\w.]){re.escape(alias)}(?![\w(])", ctx.raw, re.I))
        if n - 1 > 0:
            out[alias] = n - 1  # tru 1 lan dinh nghia
    return out


@rule("3.3", G3, "Filter truoc khi join, tan dung partition pruning", (P_SILVER, P_GOLD))
def r33(ctx: Ctx, repo: dict) -> Finding:
    """Filter rieng cua bang join co the nam o WHERE hoac o chinh ON cua join do.

    Voi LEFT JOIN thi dieu kien loc bang phai BUOC PHAI nam trong ON (chuyen ra WHERE se
    bien thanh INNER JOIN, mat dong) - Spark van day duoc xuong scan de prune partition.
    Nen quet ca hai cho, khong chi WHERE."""
    naked = []
    for st in ctx.statements:
        for join in st.find_all(exp.Join):
            tbl = join.this
            if not isinstance(tbl, exp.Table):
                continue  # subquery da co filter rieng
            fqn = tbl.name
            if fqn.lower() in ctx.cte_aliases:
                continue
            sel = join.parent_select
            if sel is None:
                continue
            alias = tbl.alias_or_name
            if not (_filters_alias(sel.args.get("where"), alias)
                    or _filters_alias(join.args.get("on"), alias)):
                naked.append(f"{fqn} ({alias})")
    if naked:
        return Finding(WARN, [f"{len(naked)} bảng join trực tiếp mà không có filter riêng: " + ", ".join(sorted(set(naked))[:8])])
    return _ok("các bảng join đều được filter trước")


CMP_NODES = (exp.EQ, exp.NEQ, exp.GT, exp.GTE, exp.LT, exp.LTE, exp.Like, exp.ILike, exp.In, exp.Is)


def _filters_alias(node, alias: str) -> bool:
    """Co dieu kien LOC RIENG cho <alias> trong bieu thuc node hay khong.

    Dieu kien loc rieng = bieu thuc so sanh ma alias la bang DUY NHAT xuat hien
    (vd. W.bsn_day_f = 1). Neu co bang khac trong cung bieu thuc (vd. D.dt > W.dt)
    thi do la dieu kien JOIN, khong prune duoc partition -> khong tinh."""
    if node is None or not alias:
        return False
    want = alias.lower()
    for cmp_node in node.find_all(*CMP_NODES):
        tables = {c.table.lower() for c in cmp_node.find_all(exp.Column) if c.table}
        if tables == {want}:
            return True
    return False


@rule("3.4", G3, "Su dung CACHE cho query lap lai trong cung luong")
def r34(ctx: Ctx, repo: dict) -> Finding:
    heavy = {k: v for k, v in _cte_reuse(ctx).items() if v >= 2}
    if not heavy:
        return Finding(NA, ["không có kết quả nào được dùng lại nhiều lần nên chưa cần CACHE"])
    if re.search(r"\bCACHE\s+(TABLE|SELECT)\b", ctx.raw, re.I):
        return _ok("đã dùng CACHE")
    return Finding(WARN, [f"{len(heavy)} CTE nặng dùng lại >= 2 lần mà không có CACHE: " + ", ".join(sorted(heavy))])


@rule("3.5", G3, "Uu tien MAX_BY + QUALIFY thay ROW_NUMBER()+WHERE rn=1")
def r35(ctx: Ctx, repo: dict) -> Finding:
    if not re.search(r"ROW_NUMBER", ctx.raw, re.I):
        return Finding(NA, ["script không dùng ROW_NUMBER"])
    if re.search(r"\bMAX_BY\s*\(", ctx.raw, re.I):
        return _ok("đã dùng MAX_BY")
    latest_pick = re.search(r"ROW_NUMBER[^;]{0,400}?\)\s*=\s*1|(?:\brn\b|\brnk\b|row_num)\s*=\s*1", ctx.raw, re.I)
    if not latest_pick:
        return Finding(WARN, [f"có ROW_NUMBER ở dòng {lines_of(ctx.raw, 'ROW_NUMBER')[:5]} nhưng không phải dạng lấy dòng mới nhất, cần xác nhận không thay được bằng MAX_BY"])
    return Finding(FAIL, [f"lấy bản ghi mới nhất bằng ROW_NUMBER = 1 ở dòng {lines_of(ctx.raw, 'ROW_NUMBER')[:5]},"
                          f" pattern chuẩn đã chốt là MAX_BY (Issue log #5)"])


@rule("3.6", G3, "Khong lam dung window function; co comment khi dung")
def r36(ctx: Ctx, repo: dict) -> Finding:
    wl = lines_of(ctx.raw, r"OVER\s*\(")
    if not wl:
        return Finding(NA, ["script không dùng window function"])
    src = ctx.raw.splitlines()
    # comment giai thich thuong dat o dau CTE chua window -> quet tu dau CTE do den dong window
    uncommented = [ln for ln in wl if not _commented_block(src, ln)]
    if uncommented:
        return Finding(WARN, [f"{len(uncommented)}/{len(wl)} window function không có comment giải thích, ở dòng {uncommented[:5]}"])
    return _ok(f"{len(wl)} window function đều có comment")


CTE_START_RE = re.compile(r"^\s*,?\s*\w+\s+AS\s*\(", re.I)


def _commented_block(src: list, line: int) -> bool:
    """Co comment nao trong khoi CTE/cau lenh chua dong `line` khong."""
    start = 1
    for i in range(line - 1, 0, -1):
        if CTE_START_RE.match(src[i - 1]):
            start = i
            break
    return any("--" in src[i - 1] for i in range(max(1, start - 3), line + 1) if i <= len(src))


# ============================================================ NHOM X (bo sung Raffles)
@rule("X.1", GX, "Link phai rut ve current truoc khi join (chong fan-out)", (P_SILVER,))
def rx1(ctx: Ctx, repo: dict) -> Finding:
    """Tai lieu III.4.2.3: luon rut link ve current (1 dong / driving key) bang
    GROUP BY <driving_hk> + MAX_BY(<target_hk>, source_event_date) truoc khi join vao
    fact/dim, neu khong se nhan doi so dong. M:N thi khu trung o muc link_hashkey."""
    risky = []
    for st in ctx.statements:
        for join in st.find_all(exp.Join):
            tbl = join.this
            if not isinstance(tbl, exp.Table) or not LINK_RE.search("." + tbl.name):
                continue
            sel = join.parent_select
            if sel is None:
                continue
            # da rut current: chinh SELECT chua link co GROUP BY + MAX_BY, hoac DISTINCT/QUALIFY
            if (sel.args.get("group") and re.search(r"max_by\s*\(", sel.sql(), re.I)) \
                    or sel.args.get("distinct") or sel.args.get("qualify"):
                continue
            risky.append(f"{tbl.name} (dong {first_line(ctx.raw, tbl.name)})")
    if risky:
        return Finding(FAIL, [f"{len(risky)} bảng link_* join trực tiếp mà chưa rút về current, sẽ nhân đôi số dòng: "
                              + ", ".join(sorted(set(risky))[:6]),
                              ])
    return _ok("các bảng link_* đều được rút về current trước khi join")


@rule("X.6", GX, "Satellite phai LEFT JOIN, khong INNER JOIN", (P_SILVER,))
def rx6(ctx: Ctx, repo: dict) -> Finding:
    """Tai lieu III.4.2.2 nguyen tac 1: INNER JOIN satellite lam mat ban ghi Hub dang song
    nhung chua co dong satellite. Lam giau luon phai LEFT JOIN."""
    bad = []
    for st in ctx.statements:
        for join in st.find_all(exp.Join):
            tbl = join.this
            name = tbl.name.lower() if isinstance(tbl, exp.Table) else ""
            if not SAT_RE.search("." + name):
                continue
            side = (join.side or "").upper()
            kind = (join.args.get("kind") or "").upper()
            if side in ("LEFT", "RIGHT", "FULL") or kind == "CROSS":
                continue
            bad.append(f"{tbl.name} (dong {first_line(ctx.raw, tbl.name)})")
    if bad:
        return Finding(FAIL, [f"{len(bad)} satellite dùng INNER JOIN, sẽ mất bản ghi Hub chưa có dòng satellite: "
                              + ", ".join(sorted(set(bad))[:6])])
    return Finding(NA, ["không join satellite trực tiếp"]) if not sat_refs(ctx) \
        else _ok("các satellite đều LEFT JOIN")


@rule("X.9", GX, "Moi bang phai dev lai tu Silver (truy duoc ve raw_vault/business_vault)")
def rx9(ctx: Ctx, repo: dict) -> Finding:
    """Quy dinh da chot: TAT CA cac bang Gold deu phai dev lai tu Silver.
    Doc truc tiep raw_vault/business_vault -> dat. Doc bang Gold khac -> bang do phai cung
    nam trong batch va cung dev tu Silver (truy theo chuoi).

    NGOAI LE da thong nhat: bang upload/thu cong (co DDL + data nap tay, khong qua ETL)
    duoc coi la NGUON HOP LE, nhung phai KHAI BAO ro o cot NOTE cua block JOIN SCHEMA
    trong workbook thiet ke - vd. 'TABLE upload thu cong (khong qua ETL/Silver)'.
    Khong khai bao thi may khong phan biet duoc voi truong hop quen dev tu Silver."""
    if ctx.silver_tables:
        return _ok(f"đọc trực tiếp {len(ctx.silver_tables)} bảng Silver:"
                   f" {[t.split('.')[-1] for t in ctx.silver_tables][:5]}")

    chain = repo.get("silver_chain") or {}
    batch = repo.get("batch_objects") or set()
    reads = [t.split(".")[-1].lower() for t in ctx.tables
             if not same_object(t, ctx.target)]
    declared = declared_upload(ctx)
    via = sorted({r for r in reads if chain.get(r)})
    upload = sorted({r for r in reads if not chain.get(r) and r in declared})
    rest = {r for r in reads if not chain.get(r) and r not in declared}
    # Phan biet 2 truong hop rat khac nhau:
    #   orphan  = object CO trong luot chay nhung khong truy duoc ve Silver -> loi that
    #   unknown = object KHONG co trong luot chay -> may chua co du lieu de ket luan,
    #             khong duoc bao Fail (vd. chay che do Excel ma workbook chua khai object do)
    orphan = sorted(r for r in rest if r in batch)
    unknown = sorted(r for r in rest if r not in batch)

    ev_upload = (f"{len(upload)} nguồn là bảng upload/thủ công đã khai báo ở NOTE của JOIN SCHEMA:"
                 f" {upload[:5]}") if upload else ""
    ev_unknown = (f"{len(unknown)} nguồn không có trong lượt chạy này nên chưa truy được:"
                  f" {unknown[:5]} — chấm cả các object đó cùng lượt (hoặc khai vào sheet"
                  " 'Script SQL' của workbook) thì máy mới truy được chuỗi") if unknown else ""

    if not reads:
        return Finding(NA, ["script không đọc bảng nguồn nào"])
    if orphan:
        ev = [f"{len(orphan)} nguồn nằm trong lượt chạy nhưng KHÔNG truy được về Silver:"
              f" {orphan[:5]}", ev_upload, ev_unknown,
              "nếu là bảng upload/thủ công thì khai ở cột NOTE của JOIN SCHEMA trong workbook"]
        return Finding(WARN, ev) if via or upload else Finding(FAIL, ev)
    if unknown:
        return Finding(WARN, [
            ev_unknown,
            f"các nguồn còn lại đã truy được: {(via + upload)[:5]}" if via or upload else ""])
    if via:
        return _ok(f"truy về Silver qua {len(via)} bảng Gold trung gian: {via[:5]}", ev_upload)
    return _ok(ev_upload or "mọi nguồn đều truy được về Silver")


UPLOAD_NOTE_RE = re.compile(r"upload|thu\s*cong|thủ\s*công|manual|nhap\s*tay|nhập\s*tay"
                            r"|khong\s*qua\s*(etl|silver)|không\s*qua\s*(etl|silver)", re.I)


def declared_upload(ctx: Ctx) -> set:
    """Ten bang (dang ngan, lowercase) duoc khai la upload/thu cong o NOTE cua JOIN SCHEMA."""
    doc = ctx.mapping
    if doc is None:
        return set()
    return {s.name.split(".")[-1].strip().lower()
            for s in doc.sources if UPLOAD_NOTE_RE.search(s.note or "")}


# Ten bang nam trong doan SQL viet inline o cot 'Table / View' cua workbook thiet ke.
# Bat ca dang IDENTIFIER(:cleaned || '.raw_vault.sat_x') va dang dbo.HOLIDAY WITH (NOLOCK).
INLINE_TBL_RE = re.compile(
    r"\b(?:FROM|JOIN)\s+(?:IDENTIFIER\s*\(\s*:?\w*\s*\|\|\s*')?([A-Za-z_.][\w.]*)", re.I)


def _tables_in_sql_text(text: str) -> list:
    return [m.group(1).split(".")[-1].upper() for m in INLINE_TBL_RE.finditer(text or "")]


@rule("X.8", GX, "JOIN SCHEMA trong thiet ke khop bang nguon trong SQL")
def rx8(ctx: Ctx, repo: dict) -> Finding:
    """Bang khai bao o block JOIN SCHEMA cua workbook phai xuat hien trong SQL va nguoc lai.
    Lech = thiet ke va code di 2 duong."""
    doc = ctx.mapping
    if doc is None or not doc.sources:
        return Finding(NA, ["workbook không có block JOIN SCHEMA để đối chiếu"])

    sql_short = {t.name.upper() for t in _tables(ctx)} | {t.split(".")[-1].upper() for t in ctx.tables}
    designed, missing, inline = [], [], 0
    for s in doc.sources:
        # o thiet ke ghi ca doan SQL (subquery/CTE inline) thay vi ten bang -> khong so khop duoc
        if len(s.name) > 60 or re.search(r"\bSELECT\b|\bWITH\b", s.name, re.I):
            inline += 1
            # Khong doi chieu duoc theo dong, NHUNG ten bang nam ngay trong doan SQL do
            # -> boc ra, neu khong se bao oan "SQL doc bang ma JOIN SCHEMA khong khai bao".
            designed += _tables_in_sql_text(s.name)
            continue
        # 1 dong thiet ke co the ghi nhieu bang: 'LINK_X + HUB_Y'
        parts = [p.strip().split(".")[-1].upper() for p in re.split(r"[+,/]", s.name) if p.strip()]
        parts = [re.sub(r"\s*\(.*?\)\s*", "", p).strip() for p in parts if p]
        if not parts:
            continue
        designed += parts
        if not any(p in sql_short for p in parts):
            missing.append(s.name)
    note = f" (bỏ qua {inline} dòng thiết kế ghi subquery inline thay vì tên bảng)" if inline else ""
    if missing:
        return Finding(FAIL, [f"{len(missing)}/{len(doc.sources)} bảng khai báo trong JOIN SCHEMA nhưng KHÔNG thấy trong SQL:"
                              f" {missing[:6]}{note}"])
    unlisted = sorted({t for t in sql_short if t not in designed
                       and not t.startswith(("PIT_",)) and t != ctx.target.split(".")[-1].upper()})
    if unlisted:
        return Finding(WARN, [f"SQL đọc {len(unlisted)} bảng mà JOIN SCHEMA không khai báo: {unlisted[:8]}"])
    return _ok(f"{len(doc.sources)} bảng nguồn khớp giữa thiết kế và SQL{note}")


@rule("X.7", GX, "Khong hard-code catalog, dung bien moi truong", (P_SILVER, P_GOLD))
def rx7(ctx: Ctx, repo: dict) -> Finding:
    """Tai lieu (Cau hinh Pipeline / Cu phap chung): dung IDENTIFIER(:cleaned || '...') hoac
    ${cleaned_catalog} / ${curated_catalog} thay cho ten catalog cung."""
    hard = sorted({m.group(0) for m in re.finditer(r"ocb_datavault_[a-z0-9]+_(cleaned|curated)", ctx.raw, re.I)})
    if not hard:
        return _ok("dùng biến môi trường cho catalog")
    if re.search(r"IDENTIFIER\s*\(|\$\{(cleaned|curated)_catalog\}", ctx.raw, re.I):
        return Finding(WARN, [f"dùng lẫn cả biến môi trường và catalog cứng: {hard}"])
    return Finding(WARN, [f"hard-code catalog {hard}, deploy sang môi trường khác phải sửa tay từng file"])


@rule("X.2", GX, "Catalog/schema nhat quan theo moi truong")
def rx2(ctx: Ctx, repo: dict) -> Finding:
    envs = sorted({m.group(1).lower() for m in re.finditer(r"ocb_datavault_([a-z0-9]+)_", ctx.raw, re.I)})
    if len(envs) > 1:
        return Finding(FAIL, [f"trộn {len(envs)} môi trường trong cùng 1 file: {envs}, sẽ chạy sai môi trường"])
    return _ok(f"môi trường nhất quán: {envs or ['(không hard-code catalog)']}")


@rule("X.3", GX, "INSERT INTO phai liet ke cot khop DDL")
def rx3(ctx: Ctx, repo: dict) -> Finding:
    ins = [st for st in ctx.statements if isinstance(st, exp.Insert)]
    if not ins:
        return Finding(NA, ["không có câu INSERT (là view hoặc CREATE TABLE AS)"])
    bad = [st for st in ins if not isinstance(st.this, exp.Schema)]
    if bad:
        return Finding(FAIL, [f"{len(bad)} câu INSERT không liệt kê cột, ở dòng {lines_of(ctx.raw, r'^\s*INSERT\s+INTO')[:4]}"])
    return _ok("INSERT có liệt kê cột")


@rule("X.4", GX, "Idempotent: co DELETE/TRUNCATE khop khoa truoc INSERT")
def rx4(ctx: Ctx, repo: dict) -> Finding:
    ins = [st for st in ctx.statements if isinstance(st, exp.Insert)]
    if not ins:
        return Finding(NA, ["không có câu INSERT"])
    dels = [st for st in ctx.statements if isinstance(st, exp.Delete)]
    has_trunc = bool(re.search(r"\b(TRUNCATE|OVERWRITE)\b", ctx.raw, re.I))
    if not dels and not has_trunc:
        return Finding(FAIL, ["có INSERT mà không có DELETE/TRUNCATE, chạy lại lần 2 sẽ nhân đôi dữ liệu"])
    keys = []
    for d in dels:
        where = d.args.get("where")
        if where is not None:
            keys += [c.name.upper() for c in where.find_all(exp.Column)]
    out_up = [c.upper() for c in ctx.out_columns]
    orphan = [k for k in dict.fromkeys(keys) if out_up and k not in out_up]
    if orphan:
        return Finding(WARN, [f"khóa DELETE {orphan} không nằm trong danh sách cột đầu ra, cần xác nhận xóa đúng phạm vi"])
    return _ok(f"DELETE theo khóa {sorted(set(keys)) or ['(TRUNCATE/OVERWRITE)']}")


@rule("X.5", GX, "Join key NULL-safe")
def rx5(ctx: Ctx, repo: dict) -> Finding:
    nullable = {m.group(2).upper() for m in
                re.finditer(r"\b(NVL|COALESCE|IFNULL)\s*\(\s*\w*\.?(\w+)\s*,", ctx.raw, re.I)}
    risky = []
    for st in ctx.statements:
        for join in st.find_all(exp.Join):
            on = join.args.get("on")
            if on is None:
                continue
            for eq in on.find_all(exp.EQ):
                for col in eq.find_all(exp.Column):
                    if col.name.upper() in nullable and not re.search(
                            r"(NVL|COALESCE|IFNULL|<=>)", eq.sql(), re.I):
                        risky.append(f"{col.name} @ {_join_name(join)}")
    if risky:
        return Finding(WARN, [f"cột được NVL ở chỗ khác nhưng join lại không NULL-safe: {sorted(set(risky))[:6]}",
                              ])
    return _ok("không thấy join key nào có nguy cơ NULL")


@rule("X.10", GX, "Bang raw_vault/business_vault duoc doc phai TON TAI THAT trong Data Vault model")
def rx10(ctx: Ctx, repo: dict) -> Finding:
    """Doi chieu ten bang Silver ma script doc voi danh sach model THAT (engine/known_models.json,
    trich tu docs/datavault-model-dev_zonec.zip - dbt project nhanh dev).

    Cac rule khac (2.1, X.6...) chi kiem CU PHAP (co dung pattern sts_hub/hub/sat khong),
    KHONG kiem du lieu THAT co ton tai hay khong. Vi vay 1 script co the dung DUNG PATTERN
    ma vAn goi SAI TEN BANG khong ton tai (vd doc 'sts_hub_giao_dich' vi hub_giao_dich co
    thuc, nhung KHONG co sts_hub tuong ung trong model - hub nay khong track xoa qua STS
    Hub) - loi nay se FAIL o RUNTIME Databricks (table not found), khong loi cu phap nao
    bat truoc duoc ngoai rule nay. Day la loi thuc te da gui OCB va bi lech."""
    known = repo.get("known_models")
    if not known:
        return Finding(NA, ["không có danh sách model (known_models.json) để đối chiếu"])
    bad = sorted({t.split(".")[-1].lower() for t in ctx.silver_tables
                  if t.split(".")[-1].lower() not in known})
    if bad:
        ev = []
        for name in bad:
            guess = difflib.get_close_matches(name, known, n=1, cutoff=0.6)
            gt = f" — có phải ý bạn là '{guess[0]}'?" if guess else ""
            ev.append(f"{name} (dòng {first_line(ctx.raw, name)}){gt}")
        return Finding(FAIL, [f"{len(bad)} bảng KHÔNG TỒN TẠI trong Data Vault model thật"
                              f" (kiểm tra lại tên, có thể gõ sai hoặc bảng chưa được tạo): "
                              + "; ".join(ev)])
    if not ctx.silver_tables:
        return Finding(NA, ["script không đọc bảng raw_vault/business_vault nào"])
    return _ok(f"{len(ctx.silver_tables)} bảng Silver đều có thật trong Data Vault model")


@rule("X.11", GX, "Cot doc tu satellite (sat_*) phai TON TAI THAT trong model")
def rx11(ctx: Ctx, repo: dict) -> Finding:
    """Doi chieu cot duoc SELECT/WHERE/GROUP BY/HAVING tu 1 bang sat_* voi danh sach cot
    THAT (engine/known_sat_columns.json, trich list_cols/raw_sql cua tung model .sql trong
    docs/datavault-model-dev_zonec.zip). Chi kiem khi Select do CHI DOC DUNG 1 bang (khong
    co bang/join khac trong CUNG mot Select) de khong nham cot cua bang khac gan vao - truong
    hop phuc tap hon bo qua, KHONG doan bua theo nghiep vu (chi doi chieu voi file model that)."""
    known = repo.get("known_sat_columns") or {}
    uncertain = repo.get("uncertain_sat_tables") or set()
    if not known:
        return Finding(NA, ["không có known_sat_columns.json để đối chiếu"])
    bad, checked_any = [], False
    for st in ctx.statements:
        for tbl in st.find_all(exp.Table):
            name = tbl.name.lower()
            if not name.startswith("sat_") or name not in known or name in uncertain:
                continue
            sel = tbl.parent_select
            if sel is None:
                continue
            others = [t for t in sel.find_all(exp.Table) if t is not tbl and t.parent_select is sel]
            if others:
                continue  # Select doc >=2 bang -> khong chac cot thuoc bang nao, bo qua
            checked_any = True
            real_cols = known[name]
            refs = {c.name.lower() for c in sel.expressions for c in c.find_all(exp.Column)}
            for key in ("where", "group", "having", "qualify"):
                node = sel.args.get(key)
                if node is not None:
                    refs |= {c.name.lower() for c in node.find_all(exp.Column)}
            missing = sorted(c for c in refs if c not in real_cols)
            if missing:
                bad.append(f"{name} (dòng {first_line(ctx.raw, name)}): {missing}")
    if bad:
        return Finding(FAIL, [f"{len(bad)} bảng sat_* đọc cột KHÔNG TỒN TẠI trong model thật: "
                              + "; ".join(bad)])
    if not checked_any:
        return Finding(NA, ["không có bảng sat_* nào đủ điều kiện đối chiếu (Select chỉ đọc 1 bảng)"])
    return _ok("mọi cột đọc từ sat_* đều tồn tại trong model thật")
