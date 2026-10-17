# 簡報圖形指南

在 slide 中繪製圖形（示意圖、流程圖、資料圖表）時的規範。目標：

1. 只用目前可從 Typst Universe 取得的最新版本與其語法，且一定要能編譯。
2. 每張圖放在 `slides/<id>/assets/<name>.typ`，主文件只引用一個函式，不受圖檔影響。
3. 優先重用 `packages/` 內的主題元件，配色與字級一律取自主題。

## 1. 版本與語法來源

| 套件      | import 寫法                                                          | 語法參考                                                                  |
| --------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| cetz      | `#import "@preview/cetz:0.5.2"`                                      | `docs/refs/cetz-0.5.3/`（`docs/`、`src/draw/`、`manual.pdf`）             |
| cetz-plot | `#import "@preview/cetz-plot:0.1.4": plot, chart`                    | `docs/refs/cetz-plot-0.1.4/`（`src/plot/`、`src/chart/`、`gallery/`）     |
| fletcher  | `#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge` | `docs/refs/fletcher-0.5.8/`（`docs/manual.typ`、`docs/gallery/`、`src/`） |

- `docs/refs/cetz-0.5.3` 是 GitHub release，**Universe 上最新只有 0.5.2**，寫 `cetz:0.5.3` 會出現 `version 0.5.3 does not exist`。因此 import 用 0.5.2，refs 只當文件看。0.5.3 獨有、0.5.2 沒有的功能不能用：`cetz.make-ctx`，以及 `line` 的 `pt-n` 錨點（0.5.2 會報 `Anchor 'pt-1' not in anchors`）；不確定時以 `~/.cache/typst/packages/preview/cetz/0.5.2/src/` 實際原始碼為準。等 0.5.3 上架後再升版。
- cetz-plot 0.1.4 內部依賴 cetz 0.5.2（`plot` 只接受 0.5.x 的 canvas），兩者搭配沒有問題。
- fletcher 0.5.8 內部用的是 cetz **0.3.4**，與外層的 cetz 0.5.2 互不相干。在 fletcher 的 `render`、自訂 `shape` 等 callback 裡要畫 cetz 圖形時，必須用 `fletcher.cetz.draw`，不能混用 `cetz:0.5.2` 的 draw 函式。
- 查語法時以 refs 原始碼中的函式簽名為準（例如 `grep -n "^#let add(" -A25 docs/refs/cetz-plot-0.1.4/src/plot/line.typ`），不要憑記憶使用舊版 API（例如 cetz 0.2 時代的 `"left"`、`"top"` 錨點名稱，或 0.5 已改名的 `on-yz`）。
- 既有 slide 的 import 不需要改。

## 2. 先找可重用的元件

`theme-academic` 已經包好以下元件並注入主題配色，能用就不要重畫：

| 需求                                   | 用法                                                                |
| -------------------------------------- | ------------------------------------------------------------------- |
| 線性的步驟 / pipeline 階段（可分兩區） | `flow(((title, sub), ...), split: n, zone-a: "...", zone-b: "...")` |
| 年代、里程碑                           | `timeline(items: ((year: [..], title: [..], desc: [..]), ...))`     |
| 排程                                   | `gantt(rows, total: 16, mid: 8)`                                    |
| 重點數字                               | `stat(value, label, note: ..)`                                      |
| A + B = C 式的組合                     | `versus(left, right, result)`                                       |
| 字母編號的條列方塊                     | `mini(letter, name)[說明]`                                          |
| 含標題的方塊 / 註解框 / 小標籤         | `card(head)[..]`、`callout(title: .., kind: ..)[..]`、`tag[..]`     |
| 左右分欄                               | `two-col(ratio: (1fr, 1fr))[左][右]`                                |

上面都不適用時，依圖形性質選工具：

