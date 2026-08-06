"""Ha tang chung cho bo check Silver -> Gold: doc file, parse SQL, phan loai profile."""
from __future__ import annotations

import os
import re
from dataclasses import dataclass, field

import sqlglot
from sqlglot import exp

DIALECT = "databricks"

# ---------------------------------------------------------------- nhan dien
SAT_RE = re.compile(r"(?:^|\.)sat_", re.I)
LINK_RE = re.compile(r"(?:^|\.)link_", re.I)
HUB_RE = re.compile(r"(?:^|\.)hub_", re.I)
SILVER_SCHEMA_RE = re.compile(r"\.(raw_vault|business_vault)\.", re.I)
GOLD_SCHEMA_RE = re.compile(r"_curated\.", re.I)
LEGACY_RE = re.compile(r"^\s*GO\s*$", re.I | re.M)
PLACEHOLDER_RE = re.compile(r"<[a-z][a-z0-9_]*>", re.I)
ENV_RE = re.compile(r"ocb_datavault_([a-z0-9]+)_", re.I)
# IDENTIFIER(:cleaned || '.raw_vault.sat_x')  /  IDENTIFIER(:curated)
IDENT_CONCAT_RE = re.compile(
    r"IDENTIFIER\s*\(\s*:(\w+)\s*\|\|\s*'([A-Za-z0-9_.]+)'\s*\)", re.I)
IDENT_PLAIN_RE = re.compile(r"IDENTIFIER\s*\(\s*:(\w+)\s*\)", re.I)
USE_CATALOG_RE = re.compile(r"^\s*USE\s+CATALOG\s+(IDENTIFIER\s*\(\s*:\w+\s*\)|[\w`.]+)", re.I | re.M)
# Ten catalog GIA do tool tu dat khi catalog viet bang bien: IDENTIFIER(:curated) -> ocb_dv_curated
SYNTH_CATALOG_RE = re.compile(r"^ocb_dv_\w+$", re.I)
USE_SCHEMA_RE = re.compile(r"^\s*USE\s+(?:SCHEMA|DATABASE)\s+([\w`.]+)\s*;?", re.I | re.M)
NUMERIC_COL_RE = re.compile(r"(AMT|AMOUNT|BAL|QTY|RATE|CNT|COUNT|NUM|PNL|FTP|VAL)", re.I)

# profile
P_SILVER = "SILVER_CONSUMER"   # doc truc tiep raw_vault/business_vault
P_GOLD = "GOLD_DERIVED"        # chi doc curated (Gold-on-Gold)
P_UPLOAD = "UPLOAD_VIEW"       # view tren bang upload
P_LEGACY = "LEGACY_TSQL"       # code cu on-prem, khong cham
P_SCRIPT = "SCRIPT_ONLY"       # script kiem tra/ad-hoc, khong tao object
P_SCORED = (P_SILVER, P_GOLD, P_UPLOAD)

# SQL doc tu dau: file .sql roi, hay tu sheet 'Script SQL' cua workbook thiet ke
SRC_FILE, SRC_EXCEL = "FILE", "EXCEL"


