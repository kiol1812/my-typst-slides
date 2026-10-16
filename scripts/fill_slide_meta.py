#!/usr/bin/env python3
"""從 slides/<name>/refs.bib 讀取論文資訊，填入 main.typ 與 meta.toml。

用法: fill_slide_meta.py <slide-dir> [bib-key]
預設使用 refs.bib 的第一筆條目；若有多筆，可指定 citation key。
"""
import re
import sys
from pathlib import Path

# venue 欄位的優先順序（取第一個有值的）。想改偏好就調這裡。
VENUE_FIELDS = ["venue", "publisher", "journaltitle", "journal", "booktitle", "eventtitle"]


# ───────── BibTeX / BibLaTeX 解析 ─────────
def _read_braced(s, i):
    """s[i] == '{'，回傳 (內容, 結束位置)。"""
    depth, start = 0, i
    while i < len(s):
        if s[i] == "{":
            depth += 1
        elif s[i] == "}":
            depth -= 1
            if depth == 0:
                return s[start + 1 : i], i + 1
        i += 1
    raise ValueError("bib 大括號不成對")


def parse_bib(text):
    entries, pos = [], 0
    head = re.compile(r"@(\w+)\s*\{\s*([^,\s]+)\s*,")
    while True:
        m = head.search(text, pos)
        if not m:
            break
        body, end = _read_braced(text, text.index("{", m.start()))
        body = body[m.end() - text.index("{", m.start()) - 1 :]
        fields, i = {}, 0
        fld = re.compile(r"\s*,?\s*([A-Za-z][\w-]*)\s*=\s*")
        while True:
            fm = fld.match(body, i)
            if not fm:
                break
            i = fm.end()
            if body[i] == "{":
                val, i = _read_braced(body, i)
            elif body[i] == '"':
                j = i + 1
                while body[j] != '"' or body[j - 1] == "\\":
                    j += 1
                val, i = body[i + 1 : j], j + 1
            else:
                j = i
                while j < len(body) and body[j] not in ",\n":
                    j += 1
                val, i = body[i:j].strip(), j
            fields[fm.group(1).lower()] = val
        entries.append({"type": m.group(1).lower(), "key": m.group(2), "fields": fields})
        pos = end
    return entries


# ───────── 資料清理 ─────────
def clean(s):
    s = s.replace("\\&", "&").replace("\\_", "_").replace("\\%", "%")
    s = re.sub(r"[{}]", "", s)
    return re.sub(r"\s+", " ", s).strip()


def format_authors(raw):
    names = []
    for a in re.split(r"\s+and\s+", raw):
        a = clean(a)
        if "," in a:  # "Last, First" -> "First Last"
            last, first = [p.strip() for p in a.split(",", 1)]
            a = f"{first} {last}".strip()
        names.append(a)
    return ", ".join(names)


def get_year(f):
    m = re.search(r"\d{4}", f.get("date", "") or f.get("year", ""))
    return m.group(0) if m else ""


def get_venue(f):
    for k in VENUE_FIELDS:
        if f.get(k, "").strip():
            return clean(f[k])
    return ""


# ───────── Typst / TOML 跳脫 ─────────
def typ_content(s):  # 用在 [ ... ] 內
    return re.sub(r"([\\#$@*_`<>\[\]~])", r"\\\1", s)


def typ_string(s):  # 用在 "..." 內
    return s.replace("\\", "\\\\").replace('"', '\\"')


def toml_string(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


# ───────── 寫回檔案 ─────────
def sub_line(text, pattern, repl, label):
    new, n = re.subn(pattern, lambda m: repl(m), text, count=1, flags=re.M)
    if n == 0:
        print(f"  ⚠ 找不到 {label} 這行，略過")
    return new


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    d = Path(sys.argv[1])
    key = sys.argv[2] if len(sys.argv) > 2 else ""
    for name in ("refs.bib", "main.typ", "meta.toml"):
        if not (d / name).exists():
            sys.exit(f"找不到 {d / name}")

    entries = parse_bib((d / "refs.bib").read_text(encoding="utf-8"))
    if not entries:
        sys.exit(f"{d}/refs.bib 是空的，請先貼入論文的 BibTeX 條目")
    if key:
        entry = next((e for e in entries if e["key"] == key), None)
        if entry is None:
            sys.exit(f"refs.bib 中沒有 key 為 {key!r} 的條目（現有: {', '.join(e['key'] for e in entries)}）")
    else:
        entry = entries[0]

    f = entry["fields"]
    title = clean(f.get("title", ""))
    authors = format_authors(f["author"]) if "author" in f else ""
    year, venue = get_year(f), get_venue(f)

    print(f"使用條目: {entry['key']}")
    print(f"  title  : {title}")
    print(f"  authors: {authors}")
    print(f"  venue  : {venue}")
    print(f"  year   : {year}")

    # main.typ
    p = d / "main.typ"
    t = p.read_text(encoding="utf-8")
    t = sub_line(t, r'^#let title-text = ".*"[ \t]*$',
                 lambda m: f'#let title-text = "{typ_string(title)}"', "#let title-text")
    for field, val in (("authors", authors), ("venue", venue), ("year", year)):
        t = sub_line(t, rf"^([ \t]*){field}:\s*\[.*\],[ \t]*$",
                     lambda m, v=val, fl=field: f"{m.group(1)}{fl}: [{typ_content(v)}],", field)
    p.write_text(t, encoding="utf-8")

    # meta.toml（只動 title，其餘包含 date/summary 不變）
    p = d / "meta.toml"
    t = p.read_text(encoding="utf-8")
    t = sub_line(t, r"^title\s*=.*$",
                 lambda m: f'title    = "{toml_string(title)}"', "title")
    p.write_text(t, encoding="utf-8")
    print("✓ 已更新 main.typ 與 meta.toml")


if __name__ == "__main__":
    main()
