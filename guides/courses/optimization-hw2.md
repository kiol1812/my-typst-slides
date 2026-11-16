# Optimization HW2：論文略讀簡報

規範原文：`docs/courses/Optimization/[Optimization2026]_HW2_作業指引_中文版.pdf`。本文件把規範對應到這個 repo 的寫法，內容整理自 `slides/S2V-DQN`、`slides/RL4REAl`、`slides/AlphaDev` 的定稿；與 `guides/paper-report.md` 衝突時以本文件為準（不需要 Outline、References、TODO 頁，頁數上限 8）。

## 1. 規格

- 每篇 15 分鐘，**5–8 頁（含封面，不含附錄）**。附錄放在 `appendix.typ`，主文件以 `// #include "appendix.typ"` 保留但不編入。
- 不放 Outline、References、TODO 頁；來源一律寫在各頁 `slide(source: ...)`。`just new <id> compact` 產生的 `#outline-slide()` 與 `#references-slide(...)` 要刪除。
- 只講**一個與最佳化有關的核心機制**和**一項證據**。論文處理多個問題時挑一個講（例如 S2V-DQN 只講 MVC），並在 Problem 頁說明。
- 檢查：`just build <id>`、`just check <id>` 無溢出頁、`just png <id>` 逐頁看版面，最後確認頁數（`pdfinfo out/<id>.pdf`）。

## 2. 頁面配置

| 頁 | `#section` | 標題 | 對應規範 |
| --- | --- | --- | --- |
| 1 | — | 封面 | 1. 論文資訊與報告者 |
| 2 | Problem | Research Problem & Optimization Problem | 2. 研究問題與最佳化問題 |
| 3 | Background | Existing Approaches & Difficulties | 3. 既有做法與困難 |
| 4 | Background | Prerequisite Methods: Core Formulas | 4. 必要前置方法 |
| 5（–6） | Method | Main Method[ (1) / (2)]: ... | 5. 主方法 |
| 6（–7） | Evidence | Evidence[ (1)]: Setup of ... / Evidence (2): Reading ... | 6–7. 證據的設定與解讀 |
| 8 | Summary | Summary, Open Question & Next Steps | 8. 整理與下一步 |

主方法或證據需要兩頁時，拆成 `(1)` / `(2)`，其他頁不增加。證據只有一頁時，設定與解讀都要在同一頁。

## 3. 檔案開頭

```typ
#import "@local/theme-academic:0.2.1": *
#import "@preview/cetz:0.5.2"

#let title-text = "..."

#show: deck.with(footer: [<簡稱> (<First author> et al., <Venue> <Year>)], text-size: 21pt)

#let palette = default-palette + (:)

#set figure(supplement: "Figure", numbering: none)
#show figure: set block(below: 0.6em)
#show table: set text(size: 16pt)
#show footnote.entry: set text(size: 13pt, fill: palette.muted)
#set footnote.entry(clearance: 8pt, gap: 4pt)
#show list: set block(above: 0.55em, below: 0.55em)
#show math.equation.where(block: true): set block(above: 0.5em, below: 0.5em)

#let note(body) = text(size: 15pt, fill: palette.muted, body)
#let src(body) = [Source: <First author> et al. (<Venue> <Year>), #body]
#let eq(n, e) = math.equation(block: true, numbering: (..) => [(#n)], e.body)
```

- `equal-row` 由 theme-academic 0.1.2 / 0.2.1 提供，不要在 slide 中重新定義。並排的 `card` 要等高時用它：`#equal-row(columns: (1fr, 1fr), h => card([A], height: h)[...], h => card([B], height: h)[...])`。
- 頁尾用簡稱與引用格式，不用完整標題。

## 4. 各頁寫法

### 封面