@dataclass
class Ctx:
    """Ngu canh 1 file SQL dau vao."""
    path: str
    raw: str
    statements: list = field(default_factory=list)
    parse_error: str | None = None
    target: str = ""              # FQN object Gold duoc tao/ghi
    profile: str = P_SCRIPT
    is_dim: bool = False
    cte_aliases: set = field(default_factory=set)
    tables: list = field(default_factory=list)         # FQN thuc the (da tru CTE)
    silver_tables: list = field(default_factory=list)
    gold_tables: list = field(default_factory=list)
    out_columns: list = field(default_factory=list)    # cot dau ra cua object

    target_source: str = "AST"    # AST | COMMENT | FILENAME - target duoc suy tu dau
    source_kind: str = SRC_FILE   # FILE (input/sql/*.sql) | EXCEL (sheet Script SQL)
    mapping: object = None        # MappingDoc cua workbook thiet ke, None neu khong tim thay
    pic: str = ""                 # nguoi phu trach, boc tu ten file workbook (doan cuoi)
    stt: int | None = None        # so thu tu, boc tu ten file workbook (doan dau); None = khong co

    @property
    def label(self) -> str:
        """Ten object de hien thi / ghi vao Excel gui OCB.

        Catalog viet bang bien moi truong (USE CATALOG IDENTIFIER(:curated)) duoc thay tam
        thanh 'ocb_dv_curated' de sqlglot parse duoc - do KHONG phai ten that, tuy moi truong
        moi biet, nen bo di chi hien '<schema>.<object>'. Catalog hard-code thi giu nguyen
        vi do la ten that (va tieu chi X.7 se canh bao viec hard-code)."""
        if not self.target:
            return self.path.replace("\\", "/").split("/")[-1]
        parts = self.target.split(".")
        if len(parts) == 3 and SYNTH_CATALOG_RE.match(parts[0]):
            return ".".join(parts[1:]).upper()
        return self.target.upper()

    @property
    def short(self) -> str:
        return ".".join(self.target.upper().split(".")[-2:]) if self.target else self.label


# ---------------------------------------------------------------- doc & parse
def read_ctx(path: str) -> Ctx:
    with open(path, encoding="utf-8", errors="replace") as fh:
        raw = fh.read()
    return build_ctx(path, raw)


def build_ctx(path: str, raw: str, source_kind: str = SRC_FILE, target_hint: str = "") -> Ctx:
    """Dung Ctx tu text SQL. path chi dung de hien thi va suy ten object khi thieu.

    source_kind = SRC_EXCEL khi SQL lay tu sheet 'Script SQL' cua workbook thiet ke:
    luc do khong co file .sql that nen tieu chi 1.2 bo qua buoc so ten object voi ten file.

    target_hint: ten object THAT (vd. tu mapping.object_from_filename tren ten workbook),
    dung khi SQL khong co INSERT/CREATE de doan target - uu tien hon la doan tu 'path'
    (path luc do la label ghep '<file>.xlsx [Sheet: key]', doan truc tiep tu do se dinh
    them PIC/hau to vao ten object, sai lech voi workbook mapping)."""
    ctx = Ctx(path=path, raw=raw, source_kind=source_kind)

    if LEGACY_RE.search(raw) and re.search(r"\[dbo\]", raw):
        ctx.profile = P_LEGACY
        return ctx

    # placeholder <upload_catalog> chua thay khong parse duoc -> thay tam de van cham duoc,
    # rule 1.1 doc ctx.raw nen van bao FAIL placeholder.
    sanitized = PLACEHOLDER_RE.sub(lambda m: "__ph_" + m.group(0)[1:-1], raw)
    # IDENTIFIER(:cleaned || '.raw_vault.sat_x') -> ocb_dv_cleaned.raw_vault.sat_x
    # (sqlglot coi ca bieu thuc la 1 ten bang, khong tach duoc catalog/schema)
    sanitized = IDENT_CONCAT_RE.sub(lambda m: f"ocb_dv_{m.group(1)}.{m.group(2).lstrip('.')}", sanitized)
    sanitized = IDENT_PLAIN_RE.sub(lambda m: f"ocb_dv_{m.group(1)}", sanitized)
    try:
        ctx.statements = [s for s in sqlglot.parse(sanitized, read=DIALECT) if s is not None]
    except Exception as exc:  # noqa: BLE001 - bao cao nguyen van cho nguoi review
        ctx.parse_error = f"{type(exc).__name__}: {str(exc).splitlines()[0][:200]}"
        ctx.profile = P_SCRIPT
        return ctx

    _fill(ctx, target_hint)
    return ctx


