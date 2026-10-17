---
name: slide-figure
description: 在某份 slide 中繪製或修改圖形（示意圖、架構圖、流程圖、函數圖、資料圖表）：優先重用主題元件，否則在 slides/<id>/assets/ 建立獨立的 .typ 圖檔，使用 cetz 0.5.2 / cetz-plot 0.1.4 / fletcher 0.5.8 的最新語法與主題配色，由 main.typ 具名引用並編譯確認。當使用者說「幫我畫一張…圖」「把這張圖改成…」「加一個流程圖 / 圖表」時使用。
---

# 繪製簡報圖形

完整規範在 `guides/figures.md`。開始前先讀它，尤其是第 1 節（版本）、第 3 節（圖檔格式）與第 5 節（語法速查）。下面是執行流程。

## 1. 確認目標

- slide id：使用者正在處理的 `slides/<id>/`；不明確時從對話脈絡或最近修改的 slide 判斷，仍無法確定才詢問。
- 讀 `slides/<id>/main.typ`：確認使用哪個主題、目前的 import、圖要放在哪張 `#slide`。
- 圖的內容：使用者描述、論文圖片（`assets/*.png` 等）或論文文字。從論文圖重繪時，先讀圖片再動手。

## 2. 決定做法

依 `guides/figures.md` 第 2 節的決策表：

1. 主題元件（`flow`、`timeline`、`gantt`、`stat`、`versus`、`mini`、`card`、`callout`、`tag`、`two-col`）能表達的，直接在 `main.typ` 使用，不建立圖檔。
2. 否則選 fletcher（節點與箭頭）、cetz-plot（資料與函數）或 cetz（自由繪圖），可以和主題元件組合。
3. 選擇不明顯時，用一句話告訴使用者選了哪個工具、原因是什麼，然後直接做。

## 3. 建立圖檔

- 路徑 `slides/<id>/assets/<name>.typ`；`<name>` 為 kebab-case；入口函式與檔名同名，簽名包含 `palette: (:)`、`sizes: academic-sizes`。
- 檔案已存在且不是要修改它時，換一個名稱，不要覆寫。
- 頂層只有 import 與 `#let`；`set text(size: ...)` 等樣式寫在函式內；輔助函式以 `_` 開頭。
- 顏色只用 `p.<key>` 與其 `lighten` / `darken`，或 `main-palette`；字級只用 `sizes.<key>`；不設定字型。
- 語法以 `guides/figures.md` 第 5 節與 `docs/refs/` 的原始碼為準。用到速查沒列出的函式時，先用 grep 在 `docs/refs/<pkg>/src/` 找到簽名再寫；cetz 的函式還要確認 `~/.cache/typst/packages/preview/cetz/0.5.2/src/` 裡存在（0.5.3 的功能不能用）。
- 註解用英文，只寫對日後閱讀有幫助的內容。

## 4. 接到主文件

- 在 `main.typ` 開頭、主題 import 之後加上 `#import "assets/<name>.typ": <name>`，必須具名，不可用 `*`。
- 在目標 slide 呼叫，通常是 `#align(center, <name>())`；需要圖說時包 `figure(..., caption: [...])`。
- 不要為了圖去改 `main.typ` 的全域設定（`#set`、`#show`、`palette`）或主題 package。主題確實缺少可重用的元件時，先向使用者提議，不要自行修改 `packages/`。

## 5. 驗證

```bash
just fig <id> <name>    # single figure preview -> out/<id>--<name>.pdf
just build <id>         # whole deck
```

- 兩者都必須成功。除了來自 `theme-academic/.../lib.typ` 的既有字型警告，不能有其他警告。
- 輸出 PNG 檢查版面：`pdftoppm -r 60 -png out/<id>--<name>.pdf <scratchpad>/<name>`，再用 Read 看圖。確認文字沒有重疊或溢出、圖沒有超出內容區、配色來自主題、跟同份 slide 其他頁的觀感一致。有問題就修改後重新驗證。
- 編譯錯誤時先查 refs 原始碼中的簽名，不要用猜的反覆嘗試。

## 6. 回報

告訴使用者：建立 / 修改了哪個檔案、在哪張 slide 引用、用了哪些主題元件或套件，以及刻意做的設計取捨（例如哪個節點用 `accent` 強調）。不要自動 commit。
