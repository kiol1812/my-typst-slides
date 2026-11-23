# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案概要

用 Typst 撰寫投影片的 monorepo：共用元件、模板與每份 slide 都在同一個 repo。推送 `slides/<slide-id>/v<x.y.z>` 格式的 tag 會觸發 `.github/workflows/release.yaml`，編譯該 slide 並把 PDF 發佈到 GitHub Release。推送 `batch/<name>` tag 則會編譯 `batches/<name>.txt` 列出的所有 slide（每行一個 id），放進同一個 Release。CI 固定使用 Typst 0.15.1。

## 常用指令

所有編譯都必須帶 `--root . --package-path packages --font-path fonts`，否則 `@local/...` 套件與字型會找不到。`justfile` 已包好：

```bash
just build <slide>          # 編譯 slides/<slide>/main.typ -> out/<slide>.pdf
just watch <slide>          # 即時預覽（會濾掉含 "font" 的警告行）
just new <slide> [template] # 從 templates/<template>/ 建立新 slide（預設 slide；compact 為無章節頁版本）
just fill <slide> [bib-key] # 從 refs.bib 填入 main.typ 的標題、作者、venue、年份與 meta.toml 的 title
just fig <slide> <name>     # 單獨預覽 slides/<slide>/assets/<name>.typ 的 <name>() -> out/<slide>--<name>.pdf
just png <slide> [ppi]      # 每頁轉成 PNG 檢查版面 -> out/<slide>-png/
just check <slide>          # 列出內容溢出、被擠到下一頁的頁面（theme-academic 0.1.2 / 0.2.1 以上）
just export <slide>         # 匯出最小可編譯專案（簡報、assets、用到的本地套件版本、README）-> out/<slide>.zip
python3 scripts/build-index.py [--include-draft]   # 由各 meta.toml 產生 docs/index.md 與 docs/index.json
typst fonts --font-path fonts | grep -i "TW-MOE"   # 確認教育部標準楷書有被載入
```

沒有測試或 lint；驗證方式是 `just build <slide>` 能成功編譯且沒有缺字警告，新主題的 slide 再加上 `just check <slide>` 沒有溢出頁。

處理溢出頁時不要調整字級（包含程式碼、圖說、表格與 `#set text(size:)`）。依序嘗試：改變排版（例如 `grid` 改成左右並排、調整欄寬比例、把內容移進 `card` 並排）、縮小圖片或截圖寬度、精簡或拆分內容（文字改動要先徵求使用者同意）。都無法解決時，在對話中列出選項讓使用者決定。例外：表格真的無法靠排版放下時，可以調整表格字級，但必須整份簡報統一（theme-academic 0.2.2 用 `deck(table-size:)` 設定一次），不可讓各頁表格字級不同，也不要在個別表格設定 `#set text(size:)`。

`<slide>` 是 `slides/` 下的資料夾名稱（例如 `SPAGD`、`RL4REAl`），也就是 release tag 中的 slide id。

## 架構

三層依賴，皆為放在 repo 內的 Typst package（`packages/local/<name>/<version>/`，以 `@local/<name>:<version>` 引用）：

1. **`slide-kit`**：跨主題共用元件（callout、card、gantt、stat、tag、timeline、mixed 中的 flow/mini/versus、layout 中的 equal-row 等）。`lib.typ` 只 re-export 公開 API，實作在 `src/`。元件接受 `palette` / `sizes` 參數，預設值來自 `src/style.typ` 的 `default-palette` / `default-sizes`。
2. **主題**（`theme-academic`、`theme-basic`）：以 `#import "@local/slide-kit:<ver>" as kit` 引用元件，定義 `deck`、`slide`、`title-slide`、`section-slide`、`outline-slide` 等版面函式，並把 kit 元件包一層、注入主題自己的 palette/sizes（例如 `theme-academic` 的 `academic-palette`，對外以 `default-palette` 匯出）。
3. **slides**：`slides/<id>/main.typ` 引用主題（既有 slide 用 `0.1.0` / `0.2.0`；`templates/slide/` 的新 slide 用 `0.1.2`，`templates/compact/` 用 `0.2.1`），可另外引用 `@preview/cetz`、`cetz-plot` 等 Universe 套件。每份 slide 附 `meta.toml`（索引用 metadata，`status = "draft"` 不進索引）、`refs.bib`，以及選用的 `assets/`。