def _fill(ctx: Ctx, target_hint: str = "") -> None:
    for st in ctx.statements:
        ctx.cte_aliases |= {c.alias.lower() for c in st.find_all(exp.CTE) if c.alias}

    ctx.target, ctx.target_source = _target_of(ctx.statements, ctx.raw, ctx.path, target_hint)
    ctx.target = _qualify(ctx.target, ctx.raw)
    ctx.out_columns = _out_columns(ctx.statements)

    seen = set()
    for st in ctx.statements:
        if isinstance(st, exp.Use):          # USE CATALOG/SCHEMA khong phai bang nguon
            continue
        for tbl in st.find_all(exp.Table):
            fqn = _fqn(tbl)
            if not fqn or fqn.lower() in ctx.cte_aliases or fqn.lower() in seen:
                continue
            seen.add(fqn.lower())
            ctx.tables.append(fqn)

    reads = [t for t in ctx.tables if not same_object(t, ctx.target)]
    ctx.silver_tables = [t for t in reads if SILVER_SCHEMA_RE.search("." + t + ".")]
    ctx.gold_tables = [t for t in reads if GOLD_SCHEMA_RE.search(t + ".")]

    if not ctx.target:
        ctx.profile = P_SCRIPT
    elif ctx.silver_tables:
        ctx.profile = P_SILVER
    elif PLACEHOLDER_RE.search(ctx.raw) or re.search(r"_upl\b|upload", ctx.raw, re.I):
        ctx.profile = P_UPLOAD
    else:
        ctx.profile = P_GOLD

    ctx.is_dim = bool(re.search(r"_DIM$", ctx.target.split(".")[-1], re.I))


def pretty_fqn(fqn: str) -> str:
    """Bo ten catalog GIA khoi FQN truoc khi ghi vao bang chung gui OCB."""
    parts = (fqn or "").split(".")
    return ".".join(parts[1:]) if len(parts) == 3 and SYNTH_CATALOG_RE.match(parts[0]) else fqn


def same_object(fqn: str, target: str) -> bool:
    """fqn co phai chinh bang dich khong.

    DDL viet ten tran ('CREATE TABLE tb_x') trong khi ctx.target da duoc _qualify bo sung
    catalog.schema -> so bang FQN se khong khop, bang dich bi tinh nham thanh bang NGUON.
    Khi mot trong hai ben chua qualify thi so ten ngan."""
    a, b = (fqn or "").lower(), (target or "").lower()
    if not a or not b:
        return False
    if a == b:
        return True
    if "." not in a or "." not in b:
        return a.split(".")[-1] == b.split(".")[-1]
    return False


def _qualify(target: str, raw: str) -> str:
    """CREATE TABLE holiday + 'USE CATALOG ... / USE SCHEMA tckh' -> bo sung catalog.schema."""
    if not target or target.count(".") >= 2:
        return target
    parts = target.split(".")
    m_sch = USE_SCHEMA_RE.search(raw)
    if len(parts) == 1 and m_sch:
        parts.insert(0, m_sch.group(1).strip("`"))
    m_cat = USE_CATALOG_RE.search(raw)
    if len(parts) == 2 and m_cat:
        cat = m_cat.group(1).strip("`")
        m_id = IDENT_PLAIN_RE.match(cat)
        parts.insert(0, f"ocb_dv_{m_id.group(1)}" if m_id else cat)
    return ".".join(parts)


def _fqn(tbl: exp.Table) -> str:
    parts = [p.name for p in (tbl.args.get("catalog"), tbl.args.get("db")) if p] + [tbl.name]
    return ".".join(p for p in parts if p)


TARGET_COMMENT_RE = re.compile(
    r"(?:Dich Gold|Dich|Target|Bang dich)\s*:?\s*([a-z0-9_]+\.[a-z0-9_]+\.[a-z0-9_]+)"
    r"|DELETE\s+FROM\s+([a-z0-9_]+\.[a-z0-9_]+\.[a-z0-9_]+)", re.I)


