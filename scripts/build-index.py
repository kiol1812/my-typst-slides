#!/usr/bin/env python3
"""掃描 slides/*/meta.toml，產生 docs/index.md 與 docs/index.json。

需要 Python 3.11+（內建 tomllib），無第三方依賴。
最新 release 連結由 git tag（slides/<id>/v*）推得；
repo 名稱讀取環境變數 GITHUB_REPOSITORY（在 Actions 內自動存在）。
"""
import argparse
import json
import os
import subprocess
import sys
import tomllib
from collections import defaultdict
from pathlib import Path
from urllib.parse import quote

REQUIRED = ("title", "date")


def load_slides(root: Path, include_draft: bool) -> list[dict]:
    slides = []
    for meta_path in sorted((root / "slides").glob("*/meta.toml")):
        slide_id = meta_path.parent.name
        try:
            meta = tomllib.loads(meta_path.read_text(encoding="utf-8"))
        except tomllib.TOMLDecodeError as e:
            sys.exit(f"[error] {meta_path}: TOML 解析失敗: {e}")
        missing = [k for k in REQUIRED if k not in meta]
        if missing:
            sys.exit(f"[error] {meta_path}: 缺少必要欄位 {missing}")
        if meta.get("status", "published") == "draft" and not include_draft:
            continue
        meta["id"] = slide_id
        meta["date"] = str(meta["date"])  # TOML 日期 -> ISO 字串
        meta["tags"] = sorted(set(meta.get("tags", [])))
        slides.append(meta)
    return slides


def latest_tag(root: Path, slide_id: str) -> str | None:
    try:
        out = subprocess.run(
            ["git", "tag", "--list", f"slides/{slide_id}/v*", "--sort=-v:refname"],
            cwd=root, capture_output=True, text=True, check=True,
        ).stdout.split()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
    return out[0] if out else None


def release_url(repo: str | None, tag: str | None) -> str | None:
    if not (repo and tag):
        return None
    return f"https://github.com/{repo}/releases/tag/{quote(tag, safe='/')}"


def download_cell(s: dict) -> str:
    if s["release_url"]:
        return f"[{s['latest_tag'].rsplit('/', 1)[-1]}]({s['release_url']})"
    return "—"


def render_markdown(slides: list[dict]) -> str:
    lines = ["# Slides 索引", ""]
    lines += ["## 全部（新到舊）", "",
              "| 日期 | 標題 | 標籤 | 下載 |", "|---|---|---|---|"]
    for s in slides:
        tags = " ".join(f"`{t}`" for t in s["tags"])
        lines.append(f"| {s['date']} | {s['title']} | {tags} | {download_cell(s)} |")

    by_tag: dict[str, list[dict]] = defaultdict(list)
    for s in slides:
        for t in s["tags"]:
            by_tag[t].append(s)

    lines += ["", "## 依標籤", ""]
    for tag in sorted(by_tag):
        lines += [f"### {tag}", ""]
        for s in by_tag[tag]:
            summary = f" — {s['summary']}" if s.get("summary") else ""
            lines.append(f"- {s['date']} **{s['title']}** ({download_cell(s)}){summary}")
        lines.append("")
    return "\n".join(lines) + "\n"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    ap.add_argument("--out", type=Path, default=None, help="輸出資料夾（預設 <root>/docs）")
    ap.add_argument("--include-draft", action="store_true")
    args = ap.parse_args()

    out_dir = args.out or args.root / "docs"
    out_dir.mkdir(parents=True, exist_ok=True)
    repo = os.environ.get("GITHUB_REPOSITORY")

    slides = load_slides(args.root, args.include_draft)
    for s in slides:
        s["latest_tag"] = latest_tag(args.root, s["id"])
        s["release_url"] = release_url(repo, s["latest_tag"])
    slides.sort(key=lambda s: s["date"], reverse=True)

    (out_dir / "index.md").write_text(render_markdown(slides), encoding="utf-8")
    (out_dir / "index.json").write_text(
        json.dumps(slides, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"wrote {len(slides)} slides -> {out_dir}")


if __name__ == "__main__":
    main()
