// 模板依賴共用元件：版本寫死，確保可重現
#import "@local/slide-kit:0.1.1" as kit

// ---------- 主題色與字型 ----------
#let navy        = rgb("#0E3445")  // 標題、直條、頁尾線條
#let link-color  = rgb("#467886")  // 超連結
#let gray-text   = rgb("#7F7F7F")  // 頁碼
#let coral       = rgb("#F9604D")  // 珊瑚紅
#let main-color = rgb("#334E86") // 51, 78, 134
#let secondary-color = color.mix(
  color.rgb(100%, 100%, 100%, 60%),
  main-color,
  space: rgb
)
#let main-palette = (
  light-80: main-color.lighten(80%),
  light-60: main-color.lighten(60%),
  light-40: main-color.lighten(40%),
  light-20: main-color.lighten(20%),
  base:     main-color,
  dark-20:  main-color.darken(20%),
  dark-40:  main-color.darken(40%),
  dark-60:  main-color.darken(60%),
  dark-80:  main-color.darken(80%),
)
#let serif-font = ("Times New Roman", "Tinos", "Liberation Serif", "Noto Serif CJK TC", "Noto Serif TC", "PMingLiU")
#let sans-font  = ("Tw Cen MT", "Noto Sans CJK TC", "Noto Sans TC", "Microsoft JhengHei")

// 元件共用設定：元件可用 palette / sizes 參數覆寫單次使用的值。
#let academic-palette = (
  primary: main-color,
  accent: coral,
  surface: link-color,
  text: navy,
  muted: gray-text,
  positive: main-palette.light-20,
  caution: main-palette.dark-20,
  highlight: main-palette.light-40,
)
#let academic-sizes = kit.default-sizes + (
  body: 20pt,
  title: 24pt,
  subtitle: 20pt,
  label: 16pt,
  small: 14pt,
  badge: 16pt,
  icon: 8pt,
  stat-value: 20pt,
  flow-number: 20pt,
)

// 用來記錄目前清單的巢狀層數（控制 28pt / 24pt / 20pt 字級）
#let _list-depth = state("dlcv-list-depth", 0)

// ---------- 頁尾（畫在 page background，所以不受頁邊距影響）----------
#let _footer(label) = context {
  let n = counter(page).get().first()
  let rule = 2.25pt + navy
  place(bottom + left, dy: -13pt, pad(x: 17pt, grid(
    columns: (auto, auto, 1fr, auto, auto),
    column-gutter: 10pt,
    align: horizon,
    line(length: 18pt, stroke: rule),
    text(font: sans-font, size: 16pt, fill: navy)[#label],
    line(length: 100%, stroke: rule),
    text(font: sans-font, size: 16pt, fill: gray-text)[#n],
    line(length: 18pt, stroke: rule),
  )))
}

// ---------- 全域設定：  #show: deck.with(footer: [...]) ----------
#let deck(footer: [], doc) = {
  set page(
    width: 960pt,
    height: 540pt,
    fill: white,
    margin: (top: 16pt, bottom: 52pt, x: 17pt),
    background: _footer(footer),
  )
  set text(font: serif-font, size: 28pt, lang: "zh", region: "tw")
  set par(leading: 0.6em, justify: false)

  // 項目符號：兩層都是 •，第二層縮排並縮小字級
  set list(marker: ([•], [•], [•]), body-indent: 0.6em, indent: 0pt)
  show list: it => {
    _list-depth.update(n => n + 1)
    context {
      let n = _list-depth.get()
      let sizes = (28pt, 24pt, 20pt)
      set text(size: sizes.at(calc.min(n, 3) - 1))
      pad(left: if n >= 2 { 19pt } else { 0pt }, it)
    }
    _list-depth.update(n => n - 1)
  }

  // 編號清單（Outline 頁使用）
  set enum(numbering: "1.", body-indent: 0.6em, indent: 0pt)

  // 超連結：外部網址用青藍色 + 底線；
  // 內部跳轉連結（Outline 項目等）不套用，維持一般文字樣式
  show link: it => if type(it.dest) == str {
    set text(fill: link-color)
    underline(it)
  } else { it }

  // 引用 [1]：青藍色，點擊會跳到參考文獻
  show cite: set text(fill: link-color)

  // 參考文獻：標題由 slide 負責、IEEE 編號樣式、縮小字級
  set bibliography(title: none, style: "ieee")
  show bibliography: set text(size: 18pt)
  show bibliography: set par(leading: 0.5em)

  // 表格：深藍表頭、淡藍斑馬紋
  set table(
    inset: 7pt,
    stroke: 0.6pt + navy.lighten(50%),
    fill: (_, y) => if y == 0 { navy } else if calc.odd(y) { navy.lighten(93%) },
  )
  show table.cell.where(y: 0): set text(fill: white, weight: "bold")

  // 圖說
  show figure.caption: set text(font: sans-font, size: 16pt, fill: gray-text)

  doc
}