def _target_of(statements: list, raw: str, path: str, target_hint: str = "") -> tuple:
    for st in statements:
        if isinstance(st, exp.Insert):
            node = st.this
            tbl = node.this if isinstance(node, exp.Schema) else node
            if isinstance(tbl, exp.Table):
                return _fqn(tbl), "AST"
    for st in reversed(statements):
        if isinstance(st, (exp.Create,)):
            node = st.this
            tbl = node.this if isinstance(node, exp.Schema) else node
            if isinstance(tbl, exp.Table):
                return _fqn(tbl), "AST"

    # MERGE INTO <bang>: bang DIM chay SCD2/SCD1 bang MERGE thi KHONG can CREATE truoc
    # (bang da ton tai hoac do LDP/APPLY CHANGES tao) - van phai nhan ra day la object dich,
    # neu khong se bi coi la 'script khong tao object Gold' roi Fail sach moi tieu chi.
    for st in statements:
        if isinstance(st, exp.Merge) and isinstance(st.this, exp.Table):
            return _fqn(st.this), "AST"

    # File chi chua SELECT (buoc load do DBX Workflow / DataStage dam nhiem):
    # suy target tu comment 'Dich Gold:' / 'BeforeSQL DELETE FROM', khong thi lay ten file.
    if any(isinstance(st, (exp.Select, exp.Union)) for st in statements):
        m = TARGET_COMMENT_RE.search(raw)
        if m:
            return (m.group(1) or m.group(2)), "COMMENT"
        if target_hint:
            return target_hint, "FILENAME"
        stem = os.path.splitext(os.path.basename(path))[0]
        return stem, "FILENAME"
    return "", "AST"


def _cte_map(st) -> dict:
    """{alias -> exp.Select} cua cac CTE khai trong WITH cua statement, de _select_cols
    'mo' duoc SELECT * FROM <cte> ra danh sach cot that (khac SELECT * tu bang vat ly,
    thuong khong biet truoc cot gi)."""
    out = {}
    for c in st.find_all(exp.CTE):
        if c.alias and isinstance(c.this, exp.Select):
            out[c.alias.lower()] = c.this
    return out


def _leftmost_select(node):
    """UNION ALL cua >=3 khoi la cay lech trai Union(Union(Select1,Select2),Select3) -
    '.left' cua Union ngoai cung co the lai la 1 Union khac, khong phai Select ngay.
    Di xuong toi khi gap Select thuc su (cau truc dau ra giong het cac khoi con lai
    do la UNION ALL, nen lay cot cua khoi dau tien la du)."""
    while isinstance(node, exp.Union):
        node = node.left
    return node if isinstance(node, exp.Select) else None


def _select_cols(sel: exp.Select, ctes: dict, _depth: int = 0) -> list:
    """Cot dau ra cua 1 SELECT. Neu la SELECT * FROM <cte> voi <cte> khai trong CUNG
    WITH, de quy lay cot that cua CTE do thay vi bo cuoc o dau '*' (vd BLOCK1 UNION...
    trong V_TB_NIM_1: CTE BLOCK1 co du danh sach cot ro rang, '*' o SELECT ngoai chi la
    gop lai, khong phai doc bang vat ly khong biet cot)."""
    exprs = sel.expressions
    if len(exprs) == 1 and isinstance(exprs[0], exp.Star) and _depth < 10:
        frm = sel.find(exp.From)          # ten key trong sel.args lech giua ban sqlglot ('from'/'from_')
        table = frm.this if frm else None
        name = table.name.lower() if isinstance(table, exp.Table) else None
        if name and name in ctes:
            return _select_cols(ctes[name], ctes, _depth + 1)
        return []
    return [e.alias_or_name for e in exprs if e.alias_or_name]