- `authors` 寫全名並以 `#super[...]` 標機構編號，`affiliations` 依論文列出（含 Equal contribution 等註記）。
- `venue` 寫「縮寫 年份 (全名)」，例如 `[NIPS 2017 (Advances in Neural Information Processing Systems 30)]`，`year: []` 留空。**不註明閱讀版本**（不寫 proceedings version、author's version、arXiv 版號）。
- `presenters` 含學號與姓名。

### Problem

- 先一行說明情境；論文涵蓋多個問題時說明「this talk focuses on ...」。
- 最佳化問題用一個具體問題寫，不要拆成 Instance level / Learning level 兩張卡片。依序列出 `*Adjustable*`、`*Given*`、`*Objective*`、`*Constraints*`（或 `*Constraint*`），每項下方可用 `#note[...]` 補一行符號或例子。
- 配一個小例子（自己畫的圖或論文原圖），讓變數與限制有具體對象。

### Existing Approaches & Difficulties

- 用表格：欄位 `Approach` / `How it works` / `Strength` / `Difficulty`，表頭底色 `palette.primary`，`Difficulty` 欄文字用 `palette.accent`。不要用並排的 `card`。
- 表格下方 1–2 個 bullet 點出共同缺口。
- `callout(kind: "info")` 的標題用 `Problem Statement`（直接引用原文的問題敘述）或 `Goal of the authors`，不要自己改寫成「What the authors want to improve」。

### Prerequisite Methods

- 每個前置方法一張 `card`，標題 `A. <方法>`、`B. ...`，內容依序為核心公式、`*Role*:`、`*Difficulty*:`。
- 最後一行固定格式：`*<方法名> keeps* ...; *replaces* ...; *adds* ...`（必要時加 `*trains* ...`）。

### Main Method

- 公式用 `eq(n, $ ... $)` 標上**論文原本的公式編號**；論文沒編號的公式不加。
- 論文有 Algorithm 時照原文逐行列出並加行號，不要縮寫成幾行 `enum`。
- 符號在同頁用 `#note[...]` 一句說明。

### Evidence

- 設定用兩欄表格，表頭 `Term` / `Description`（不要用 Question / Answer），列依序為：`Claim`、`Task / data`、`Model`、`Compared`、`Same`、`Changed`、`Metric`。論文沒交代的項目寫 `Not stated`。
- 解讀用兩張 `card`：
  - `Reading`：指標方向（higher / lower is better）與比較結果，數字取自原文。
  - `Support range`：`*Supports*: ...`、`*Cannot infer*: ...`（可多條）。
- 論文表格以 Typst `table` 重新排版，數值與原文標示（粗體、底色）不變，source 註明 `re-typeset, values unchanged`。
- 表格內的縮寫（例如 baseline 名稱）要在同頁說明。

### Summary

- 一列三個 `mini`（用 `equal-row` 等高）：核心機制的兩個重點 + Evidence。
- `callout(kind: "warn")`，標題 `Open question: ...`：一個具體疑問，附頁碼或公式編號。
- 最後一個 bullet `*Directions for the 40-minute in-depth study*`，下面 1–2 個子項。
- 這頁的 `source` 加上生成式 AI 使用說明：`Assignment note: generative AI (Claude) was used to ...; all statements were checked against the paper.`

## 5. 來源

- 每頁 `slide(source: src[...])`，寫出頁碼與 Sec. / Eq. / Figure / Table / Algorithm 編號；自己畫的圖寫 `diagram self-drawn` 或 `self-drawn from Sec. x`，從多處整理的內容寫 `summarized from Sec. x`。
- 其他論文（前置方法、baseline）用 footnote，只寫 `Author et al., Year`，例如 `#footnote[Schulman et al., 2017]`；不要寫 ref 編號或「not read by the presenter」。

## 6. 繳交

- 檔名格式 `HW2_學號_姓名_<簡稱>.pdf`，另附可編輯原始檔（`just export <id>` 產生 zip）。release 產出的 PDF 是 `<id>.pdf`，上傳前要改名。
