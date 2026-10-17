---
name: new-slide
description: 用自然語言建立一份新的論文報告簡報：決定 slide id、執行 just new、寫入 refs.bib、執行 just fill，並編譯確認。當使用者說「幫我建一份新簡報」「開一個新的 slide 報告這篇論文」等需求時使用。
---

# 建立新簡報

依照下列步驟，把使用者的自然語言需求轉成一份可編譯的新 slide。所有指令都在 repo 根目錄執行；使用者的 shell 是 fish，指令避免使用 bash 專屬語法。

## 1. 從需求中取出資訊

| 資訊           | 來源                                           | 缺少時                                                                                        |
| -------------- | ---------------------------------------------- | --------------------------------------------------------------------------------------------- |
| 論文 BibTeX    | 使用者直接貼上；或給 DOI / arXiv id / 論文連結 | 詢問使用者                                                                                    |
| slide id       | 使用者指定                                     | 由論文標題取縮寫（例如 Self-Perturbed Anomaly-Aware Graph Dynamics -> `SPAGD`），並告知使用者 |
| 報告日期       | 使用者提到的日期（例如「下週三報告」）         | 留空                                                                                          |
| summary / tags | 使用者提到時                                   | 保留模板預設值                                                                                |

- slide id 只用英數字與 `-`，因為它同時是資料夾名稱與 release tag（`slides/<id>/v*`）的一部分。
- 先確認 `slides/<id>/` 不存在；已存在時停下來問使用者要換名稱還是更新既有 slide，不要覆寫。

### 取得 BibTeX

- DOI：`curl -sL -H "Accept: application/x-bibtex" https://doi.org/<doi>`
- arXiv：`curl -sL https://arxiv.org/bibtex/<arxiv-id>`
- 只有論文標題時，用網路搜尋找出 DOI 或 arXiv id 再取得；找不到可信來源時請使用者提供，不要自行編造 BibTeX。
- 取得後檢查 `title`、`author`、`year` 是否齊全，並確認 venue 欄位（`booktitle` / `journal` 等）。arXiv 條目沒有正式 venue 時，如果使用者知道發表會議，可在條目加上 `venue = {...}` 欄位（`fill_slide_meta.py` 會優先讀取它）。

## 2. 建立與填入

```bash
just new <id>
```

把 BibTeX 寫入 `slides/<id>/refs.bib`（用 Write 工具），然後：

```bash
just fill <id>             # refs.bib 只有一筆時
just fill <id> <bib-key>   # 多筆時指定要當作封面的條目
```

檢查 `just fill` 的輸出：出現「找不到 ... 這行，略過」代表 `main.typ` 的格式和模板不符，需要手動補上該欄位。

## 3. 補上其他資訊

- 報告日期：修改 `slides/<id>/main.typ` 中 `title-slide(...)` 的 `date: [],`，格式沿用既有 slide，例如 `date: [2026/10/21],`。
- summary / tags：修改 `slides/<id>/meta.toml`。`meta.toml` 的 `date` 是 `just new` 自動填的建立日期，不要改成報告日期。
- 作者過多時（例如超過 8 位），詢問使用者是否縮寫成 `First Author et al.`。

## 4. 驗證

```bash
just build <id>
```

成功產生 `out/<id>.pdf` 才算完成。最後向使用者回報：slide id、填入的標題 / 作者 / venue / 年份 / 日期，以及仍需手動處理的項目（例如 summary 仍為 `TBD`）。不要自動 commit。