| 圖形性質                                                   | 工具                                     |
| ---------------------------------------------------------- | ---------------------------------------- |
| 節點與箭頭：有分岔、回饋、跨列連線的流程圖、架構圖、狀態機 | fletcher                                 |
| 函數曲線、資料點、長條圖、圓餅圖                           | cetz-plot（`plot`、`chart`）             |
| 幾何、座標、張量 / 網路結構示意、需要精確定位的自由繪圖    | cetz                                     |
| 只是幾個方塊水平排列                                       | `grid` + `block` + 主題元件，不必上 cetz |

複雜的圖也可以組合：例如在 `grid` 裡放幾張 `card`，中間用 fletcher 圖。

## 3. 圖檔格式

### 位置與命名

- 路徑：`slides/<id>/assets/<name>.typ`，`<name>` 用 kebab-case，描述圖的內容（`encoder-arch.typ`、`loss-curve.typ`）。
- 每個檔案匯出一個與檔名同名的入口函式；同主題的多張相關圖可以放同一檔，各自一個函式。
- 檔內輔助函式以 `_` 開頭（`_box`、`_arrow`），表示不對外使用。

### 檔案骨架

```typ
#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.1.0": default-palette, academic-sizes

#let encoder-arch(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.label)
  cetz.canvas({
    import cetz.draw: *
    // ...
  })
}
```

規則：

- **主題名稱一律具名 import**（`default-palette`、`academic-sizes`、`main-palette`、`card` 等），不要 `#import "@local/theme-academic:0.1.0": *`。
- **入口函式的參數沿用主題慣例**：`palette: (:)` 與 `sizes: academic-sizes`，函式內用 `let p = default-palette + palette`。需要可調的內容（資料、標籤）也做成參數。
- **檔案頂層只放 import 與 `#let`**。不要有頂層的 `#set`、`#show`、可見內容或測試呼叫；樣式設定寫在函式內，只作用於該圖。
- **不要設定字型**，沿用 `deck` 的字型；只用 `sizes` 設定字級。
- slide 使用的主題不是 `theme-academic` 時（例如 `theme-basic` 沒有 palette），改從 `@local/slide-kit:0.1.1` 匯入 `default-palette`、`default-sizes`。

### 主文件引用

```typ
#import "@local/theme-academic:0.1.0": *
#import "assets/encoder-arch.typ": encoder-arch

#slide[Architecture][
  #align(center, encoder-arch())
]
```

- import 放在檔案開頭、主題 import 之後（與 `RL4REAl/main.typ` 一致），**只能具名 import 入口函式**。`import "assets/x.typ": *` 會把圖檔內部 import 的名稱（例如 `card`）一併帶進主文件，可能遮蔽主題或主文件的同名變數。
- 主文件不需要為了圖檔 import cetz / fletcher；圖檔自己負責。
- 要編號圖說時再包 `figure(encoder-arch(), caption: [...])`，圖說樣式由主題處理。
- 頂層 `#set` / `#show` 不會從被 import 的檔案外洩（已實測），但「頂層只放 `#let`」的規則仍要遵守，避免圖檔單獨看時誤導。

## 4. 配色與字級

一律從 palette 取色，不要寫死 `rgb(...)`（`RL4REAl/assets/` 的舊檔是例外，不必改）。

| palette key                          | 顏色                  | 建議用途                               |
| ------------------------------------ | --------------------- | -------------------------------------- |
| `primary`                            | `#334E86` 藍          | 主要節點、主要資料系列                 |
| `accent`                             | `#F9604D` 珊瑚紅      | 強調：本文方法、關鍵路徑、需注意的部分 |
| `surface`                            | `#467886` 青藍        | 次要元素、輔助標註                     |
| `text`                               | `#0E3445` 深藍        | 線條、箭頭、座標軸、文字               |
| `muted`                              | `#7F7F7F` 灰          | 說明文字、格線、不重要的元素           |
| `positive` / `caution` / `highlight` | `primary` 的淺 / 深色 | 同色系的第二、三層次                   |