`theme-academic` 的 `slide` 簽名是 `slide(title, subtitle: none, outlined: false, body)`（0.1.2 起多了 `source:`，0.2.x 再多 `prefix:`），所以寫法為 `#slide[標題][內容]`。

`theme-academic` 各版本：

| 版本 | 章節 | 主要差異 |
| --- | --- | --- |
| 0.1.0 | `section-slide` 分隔頁 | 原始版本 |
| 0.1.1 | 同上 | 頁尾章節導覽 |
| 0.1.2 | 同上（`templates/slide/`） | 0.1.1 + 下方共同新增功能（slide-kit 0.1.2） |
| 0.2.0 | `#section[...]`，不產生新頁 | 章節顯示在標題上方小字與頁尾導覽；`slide(source:)`、`title-slide(affiliations:)`、`deck(list-sizes:)` |
| 0.2.1 | 同上（`templates/compact/`） | 0.2.0 + 下方共同新增功能；`list-sizes` 改為 `text-size` |
| 0.2.2 | 同上 | 0.2.1 + 統一字級（slide-kit 0.1.3，見下方） |

0.1.2 / 0.2.1 共同新增：
- `deck(text-size:, lang: "en", debug:)`：清單字級改為相對值（放進 `card`、`callout` 會跟著元件字級）；圖表 supplement 依 `lang` 自動顯示 Figure / Table，表格圖說在上方；原本每份 slide 開頭的 `#set` / `#show` 已收進 `deck`，主題也直接匯出 `palette`。`debug: true` 會在溢出頁標紅字。
- `slide(source:)`、`source-figure(body, caption:, source:)`、`note[..]`、`best[..]`、`second[..]`。
- `todo-slide[標題]`（報告者預留頁）、`references-slide(bibliography("refs.bib"))`（`bibliography` 必須在主文件呼叫，路徑才會相對於主文件）。
- `appendix()`：之後的頁碼顯示為 A1、A2、…（0.1.2 會多一張 A 分隔頁）。References 要放在 `appendix()` 之前，否則也會被編成附錄頁碼。
- `title-slide(affiliations:)`；year 空白時不印逗號；只有一位報告者時標籤為 Presenter。
- `equal-row(columns:, gutter:, ..items)`：一列區塊取最高者的高度，每個 item 是接收高度的函式（`h => card(..., height: h)[..]`）。
- `card`、`stat`、`mini` 不會被拆到兩頁；`flow` 的階段可用第三個元素指定顏色。
- 頁尾在有章節時列出可點擊的章節導覽（0.1.1 起），文字太長時導覽移到頁尾線上方靠右。

0.2.2 統一字級（`deck(table-size:)` 可統一調整整份簡報的表格字級，預設同內文），整份簡報只有三層：`body` 20pt（deck 內文預設、表格、`card` / `mini` / `callout` / `timeline` / `stat` 的文字與元件內粗體標題）、`label` 16pt（圖說、註腳、參考文獻、`flow` 說明、`stat` 註記、圖中節點文字）、`small` 14pt（圖內小字、`gantt`）；`stat` 的數字為 32pt。元件輸入也放寬：文字參數接受任何內容（字串、數字、數學式、圖片），`none` 表示省略；顏色參數接受 color 或 palette key（例如 `"accent"`）；`flow` / `timeline` / `gantt` 的項目可寫成 dictionary 或陣列，非必要欄位可省略；新增 `card(head-color:)`（只替標籤上色）與 `hl[..]`（accent 原色的文字強調，也可只用在標籤的部分文字），細節見 `guides/figures.md` 第 2 節。同時修正：References 頁不再顯示上一章的章節小字；`venue` 空白時封面不印開頭逗號；`versus` 的 `+` / `=` 不再超出圓圈。`equal-row` 量測清單時高度偏矮的問題只修在 0.2.2；0.1.2 / 0.2.1 維持原樣，在這兩版用 `equal-row` 放含清單的 `card` 時，最後一行會貼近下框線。

### 版本規則

