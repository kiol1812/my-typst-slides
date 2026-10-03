# Typst Slides

用 [Typst](https://typst.app) 撰寫投影片的 monorepo：模板、共用元件與所有 slides 放在同一個 repo，透過 git tag 觸發 GitHub Actions，自動編譯 PDF 並發佈到 Releases。

## 目錄結構

```
.
├─ packages/local/                 # Typst packages，結構為 <namespace>/<name>/<version>/
│  ├─ slide-kit/0.1.0/             # 跨模板共用元件
│  │  ├─ typst.toml
│  │  ├─ lib.typ                   # 只 re-export 公開 API
│  │  └─ src/                      # 內部實作
│  └─ theme-basic/0.1.0/           # 模板（依賴 slide-kit）
│     ├─ typst.toml
│     └─ lib.typ
├─ slides/
│  └─ example/         # 每份 slide 一個資料夾：<日期>-<名稱>
│     ├─ main.typ
│     ├─ meta.toml                 # 標題、日期、標籤等 metadata
│     └─ assets/                   # 該 slide 專用的圖片等資源
├─ fonts/                          # 字型（CI 與本機一致，避免缺字）
├─ scripts/build-index.py          # 掃描 meta.toml 產生索引
├─ docs/                           # 索引輸出（index.md / index.json）
└─ .github/workflows/release.yml   # 推送 tag 時編譯並發佈
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
#import "@local/slide-kit:0.1.0": callout

// slide 引用模板
#import "@local/theme-basic:0.1.0": *
```

好處：

- 日後發佈到 Universe 時，只需把 `@local` 改成 `@preview`。
- 元件版本明確，破壞性改動時複製成新版本資料夾（如 `0.2.0/`），舊 slide 繼續使用舊版。
- `lib.typ` 只公開 API，`src/` 為內部實作，邊界清楚。

### Tag 用於版本與 release，分類用 metadata

Git tag 是整個 repo 共用的名稱，不屬於某個資料夾，所以：

- **Tag**：用帶前綴的命名觸發個別 slide 的 release，格式為 `slides/<slide-id>/v<major>.<minor>.<patch>`，例如 `slides/2026-10-intro-typst/v1.0.0`。
- **分類**：寫在每份 slide 的 `meta.toml`，由腳本產生索引。GitHub Topics 只能標示整個 repo，不適合用來分類個別 slide。

## 使用方式

### 新增一份 slide

1. 建立 `slides/<日期>-<名稱>/`，加入 `main.typ` 與 `meta.toml`。
2. 在 `main.typ` 引用模板：

   ```typst
   #import "@local/theme-basic:0.1.0": *

   #show: deck.with(title: "標題", author: "你的名字", date: "2026-10-03")

   #slide(title: "第一頁")[
     內容
   ]
   ```

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

### 發佈 release

```bash
git tag slides/example/v1.0.0
git push origin slides/example/v1.0.0
```

推送符合 `slides/*/v*` 的 tag 後，workflow 會以 tag 中的 slide id 編譯 `slides/<id>/main.typ`，並把 PDF 附加到對應的 GitHub Release。

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

- **固定 Typst 版本**：workflow 內已指定版本，升級前請先確認舊 slide 的編譯結果沒有改變。各 package `typst.toml` 的 `compiler` 欄位為最低版本需求，請依實際使用版本調整。
- **字型**：模板預設使用 `Noto Sans CJK TC`，請將字型放入 `fonts/`，並確認授權允許放進公開 repo。
- **大型資產**：圖片、影片過大時請使用 Git LFS，或避免放入 repo。
- **元件破壞性改動**：複製成新版本資料夾，更新需要的模板 import，舊 slide 不必動。
- **發佈前請填妥**：各 `typst.toml` 與 workflow 中的作者、`repository`（目前為 `YOUR_NAME` 佔位符）。若要發佈到 Universe，`license` 與 `description` 為必填。

## 字型與授權

### 教育部標準楷書（TW-MOE-Std-Kai）

本專案的模板預設使用教育部標準楷書字型（Version 5.1，收錄 13,084 字，適用 Windows、macOS）。

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