- 填色用淡化版本：`p.primary.lighten(85%)`～`lighten(90%)` 搭配 `1.2pt + p.primary` 外框，與 `flow`、`card` 的觀感一致。
- 需要更多同色系層次時，`main-palette` 提供 `light-80` … `base` … `dark-80`。
- 一張圖的主要顏色控制在 `primary` + `accent` 兩色，其他用 `muted` 或淡化色。
- 線寬：主要線條 `1.2pt`，資料曲線 `2pt`，格線與次要線 `0.6pt`～`0.8pt`。

| sizes key | 值   | 用途                         |
| --------- | ---- | ---------------------------- |
| `body`    | 20pt | 圖中較大的標題文字           |
| `label`   | 16pt | 節點文字（預設）             |
| `small`   | 14pt | 座標軸刻度、邊上的標籤、圖例 |

### 尺寸

- 投影片 960 × 540 pt；扣掉邊距後內容寬約 890pt（約 31cm）、標題下方可用高度約 400pt（約 14cm）。
- cetz 預設 `length: 1cm`，所以座標與 `plot.plot(size: (w, h))` 的單位都是 cm：整頁寬的圖 `w` 不超過約 28，雙欄裡的圖不超過約 13，高度一般不超過約 9。
- canvas 的文字不隨 `length` 縮放，調整整體大小時改 `length` 會讓文字比例跑掉，優先調整座標或 `size`。

## 5. 語法速查（皆已在本 repo 實測編譯）

### cetz 0.5

```typ
cetz.canvas(length: 1cm, {
  import cetz.draw: *
  set-style(
    stroke: 1.2pt + p.text,
    rect: (radius: 0.15),
    mark: (end: "stealth", fill: p.text),   // all lines get an arrow head
  )
  rect((0, 0), (3, 1.2), fill: p.primary.lighten(85%), stroke: 1.2pt + p.primary, name: "q")
  content("q", [Query])                       // element name = its center
  rect((4.5, 0), (7.5, 1.2), fill: p.accent.lighten(85%), stroke: 1.2pt + p.accent, name: "k")
  content("k", [Key])
  line("q.east", "k.west", name: "e")
  content("e.mid", anchor: "south", padding: 0.15, text(size: sizes.small, fill: p.muted)[score])
})
```

- 錨點：元件邊界用方位名稱 `north`、`south-east`、`center` 等；路徑用 `start`、`mid`、`end`。中間點要另外取名：拆成多段 `line` 或用 `anchor("p", (x, y))`。
- 箭頭：`line(a, b, mark: (end: ">"))`；常用符號 `">"`、`"stealth"`、`"|"`、`"o"`、`"<>"`。也可用 `set-style(mark: ...)` 統一設定。
- 群組：`group(name: "enc", { ... })`，之後可以用 `"enc.east"`。
- 相對座標：`(rel: (1, 0), to: "q.east")`；兩點之間：`("q.east", 50%, "k.west")`。
- 0.5 的破壞性改動：`on-yz` 改名為 `on-zy`；`ortho` 不再接受 `name:`；`tree` 的 `draw-node` / `draw-edge` callback 簽名改變。

### cetz-plot 0.1.4

```typ
#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4": plot, chart

cetz.canvas({
  import cetz.draw: *
  set-style(
    axes: (stroke: 0.8pt + p.text, tick: (stroke: 0.8pt + p.text)),
    legend: (stroke: none, fill: none),
  )
  plot.plot(size: (12, 5), x-label: [Epoch], y-label: [Loss], legend: "inner-north-east", {
    plot.add(domain: (0, 10), samples: 100, x => calc.exp(-x / 3),
      style: (stroke: 2pt + p.primary), label: [Train])
    plot.add(((0, 1.0), (5, 0.4), (10, 0.2)),               // data points: array of (x, y)
      style: (stroke: (paint: p.accent, thickness: 2pt, dash: "dashed")), label: [Val])
  })
})

cetz.canvas({
  chart.columnchart(size: (8, 4), (([A], 0.71), ([B], 0.83), ([Ours], 0.91)),
    bar-style: i => (fill: if i == 2 { p.accent } else { p.primary }, stroke: none),
    y-label: [Acc.])
})
```

