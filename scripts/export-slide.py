#!/usr/bin/env python3
"""Export a minimal, self-contained compilable project for one slide.

Usage: export-slide.py <slide>
Output: out/<slide>.zip (top-level folder <slide>/)
"""
import json
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TYPST_VERSION = "0.15.1"
COMPILE_FLAGS = ["--root", ".", "--package-path", "packages", "--font-path", "fonts"]

FONT_DECL = re.compile(r'(?:\bfont\s*:|-font\s*=)\s*(\([^)]*\)|"[^"]*")')
QUOTED = re.compile(r'"([^"]+)"')
IMPORT_PKG = re.compile(r'"@(preview|local)/([a-z0-9-]+):([0-9.]+)"')


def run_typst(args, cwd):
    return subprocess.run(["typst", *args], cwd=cwd, capture_output=True, text=True)


def collect_deps(slide, tmp):
    deps = tmp / "deps.json"
    res = run_typst(
        ["compile", *COMPILE_FLAGS, "--deps", str(deps), "--deps-format", "json",
         f"slides/{slide}/main.typ", str(tmp / "probe.pdf")],
        ROOT,
    )
    if res.returncode != 0:
        sys.exit(f"✗ 無法編譯 slides/{slide}/main.typ：\n{res.stderr}")
    return json.loads(deps.read_text())["inputs"]


def repo_relative(path):
    p = Path(path)
    if p.is_absolute():
        try:
            return p.resolve().relative_to(ROOT)
        except ValueError:
            return None
    return p


def font_families(font_dir):
    res = run_typst(
        ["fonts", "--font-path", str(font_dir), "--ignore-system-fonts", "--ignore-embedded-fonts"],
        ROOT,
    )
    return {line.strip() for line in res.stdout.splitlines() if line.strip()}


def declared_fonts(typ_files):
    fonts = []
    for f in typ_files:
        for decl in FONT_DECL.findall(f.read_text(encoding="utf-8")):
            for name in QUOTED.findall(decl):
                if name not in fonts:
                    fonts.append(name)
    return fonts


def preview_packages(typ_files):
    pkgs = set()
    for f in typ_files:
        for ns, name, ver in IMPORT_PKG.findall(f.read_text(encoding="utf-8")):
            if ns == "preview":
                pkgs.add(f"@preview/{name}:{ver}")
    return sorted(pkgs)