// ---------- 標題區塊：左側直條 + 標題 + 副標題 ----------
#let _title-block(title, subtitle, title-size: 40pt, sub-size: 28pt) = pad(
  left: 11pt,
  block(
    stroke: (left: 6pt + navy),
    inset: (left: 10pt, y: 3pt),
    {
      set par(leading: 0.3em)
      text(size: title-size, fill: navy)[#title]
      if subtitle != none {
        linebreak()
        text(size: sub-size, fill: navy)[#subtitle]
      }
    },
  ),
)

// ---------- 一般投影片 ----------
//   #slide[Title][body]
//   #slide(subtitle: [DeZero])[Implement Detail][body]
//   #slide(outlined: false)[Title][body]   // 不列入 Outline / PDF 書籤
//
// 標題本身是 level-2 heading（level-1 留給 section-slide 的章節）：
// Outline 與 PDF 書籤會自動對應，外觀仍由 _title-block 負責
// （show rule 只作用在這個 heading，不影響其他地方）。
#let slide(title, subtitle: none, outlined: false, body) = {
  pagebreak(weak: true)
  {
    show heading.where(level: 2): it => _title-block(it.body, subtitle)
    heading(level: 2, outlined: outlined, title)
  }
  v(14pt)
  pad(left: 26pt, right: 11pt, body)
}

// ---------- 章節分隔頁 ----------
//   #section-slide[Methodology]               // 編號自動遞增：01、02、…
//   #section-slide(number: 5)[Results]        // 手動指定編號
//   #section-slide(prefix: [Part])[Appendix]  // 小字改成 PART 03
//   #section-slide(outlined: false)[...]      // 不列入 Outline
// 頁尾沿用 deck 設定的 background，與一般投影片完全相同。
// 章節標題是 level-1 heading，所以會自動出現在 Outline 與 PDF 書籤。
#let section-outline = rgb("#D9DFE0")   // 空心數字的線條色
#let section-rule    = rgb("#B7C3C6")   // 中間的直線

#let _chapter = counter("dlcv-chapter")
#let _pad2(n) = if n < 10 { "0" + str(n) } else { str(n) }

#let _section-block(title, num, prefix) = {
  let digits = _pad2(num)
  block(width: 100%, height: 100%, pad(left: 40pt, align(horizon, grid(
    columns: (auto, auto, 1fr),
    column-gutter: 44pt,
    align: horizon,
    // 左：空心章節數字（白色填滿 + 淺色描邊）
    text(
      font: sans-font, size: 190pt, fill: white,
      stroke: (paint: section-outline, thickness: 1.6pt, join: "round"),
      top-edge: "cap-height", bottom-edge: "baseline",
      digits,
    ),
    // 中：直線
    rect(width: 1.5pt, height: 150pt, fill: section-rule, stroke: none),
    // 右：CHAPTER 02 小字 + 章節名稱
    stack(
      dir: ttb,
      spacing: 14pt,
      text(
        font: sans-font, size: 13pt, weight: "bold",
        fill: gray-text, tracking: 3pt,
        upper[#prefix #digits],
      ),
      text(font: sans-font, size: 52pt, weight: "bold", fill: navy, title),
    ),
  ))))
}

#let section-slide(title, number: auto, prefix: [Chapter], outlined: true) = {
  pagebreak(weak: true)
  if number == auto { _chapter.step() } else { _chapter.update(number) }
  context {
    let n = _chapter.get().first()
    show heading.where(level: 1): it => _section-block(it.body, n, prefix)
    heading(level: 1, outlined: outlined, title)
  }
}

// ---------- 自動 Outline 頁 ----------
//   #outline-slide()
// 有 section-slide 時列出各章節；沒有時列出各投影片標題
// （標題相同的投影片，例如兩張 Implement Detail，只列一次）。
// 每一項都是跳轉到該頁的連結。
#let outline-slide(title: [Outline]) = slide(title, outlined: false)[
  #context {
    let chapters = query(heading.where(level: 1, outlined: true))
    let items = ()
    if chapters.len() > 0 {
      items = chapters.map(h => link(h.location(), h.body))
    } else {
      let seen = ()
      for h in query(heading.where(level: 2, outlined: true)) {
        if not seen.any(b => b == h.body) {
          seen.push(h.body)
          items.push(link(h.location(), h.body))
        }
      }
    }
    enum(..items)
  }
]

