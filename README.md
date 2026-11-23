# Typst Slides

用 [Typst](https://typst.app) 撰寫投影片的 monorepo：模板、共用元件與所有 slides 放在同一個 repo，透過 git tag 觸發 GitHub Actions，自動編譯 PDF 並發佈到 Releases。

## 目錄結構

```
.
├─ packages/local/                 # Typst packages，結構為 <name>/<version>/，以 @local/<name>:<version> 引用
│  ├─ slide-kit/
│  │  ├─ 0.1.0/                    # callout、code-block（theme-basic 使用）
│  │  ├─ 0.1.1/                    # callout、card、gantt、stat、tag、timeline、flow 等
│  │  ├─ 0.1.2/                    # 0.1.1 + note / best / second、equal-row 等
│  │  └─ 0.1.3/                    # 0.1.2 + 統一字級（body 20 / label 16 / small 14）、寬鬆輸入、hl
│  │     ├─ typst.toml
│  │     ├─ lib.typ                # 只 re-export 公開 API
│  │     └─ src/                   # 內部實作
│  ├─ theme-academic/              # 論文報告主題；各版本差異見 CLAUDE.md
│  │  ├─ 0.1.0/ 0.1.1/ 0.1.2/      # section-slide 分隔頁（0.1.2 依賴 slide-kit 0.1.2）
│  │  └─ 0.2.0/ 0.2.1/ 0.2.2/      # #section[...] 不產生新頁（0.2.1 依賴 slide-kit 0.1.2，0.2.2 依賴 0.1.3）
│  └─ theme-basic/0.1.0/           # 簡易主題（依賴 slide-kit 0.1.0）
├─ templates/
│  ├─ slide/                       # `just new` 預設模板（主題版本在 `just new` 時選定，見 `just versions`）
│  └─ compact/                     # `just new <id> compact`，有頁數上限的課程報告
├─ slides/
│  ├─ example/                     # 元件展示範例
│  └─ <slide-id>/                  # 每份 slide 一個資料夾（例如 SPAGD、RL4REAl、AlphaDev）
│     ├─ main.typ
│     ├─ appendix.typ              # 選用，附錄頁
│     ├─ meta.toml                 # 標題、日期、標籤等 metadata
│     ├─ refs.bib                  # 參考文獻，`just fill` 也從這裡讀取論文資訊
│     └─ assets/                   # 該 slide 專用的圖檔（論文原圖、<name>.typ 自繪圖）
├─ batches/<name>.txt              # batch release 的 slide 清單（每行一個 slide id）
├─ guides/
│  ├─ paper-report.md              # 論文報告簡報指南
│  ├─ figures.md                   # 圖形繪製指南（cetz / cetz-plot / fletcher）
│  └─ courses/                     # 各課程作業的頁面配置與寫法慣例
├─ fonts/                          # 字型（CI 與本機一致，避免缺字）
├─ scripts/
│  ├─ build-index.py               # 掃描 meta.toml 產生索引
│  ├─ fill_slide_meta.py           # 從 refs.bib 填入 slide 的標題、作者等資訊
│  ├─ export-slide.py              # `just export`：匯出最小可編譯專案
│  └─ template_versions.py         # `just new` / `just versions`：模板可選的主題版本
├─ docs/                           # 不進版控：索引輸出、課程規範、論文原始檔、套件參考文件
├─ .claude/skills/                 # Claude Code skills（new-slide、slide-figure）
├─ CLAUDE.md                       # 給 Claude Code 的專案說明（架構、版本、規範）
├─ justfile                        # build / watch / new / fill / fig / png / check / export
└─ .github/workflows/release.yaml  # 推送 tag 時編譯並發佈
```

## 設計重點

### 為什麼用 monorepo

- 任一個 tag checkout 下來，模板、元件與 slide 的版本自然對齊，可重現。
- 避免 submodule 的操作負擔。
- 日後想公開模板，可用 `git subtree split` 或 `git filter-repo` 拆出並保留歷史。

### 模板與元件都做成 Typst package

Typst 不支援從 git repo 取得依賴，套件來源只有 Typst Universe、`@local` 命名空間，以及專案內相對路徑。本專案把 packages 放在 repo 內，編譯時用 `--package-path packages` 指向它們，再以 `@local/...` 引用：

```typst
// 模板引用共用元件（版本寫死，確保可重現）
#import "@local/slide-kit:<version>" as kit

// slide 引用模板
#import "@local/theme-academic:<version>": *
```

好處：

- 日後發佈到 Universe 時，只需把 `@local` 改成 `@preview`。
- 元件版本明確，破壞性改動時複製成新版本資料夾（如 `0.2.0/`），舊 slide 繼續使用舊版。
- `lib.typ` 只公開 API，`src/` 為內部實作，邊界清楚。

### Tag 用於版本與 release，分類用 metadata

Git tag 是整個 repo 共用的名稱，不屬於某個資料夾，所以：

- **Tag**：用帶前綴的命名觸發個別 slide 的 release，格式為 `slides/<slide-id>/v<major>.<minor>.<patch>`，例如 `slides/SPAGD/v1.0.0`；多份 slide 一起發佈時用 `batch/<name>`（見[發佈 release](#發佈-release)）。
- **分類**：寫在每份 slide 的 `meta.toml`，由腳本產生索引。GitHub Topics 只能標示整個 repo，不適合用來分類個別 slide。

## 使用方式

### 新增一份 slide

1. 建立 slide 資料夾（從 `templates/<template>/` 複製，`meta.toml` 的日期自動填今天）：

   ```bash
   just new <slide-id>                 # templates/slide，一般論文報告
   just new <slide-id> compact         # templates/compact，有頁數上限的課程報告
   just new <slide-id> compact 0.2.1   # 指定主題版本；不指定時終端機會詢問（預設最新版）
   just versions                       # 各模板可選的主題版本與預設版本
   ```

   模板的 import 是 `:<version>` 佔位，`just new` 會換成選定的版本。建立後會提示：內容寫完要刪除 `main.typ` 中以 `// 提醒：` 開頭的註解。

   論文報告的內容與頁面規範見 `guides/paper-report.md`；課程作業另見 `guides/courses/`。

2. 把論文的 BibTeX 貼進 `slides/<slide-id>/refs.bib`，再自動填入標題、作者、venue 與年份：

   ```bash
   just fill <slide-id>            # 使用 refs.bib 的第一筆
   just fill <slide-id> <bib-key>  # 有多筆時指定 citation key
   ```

   此腳本會改寫 `main.typ` 中 `#let title-text = "..."` 以及 `title-slide(...)` 的 `authors:`、`venue:`、`year:` 這幾行，與 `meta.toml` 的 `title`。修改模板時請保持這些行的格式。

3. 在 `main.typ` 撰寫內容（`theme-academic`）：

   ```typst
   #section-slide[Introduction]    // 0.1.x：產生章節分隔頁
   #section[Introduction]          // 0.2.x：不產生新頁，標在下一張 slide 的標題上方

   #slide[第一頁標題][
     內容
   ]
   ```

   可用元件（`callout`、`card`、`stat`、`tag`、`timeline`、`gantt`、`flow`、`mini`、`versus`、`two-col`、`equal-row`、`note` 等）定義於 `packages/local/theme-academic/<version>/lib.typ`，各版本差異見 `CLAUDE.md`；`slides/example/main.typ` 有部分元件的使用範例。圖表可另外引用 Universe 套件（`@preview/cetz:0.5.2`、`@preview/cetz-plot:0.1.4`、`@preview/fletcher:0.5.8`），首次編譯時 Typst 會自動下載；繪圖規範見 `guides/figures.md`。

### `meta.toml` 欄位

```toml
title    = "Typst 入門"        # 必填
date     = 2026-10-03          # 必填，TOML 原生日期（不加引號）
tags     = ["typst", "intro"]  # 選填，用於分類
template = "theme-basic"       # 選填，所用模板名稱
status   = "published"         # published（預設）或 draft；draft 不進索引
lang     = "zh-TW"             # 選填
subtitle = "用程式寫投影片"     # 選填
summary  = "一句話簡介。"       # 選填，顯示於索引
```

### 本機編譯

```bash
mkdir -p out
typst compile --root . --package-path packages --font-path fonts \
  slides/example/main.typ out/example.pdf

# 即時預覽
typst watch --root . --package-path packages --font-path fonts \
  slides/example/main.typ out/preview.pdf
```

```bash
# or justfile (in arch, sudo pacman -S just)

just build example

# 即時預覽
just watch example
```

其他檢查與輸出：

```bash
just fig <slide> <name>   # 單獨預覽 slides/<slide>/assets/<name>.typ -> out/<slide>--<name>.pdf
just png <slide> [ppi]    # 每頁轉成 PNG -> out/<slide>-png/
just check <slide>        # 列出內容溢出的頁面（theme-academic 0.1.2 / 0.2.1 以上）
just export <slide>       # 匯出最小可編譯專案 -> out/<slide>.zip
just versions             # 各模板可選的主題版本與預設版本
```

### 發佈 release

```bash
git tag slides/example/v1.0.0
git push origin slides/example/v1.0.0
```

推送符合 `slides/*/v*` 的 tag 後，workflow 會以 tag 中的 slide id 編譯 `slides/<id>/main.typ`，並把 PDF 附加到對應的 GitHub Release。

一次發佈多份 slide 到同一個 Release 時，在 `batches/<name>.txt` 列出 slide id（每行一個，`#` 之後為註解），commit 後推送 `batch/<name>` tag：

```bash
printf 'AlphaDev\nRL4REAl\n' > batches/w2.txt
git add batches/w2.txt && git commit -m "chore: add w2 batch"
git tag batch/w2
git push origin batch/w2
```

workflow 會依序編譯清單中的 slide，全部 PDF 附加到 `batch/w2` 這個 Release。`build-index.py` 只看 `slides/<id>/v*` tag，batch release 不會出現在索引的下載連結中。

### 產生索引

```bash
python3 scripts/build-index.py                  # 輸出 docs/index.md 與 docs/index.json
python3 scripts/build-index.py --include-draft  # 包含草稿
```

- 需要 Python 3.11 以上（使用內建 `tomllib`），沒有第三方依賴。
- 索引包含依日期排序的總表，以及依標籤分組的清單。
- 最新版本連結由 git tag 推得；repo 名稱讀取環境變數 `GITHUB_REPOSITORY`（Actions 內自動提供，本機可手動設定）。
- 在 CI 執行時，`actions/checkout` 需設定 `fetch-depth: 0` 與 `fetch-tags: true`，否則讀不到 tag。

## 維護注意事項

- **固定 Typst 版本**：workflow 固定使用 Typst `0.15.1`，升級前請先確認舊 slide 的編譯結果沒有改變。各 package `typst.toml` 的 `compiler` 欄位（目前為 `0.13.0`）為最低版本需求，請依實際使用版本調整。
- **字型**：`theme-academic` 內文使用 Times New Roman / Tinos / Liberation Serif 與 Noto Serif CJK TC 等字型清單，標題列與頁尾使用 Tw Cen MT / Noto Sans CJK TC 等，這些字型不在 `fonts/` 內，會從系統字型中依序尋找；`theme-basic` 使用 `fonts/` 內的教育部標準楷書。新增字型到 `fonts/` 前請確認授權允許放進公開 repo。
- **大型資產**：圖片、影片過大時請使用 Git LFS，或避免放入 repo。
- **元件破壞性改動**：複製成新版本資料夾（如 `slide-kit/0.1.0` → `0.1.1`），更新需要的模板 import，舊 slide 不必動。只新增元件時可直接改既有版本，改完重新編譯引用它的 slide。
- **發佈到 Universe**：各 `typst.toml` 已填妥作者、`license`、`description` 與 `repository`，發佈時只需把 import 的 `@local` 改成 `@preview`。

## 字型與授權

### 教育部標準楷書（TW-MOE-Std-Kai）

`theme-basic` 模板預設使用教育部標準楷書字型（Version 5.1，收錄 13,084 字，適用 Windows、macOS）。

- **來源**：請自教育部「國語辭典」相關網站（language.moe.gov.tw）下載，原始檔案放入 `fonts/`。
- **授權**：創用 CC「姓名標示－禁止改作」。
  - 引用時請標示「**中華民國教育部**」。
  - **請勿將字型檔修改後再散布**（例如子集化、轉檔、改名後放進本 repo）。`fonts/` 內只放官方原始檔案。
  - 若有授權以外的使用需求（例如修改字型），須敘明使用方式與目的，以書面向教育部終身教育司申請。
    - 地址：臺北市中正區中山南路 5 號
    - 電話：(02) 7736-6820
- **字數限制**：本字型收錄 13,084 字，罕用字可能缺字，編譯時請留意 Typst 的缺字警告。

### 其他字型

`New Computer Modern` 為 Typst 內建字型，不需另外安裝。

### 確認字型有被載入

```bash
typst fonts --font-path fonts | grep -i "TW-MOE"
```

若沒有輸出，代表 Typst 找不到該字型，編譯結果會悄悄改用其他字型。建議在 CI 加入同樣的檢查步驟。

## 授權

MIT