def write_readme(dest, slide, local_pkgs, preview_pkgs, fonts, bundled_fonts):
    compile_cmd = f"typst compile --root . --package-path packages --font-path fonts slides/{slide}/main.typ {slide}.pdf"
    watch_cmd = f"typst watch --root . --package-path packages --font-path fonts slides/{slide}/main.typ {slide}.pdf"

    local_list = "\n".join(f"- `@local/{n}:{v}`（`packages/local/{n}/{v}/`）" for n, v in local_pkgs) or "- （無）"
    preview_list = "\n".join(f"- `{p}`" for p in preview_pkgs) or "- （無）"
    font_list = "\n".join(
        f"- {f}{'（已附在 `fonts/`）' if f in bundled_fonts else ''}" for f in fonts
    ) or "- （未指定，使用 Typst 內建字型）"

    font_note = ""
    if bundled_fonts:
        font_note = (
            "\n`fonts/` 內的字型依其原始授權散布（教育部標準楷書為 CC 姓名標示-禁止改作），"
            "請勿修改、轉檔或子集化。\n"
        )

    install_note = "缺少的字型不會造成編譯失敗，但版面可能略有不同。\n\n"
    if any(n == "theme-academic" for n, _ in local_pkgs):
        install_note = """沒有安裝前面的字型不會造成編譯失敗，但版面可能略有不同。若要與原始 PDF 一致，建議安裝：

- Linux：`Noto Sans CJK TC`、`Noto Serif CJK TC`（Arch：`pacman -S noto-fonts-cjk`；Debian / Ubuntu：`apt install fonts-noto-cjk`），以及 `Liberation Serif`（Arch：`ttf-liberation`；Debian / Ubuntu：`fonts-liberation`）
- Windows：`Times New Roman`、`Microsoft JhengHei`、`PMingLiU` 為系統內建；`Tw Cen MT` 隨 Microsoft Office 安裝

"""

    readme = f"""# {slide}

這是由 [my-typst-slides](https://github.com/kiol1812/my-typst-slides) 匯出的最小可編譯專案，只包含編譯這份簡報需要的檔案。

## 目錄結構

```
{slide}/
├─ slides/{slide}/        # 簡報原始檔（main.typ）、圖檔 assets/ 與參考文獻
├─ packages/local/        # 簡報引用的本地 Typst 套件（只含用到的版本）
{'├─ fonts/                # 隨附字型' + chr(10) if bundled_fonts else ''}└─ README.md
```

## 依賴項目

| 項目 | 說明 |
| --- | --- |
| Typst {TYPST_VERSION} | 編譯器（原專案 CI 使用此版本，其他版本不保證輸出相同） |
| 本地套件 | 已附在 `packages/`，透過 `--package-path packages` 載入 |
| Typst Universe 套件 | 第一次編譯時自動下載，需要網路連線 |
| 字型 | 部分已附在 `fonts/`，其餘需自行安裝或使用系統字型 |

本地套件：

{local_list}

Typst Universe 套件（首次編譯時自動下載並快取，之後可離線編譯）：

{preview_list}

字型（每組依序優先使用第一個已安裝的字型，缺少時自動退回下一個）：

{font_list}
{font_note}
{install_note}可用 `typst fonts --font-path fonts` 確認 Typst 偵測到的字型。

## 安裝 Typst

以下任選一種方式，安裝後執行 `typst --version` 確認版本為 {TYPST_VERSION}。

### Linux

- 官方預編譯執行檔（任何發行版皆可）：

  ```bash
  curl -LO https://github.com/typst/typst/releases/download/v{TYPST_VERSION}/typst-x86_64-unknown-linux-musl.tar.xz
  tar -xf typst-x86_64-unknown-linux-musl.tar.xz
  sudo install typst-x86_64-unknown-linux-musl/typst /usr/local/bin/
  ```

  ARM 機器把 `x86_64` 改成 `aarch64`。

- 套件管理器：Arch Linux `sudo pacman -S typst`；其他發行版可用 `snap install typst` 或 Homebrew `brew install typst`。套件庫中的版本可能不是 {TYPST_VERSION}。
- 從原始碼安裝（需要 Rust）：`cargo install --locked typst-cli --version {TYPST_VERSION}`

### Windows

- winget（Windows 10 / 11 內建）：

  ```powershell
  winget install --id Typst.Typst --version {TYPST_VERSION}
  ```

- Scoop：`scoop install typst`
- 手動安裝：從 [GitHub Releases](https://github.com/typst/typst/releases/tag/v{TYPST_VERSION}) 下載 `typst-x86_64-pc-windows-msvc.zip`，解壓後把 `typst.exe` 所在資料夾加入 `PATH`。

安裝後需重新開啟終端機，`typst` 指令才會生效。

## 編譯

在本資料夾（`README.md` 所在處）開啟終端機執行。Linux 的 bash / zsh / fish 與 Windows 的 PowerShell / cmd 指令相同：

```
{compile_cmd}
```

輸出為 `{slide}.pdf`。三個參數缺一不可：

- `--root .`：以本資料夾為專案根目錄，簡報才能讀取 `slides/` 下的檔案
- `--package-path packages`：讓 `@local/...` 套件從 `packages/` 載入
- `--font-path fonts`：載入隨附字型

編輯時即時預覽（存檔後自動重新編譯）：

```
{watch_cmd}
```

編譯時出現 `unknown font family` 警告表示某個字型未安裝，已自動改用清單中的下一個字型，不影響輸出。
"""
    (dest / "README.md").write_text(readme, encoding="utf-8")


def main():
    if len(sys.argv) != 2:
        sys.exit("用法: export-slide.py <slide>")
    slide = sys.argv[1]
    if not (ROOT / "slides" / slide / "main.typ").is_file():
        sys.exit(f"✗ 找不到 slides/{slide}/main.typ")

    with tempfile.TemporaryDirectory() as t:
        tmp = Path(t)
        deps = collect_deps(slide, tmp)

        files, local_pkgs = set(), set()
        for d in deps:
            rel = repo_relative(d)
            if rel is None:
                continue
            parts = rel.parts
            if parts[:2] == ("packages", "local") and len(parts) > 4:
                local_pkgs.add((parts[2], parts[3]))
            elif parts[0] != "fonts":
                files.add(rel)

        dest = tmp / slide
        shutil.copytree(ROOT / "slides" / slide, dest / "slides" / slide,
                        ignore=shutil.ignore_patterns("meta.toml"))
        for rel in files:
            target = dest / rel
            if not target.exists():
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT / rel, target)
        for name, ver in sorted(local_pkgs):
            shutil.copytree(ROOT / "packages" / "local" / name / ver,
                            dest / "packages" / "local" / name / ver)

        typ_files = sorted(dest.rglob("*.typ"))
        fonts = declared_fonts(typ_files)
        bundled = font_families(ROOT / "fonts") & set(fonts)
        if bundled:
            shutil.copytree(ROOT / "fonts", dest / "fonts")
        else:
            (dest / "fonts").mkdir()

        write_readme(dest, slide, sorted(local_pkgs), preview_packages(typ_files), fonts, bundled)

        res = run_typst(["compile", *COMPILE_FLAGS, f"slides/{slide}/main.typ", str(tmp / "check.pdf")], dest)
        if res.returncode != 0:
            sys.exit(f"✗ 匯出的專案無法獨立編譯：\n{res.stderr}")

        out = ROOT / "out" / f"{slide}.zip"
        out.parent.mkdir(exist_ok=True)
        with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
            for f in sorted(dest.rglob("*")):
                zf.write(f, f.relative_to(tmp))

    print(f"✓ out/{slide}.zip（本地套件：{', '.join(f'{n}:{v}' for n, v in sorted(local_pkgs)) or '無'}）")


if __name__ == "__main__":
    main()