- 繪製函式：`plot.add`（函式或點陣列）、`add-bar`、`add-fill-between`、`add-hline`、`add-vline`、`add-errorbar`、`add-boxwhisker`、`add-contour`、`add-violin`、`add-anchor`、`add-legend`。
- 圖表：`chart.barchart`（橫向）、`chart.columnchart`（直向）、`chart.piechart`、`chart.boxwhisker`、`chart.radarchart`、`chart.pyramid`。
- `plot.plot` 的軸設定用 `x-tick-step`、`y-min`、`y-max`、`x-format: plot.formats.multiple-of` 等具名參數。
- 預設配色是 cetz 的紅藍綠，**每個系列都要用 `style:` 或 `bar-style:` 指定主題色**。
- 長條圖的標籤寫 `[A]`，不要寫 `["A"]`，否則會顯示引號。
- `chart.boxwhisker` 傳字典資料時要指定 `label-key: "label"`（預設是 `0`，會報 `expected string, found integer`）；箱體預設是藍色，用 `plot-style: (stroke: 1.2pt + p.primary, fill: p.primary.lighten(85%))` 改成主題色。
- 漏掉函式內的 `set text(size: ...)` 時，canvas 文字會繼承 deck 的 28pt，刻度與標籤會擠成一團。
- `chart.radarchart(labels, data)`：每個值都必須在 `0` 到 `radius`（預設 2）之間，否則斷言失敗；先把資料正規化。
- 圖小（寬度 5 以下）時刻度標籤容易擠在一起，要設定 `x-tick-step` / `y-tick-step`。

### fletcher 0.5.8

```typ
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

diagram(
  spacing: (18mm, 10mm),
  node-stroke: 1.2pt + p.primary,
  node-fill: p.primary.lighten(88%),
  node-corner-radius: 4pt,
  edge-stroke: 1.2pt + p.text,
  node((0, 0), [Input], name: <in>),
  node((1, 0), [Encoder], name: <enc>),
  node((2, 0), [Decoder], name: <dec>, stroke: 1.2pt + p.accent, fill: p.accent.lighten(88%)),
  node((2, 1), [Loss], shape: fletcher.shapes.pill, name: <loss>),
  edge(<in>, <enc>, "-|>"),
  edge(<enc>, <dec>, "-|>", [$z$], label-side: left),
  edge(<dec>, <loss>, "--|>"),
  edge(<loss>, <enc>, "-|>", bend: 30deg, stroke: p.accent),
)
```

- 座標是 (欄, 列) 的格點，間距由 `spacing` 控制；節點以 `name: <label>` 命名，邊以 `<label>` 指定端點。
- 箭頭字串：`"->"`、`"-|>"`、`"<->"`、`"=>"`；`"--|>"` 為虛線、`"..>"` 為點線；`"|-|"` 等端點標記。
- 邊的其他參數：`bend`、`corner: right`、`label-side`、`label-pos`、`shift`、`layer`。
- 形狀：`fletcher.shapes.` 底下有 `rect`、`circle`、`ellipse`、`pill`、`parallelogram`、`trapezium`、`diamond`、`triangle`、`house`、`chevron`、`hexagon`、`octagon`、`cylinder`。
- 框住一組節點：`node(enclose: (<a>, <b>), stroke: (paint: p.muted, dash: "dashed"), fill: none)`。

## 6. 驗證

```bash
just fig <slide> <name>   # preview one figure inside a themed slide -> out/<slide>--<name>.pdf
just build <slide>        # the whole deck must still compile
```

- `just fig` 會建立一個套用主題的臨時頁面並呼叫 `<name>()`，用來單獨檢查圖形；入口函式名稱必須與檔名相同。
- 編譯時只允許出現主題本身既有的字型警告（來自 `theme-academic/.../lib.typ`）；圖檔產生的任何警告都要處理。用 `--diagnostic-format short` 比較容易分辨來源。
- 需要看實際效果時，輸出成 PNG 再檢查：`typst compile ... out/<slide>-{p}.png --ppi 60`。確認文字沒有重疊、沒有超出頁面、顏色來自主題。