def _out_columns(statements: list) -> list:
    """Cot dau ra: uu tien column-list cua INSERT, neu khong co thi lay alias cua SELECT ngoai cung."""
    for st in statements:
        if isinstance(st, exp.Insert) and isinstance(st.this, exp.Schema):
            cols = [c.name for c in st.this.expressions if isinstance(c, exp.Identifier | exp.Column)]
            if cols:
                return cols
    for st in statements:
        # MERGE ... WHEN NOT MATCHED THEN INSERT (col, ...) - cot nam trong 'whens', khong
        # phai statement INSERT rieng nen nhanh tren khong bat duoc. Script MERGE-only
        # (bang dich tao o DDL notebook rieng, khong co CREATE TABLE trong chinh script
        # nay) se khong co cach nao khac de biet cot dau ra ngoai cho nay.
        if isinstance(st, exp.Merge):
            for when in (st.args.get("whens").expressions if st.args.get("whens") else []):
                ins = when.args.get("then")
                if isinstance(ins, exp.Insert) and isinstance(ins.this, (exp.Tuple, exp.Schema)):
                    cols = [c.name for c in ins.this.expressions if isinstance(c, exp.Identifier | exp.Column)]
                    if cols:
                        return cols
    for st in statements:
        if isinstance(st, (exp.Insert, exp.Create)):
            sel = st.expression
            ctes = _cte_map(st)
            if isinstance(sel, exp.Select):
                cols = _select_cols(sel, ctes)
                if cols:
                    return cols
            if isinstance(sel, exp.Union):
                left = _leftmost_select(sel)
                if left is not None:
                    cols = _select_cols(left, ctes)
                    if cols:
                        return cols
    for st in statements:                       # file chi co DDL: CREATE TABLE x (cot ...)
        if isinstance(st, exp.Create) and isinstance(st.this, exp.Schema):
            cols = [c.name for c in st.this.expressions if isinstance(c, exp.ColumnDef)]
            if cols:
                return cols
    for st in statements:                       # file chi co SELECT
        sel = _leftmost_select(st) if isinstance(st, exp.Union) else st
        if isinstance(sel, exp.Select):
            cols = _select_cols(sel, _cte_map(st))
            if cols:
                return cols
    return []


# ---------------------------------------------------------------- helper cho rules
def lines_of(raw: str, pattern: str, flags=re.I) -> list:
    """So dong khop pattern (dung lam bang chung, vi sqlglot khong giu vi tri)."""
    rx = re.compile(pattern, flags)
    return [i for i, line in enumerate(raw.splitlines(), 1) if rx.search(line)]


def first_line(raw: str, needle: str) -> int:
    hits = lines_of(raw, re.escape(needle))
    return hits[0] if hits else 0


def scope_chain(node: exp.Expression) -> list:
    """Chuoi SELECT tu trong ra ngoai chua node."""
    chain, cur = [], node
    while cur is not None:
        sel = cur.parent_select
        if sel is None:
            break
        chain.append(sel)
        cur = sel
    return chain


def predicates(sel: exp.Select) -> list:
    """Moi bieu thuc dieu kien gan voi 1 SELECT: WHERE / QUALIFY / HAVING / JOIN ... ON."""
    out = []
    for key in ("where", "qualify", "having"):
        node = sel.args.get(key)
        if node is not None:
            out.append(node)
    for join in sel.args.get("joins") or []:
        on = join.args.get("on")
        if on is not None:
            out.append(on)
    return out


def has_column(node: exp.Expression, name: str) -> bool:
    return any(c.name.lower() == name.lower() for c in node.find_all(exp.Column))


def has_cutoff(node: exp.Expression, col: str) -> bool:
    """Ton tai <col> <= / < ... trong bieu thuc."""
    for cmp_node in list(node.find_all(exp.LTE)) + list(node.find_all(exp.LT)):
        left = cmp_node.this
        if isinstance(left, exp.Column) and left.name.lower() == col.lower():
            return True
        if isinstance(left, exp.Cast) and has_column(left, col):
            return True
    return False


def in_scope(node: exp.Expression, check) -> bool:
    """check(expr) True o bat ky lop SELECT nao bao quanh node."""
    for sel in scope_chain(node):
        for pred in predicates(sel):
            if check(pred):
                return True
    return False


def sat_refs(ctx: Ctx) -> list:
    """Cac Table node tro tao satellite."""
    out = []
    for st in ctx.statements:
        for tbl in st.find_all(exp.Table):
            fqn = _fqn(tbl)
            if fqn.lower() in ctx.cte_aliases:
                continue
            if SAT_RE.search("." + tbl.name):
                out.append(tbl)
    return out


def window_funcs(ctx: Ctx) -> list:
    out = []
    for st in ctx.statements:
        out.extend(st.find_all(exp.Window))
    return out
