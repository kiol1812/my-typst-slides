# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案概要

用 Typst 撰寫投影片的 monorepo：共用元件、模板與每份 slide 都在同一個 repo。推送 `slides/<slide-id>/v<x.y.z>` 格式的 tag 會觸發 `.github/workflows/release.yaml`，編譯該 slide 並把 PDF 發佈到 GitHub Release。CI 固定使用 Typst 0.15.1。

## 常用指令

所有編譯都必須帶 `--root . --package-path packages --font-path fonts`，否則 `@local/...` 套件與字型會找不到。`justfile` 已包好：

```bash
just build <slide>          # 編譯 slides/<slide>/main.typ -> out/<slide>.pdf
just watch <slide>          # 即時預覽（會濾掉含 "font" 的警告行）
just new <slide>            # 從 templates/slide/ 建立新 slide（main.typ / meta.toml / refs.bib）
just fill <slide> [bib-key] # 從 refs.bib 填入 main.typ 的標題、作者、venue、年份與 meta.toml 的 title
just fig <slide> <name>     # 單獨預覽 slides/<slide>/assets/<name>.typ 的 <name>() -> out/<slide>--<name>.pdf
python3 scripts/build-index.py [--include-draft]   # 由各 meta.toml 產生 docs/index.md 與 docs/index.json
typst fonts --font-path fonts | grep -i "TW-MOE"   # 確認教育部標準楷書有被載入
```

沒有測試或 lint；驗證方式就是 `just build <slide>` 能成功編譯且沒有缺字警告。`<slide>` 是 `slides/` 下的資料夾名稱（例如 `SPAGD`、`RL4REAl`），也就是 release tag 中的 slide id。

## 架構

三層依賴，皆為放在 repo 內的 Typst package（`packages/local/<name>/<version>/`，以 `@local/<name>:<version>` 引用）：

1. **`slide-kit`**：跨主題共用元件（callout、card、gantt、stat、tag、timeline、mixed 中的 flow/mini/versus 等）。`lib.typ` 只 re-export 公開 API，實作在 `src/`。元件接受 `palette` / `sizes` 參數，預設值來自 `src/style.typ` 的 `default-palette` / `default-sizes`。
2. **主題**（`theme-academic`、`theme-basic`）：以 `#import "@local/slide-kit:<ver>" as kit` 引用元件，定義 `deck`、`slide`、`title-slide`、`section-slide`、`outline-slide` 等版面函式，並把 kit 元件包一層、注入主題自己的 palette/sizes（例如 `theme-academic` 的 `academic-palette`，對外以 `default-palette` 匯出）。
3. **slides**：`slides/<id>/main.typ` 引用主題（目前論文報告都用 `@local/theme-academic:0.1.0`），可另外引用 `@preview/cetz`、`cetz-plot` 等 Universe 套件。每份 slide 附 `meta.toml`（索引用 metadata，`status = "draft"` 不進索引）、`refs.bib`，以及選用的 `assets/`。

`theme-academic` 的 `slide` 簽名是 `slide(title, subtitle: none, outlined: false, body)`，所以寫法為 `#slide[標題][內容]`。

### 版本規則

- import 一律寫死版本。對元件或主題做破壞性改動時，複製成新的版本資料夾（如 `slide-kit/0.1.1/` 之於 `0.1.0/`），更新需要的主題 import，舊 slide 不動。
- 修改既有版本的 package 會影響所有引用它的 slide，改完應重新編譯受影響的 slide 確認。

### 模板與腳本的耦合

`scripts/fill_slide_meta.py` 以正規表示式改寫 `main.typ`，依賴 `templates/slide/main.typ` 中的固定格式：`#let title-text = "..."` 單行，以及 `title-slide(...)` 內 `authors: [...]`、`venue: [...]`、`year: [...]` 各自一行。修改模板時要維持這些行的格式，否則 `just fill` 會失效。

## 圖形

在 slide 中畫任何圖（cetz、cetz-plot、fletcher 或主題元件組合）之前，先讀 `guides/figures.md` 並遵守，即使沒有使用 `slide-figure` skill。重點：

- 版本固定為 `@preview/cetz:0.5.2`、`@preview/cetz-plot:0.1.4`、`@preview/fletcher:0.5.8`。`docs/refs/` 有這些套件的原始碼與文件，是語法的依據；其中 cetz 0.5.3 尚未上架 Universe，它新增的功能不能用。
- 能用主題元件（`flow`、`timeline`、`card` 等）就不要重畫。
- 圖畫在 `slides/<id>/assets/<name>.typ` 的同名函式中，`main.typ` 只能具名 import（不可 `*`），圖檔不能動到主文件的設定。
- 顏色與字級取自主題的 `default-palette` / `academic-sizes`，不寫死顏色、不設定字型。
- 完成後 `just fig` 與 `just build` 都要成功。

## 注意事項

- `fonts/` 內的教育部標準楷書授權為 CC 姓名標示-禁止改作：只能放官方原始檔，不可子集化、轉檔或改名。
- `out/` 與 `docs/` 為產出物，已被 `.gitignore` 忽略。
- `build-index.py` 需要 Python 3.11+（`tomllib`），最新版本連結從 git tag 推得，repo 名稱讀取 `GITHUB_REPOSITORY`。