- import 一律寫死版本。對元件或主題做破壞性改動時，複製成新的版本資料夾（如 `slide-kit/0.1.1/` 之於 `0.1.0/`），更新需要的主題 import，舊 slide 不動。
- 修改既有版本的 package 會影響所有引用它的 slide，改完應重新編譯受影響的 slide 確認。
- 只新增元件、不改既有行為時，可直接加在既有版本（先確認有哪些 slide 引用該版本）。

### 模板與腳本的耦合

`scripts/fill_slide_meta.py` 以正規表示式改寫 `main.typ`，依賴 `templates/*/main.typ` 中的固定格式：`#let title-text = "..."` 單行，以及 `title-slide(...)` 內 `authors: [...]`、`venue: [...]`、`year: [...]` 各自一行。修改模板時要維持這些行的格式，否則 `just fill` 會失效。

## 論文報告

製作或修改任何論文報告簡報時，先讀 `guides/paper-report.md` 並遵守：約 12 分鐘、內文英文且字少、先大方向再細節、必備內容與預留頁面（`TODO`）格式。使用者指定不要修改的部分不做任何更動，建議只在對話中提出。

課程作業的論文報告（規範放在 `docs/courses/<課程>/`）以該課程規範為準，與 `guides/paper-report.md` 衝突時（頁數、時間、TODO 頁、References 頁等）依課程規範，並使用 `compact` 模板。課程若有 `guides/courses/<課程>.md`，先讀它：裡面是依該課程規範整理出的頁面配置與寫法慣例（例如 Optimization HW2 見 `guides/courses/optimization-hw2.md`）。

## 圖形

在 slide 中畫任何圖（cetz、cetz-plot、fletcher 或主題元件組合）之前，先讀 `guides/figures.md` 並遵守，即使沒有使用 `slide-figure` skill。重點：

- 版本固定為 `@preview/cetz:0.5.2`、`@preview/cetz-plot:0.1.4`、`@preview/fletcher:0.5.8`。`docs/refs/` 有這些套件的原始碼與文件，是語法的依據；其中 cetz 0.5.3 尚未上架 Universe，它新增的功能不能用。
- 能用主題元件（`flow`、`timeline`、`card` 等）就不要重畫。
- 圖畫在 `slides/<id>/assets/<name>.typ` 的同名函式中，`main.typ` 只能具名 import（不可 `*`），圖檔不能動到主文件的設定。
- 顏色與字級取自主題的 `default-palette` / `academic-sizes`，不寫死顏色、不設定字型。
- 完成後 `just fig` 與 `just build` 都要成功。
- 論文原圖不要截圖：請使用者下載論文原始檔（arXiv TeX Source 等）放到 `docs/papers/<id>/`，把用到的原始圖檔複製進 `slides/<id>/assets/`（PDF 直接以 `image()` 嵌入）。使用者明確表示找不到原始檔時才截圖。細節見 `guides/paper-report.md` 第 5 節。

## 文件同步

新增功能、修改 packages、模板、justfile、腳本或 workflow 時，同一次修改內一併更新受影響的文件，不要留到之後；完成後在對話中列出改了哪些文件。對照：

| 改動 | 要檢查的文件 |
| --- | --- |
| 新增 / 修改 package 元件或版本 | `CLAUDE.md`（架構、版本表）、`README.md`（目錄結構、範例 import）、`guides/figures.md` 第 2 節元件表、`.claude/skills/slide-figure/SKILL.md` |
| 模板 | `CLAUDE.md`、`README.md`、`.claude/skills/new-slide/SKILL.md`、`guides/courses/*.md`；`just fill` 依賴的行格式不可破壞 |
| justfile 指令、`scripts/` | `CLAUDE.md` 常用指令、`README.md` 使用方式 |
| `.github/workflows/`、tag 或 batch 格式 | `CLAUDE.md` 專案概要、`README.md`（Tag、發佈 release） |
| 新增目錄或頂層檔案 | `README.md` 目錄結構 |
| 寫作 / 圖形規範 | `guides/*.md` 與對應的 skill |

## 注意事項

- `fonts/` 內的教育部標準楷書授權為 CC 姓名標示-禁止改作：只能放官方原始檔，不可子集化、轉檔或改名。
- `out/` 與 `docs/` 為產出物，已被 `.gitignore` 忽略。
- `build-index.py` 需要 Python 3.11+（`tomllib`），最新版本連結從 git tag 推得，repo 名稱讀取 `GITHUB_REPOSITORY`。