// ---------- 封面（無頁尾，之後頁碼從 1 開始）----------
#let title-slide(
  title: [],
  subtitle: none,
  authors: [],      // 論文作者
  venue: [],        // 出處（期刊／會議）
  year: [],         // 發表年份
  presenters: (),    // 報告者
  date: [],         // 報告日期
) = page(background: none)[
  #counter(page).update(0)
  #let presenter-list = if type(presenters) == array { presenters } else { (presenters,) }
  
  #set par(leading: 0.4em)

  // 使用 grid 分為上、中、下三區塊
  #grid(
    columns: 1fr,
    rows: (0.9fr, auto, 1.1fr),
    align: center,
    
    // --- 1. 上半部：標題區（靠底對齊，往上延伸） ---
    align(bottom)[
      #text(size: 48pt, weight: "bold", fill: navy)[#title]
      #if subtitle != none [
        #v(10pt)
        #text(size: 28pt, fill: navy)[#subtitle]
      ]
      #v(60pt) // 調整標題與分隔線的相對距離
    ],
    
    // --- 2. 中間部：分隔線 ---
    align(center + horizon)[
      #line(length: 40%, stroke: 2pt + navy)
    ],
    
    // --- 3. 下半部：資訊區（靠頂對齊，往下延伸） ---
    align(top)[
      #v(20pt) // 調整資訊區與分隔線的相對距離
      
      // 論文資訊
      #text(size: 24pt)[#authors]
      #v(8pt)
      #text(size: 22pt, fill: gray-text)[#venue, #year]

      #v(24pt)

      // 報告資訊
      #grid(
        columns: (auto, auto),
        column-gutter: 16pt,
        align: (right + top, left + top),
        text(size: 20pt, fill: gray-text)[Presenters],
        stack(
          dir: ttb,
          spacing: 8pt,
          ..presenter-list.map(p => text(size: 20pt)[#p]),
        ),
      )
      #linebreak()
      #text(size: 20pt, fill: gray-text)[#date]
    ]
  )
]

// 左右雙欄：#two-col(ratio: (1fr, 1fr))[左][右]
#let two-col(ratio: (1fr, 1fr), gutter: 20pt, left, right) = grid(
  columns: ratio,
  column-gutter: gutter,
  left, right,
)

#let callout(title: none, kind: "info", palette: (:), sizes: academic-sizes, body) = kit.callout(
  title: title, kind: kind, palette: academic-palette + palette, sizes: sizes, body,
)
#let tag(body, color: auto, palette: (:), sizes: academic-sizes) = kit.tag(
  body, color: color, palette: academic-palette + palette, sizes: sizes,
)
#let card(head, sub: none, color: auto, height: auto, palette: (:), sizes: academic-sizes, body) = kit.card(
  head, sub: sub, color: color, height: height,
  palette: academic-palette + palette, sizes: sizes, body,
)
#let gantt(rows, total: 16, mid: 8, palette: (:), sizes: academic-sizes) = kit.gantt(
  rows, total: total, mid: mid, palette: academic-palette + palette, sizes: sizes,
)
#let stat(value, label, color: auto, note: none, height: auto, palette: (:), sizes: academic-sizes) = kit.stat(
  value, label, color: color, note: note, height: height,
  palette: academic-palette + palette, sizes: sizes,
)
#let flow(
  stages,
  split: 4,
  zone-a: "",
  zone-b: "",
  color-a: auto,
  color-b: auto,
  height: 120pt,
  palette: (:),
  sizes: academic-sizes,
) = kit.flow(
  stages, split: split, zone-a: zone-a, zone-b: zone-b,
  color-a: color-a, color-b: color-b, height: height,
  palette: academic-palette + palette, sizes: sizes,
)
#let mini(letter, name, color: auto, palette: (:), sizes: academic-sizes, body) = kit.mini(
  letter, name, color: color, palette: academic-palette + palette, sizes: sizes, body,
)
#let versus(left, right, result, palette: (:), sizes: academic-sizes) = kit.versus(
  left, right, result, palette: academic-palette + palette, sizes: sizes,
)
#let default-palette = academic-palette
