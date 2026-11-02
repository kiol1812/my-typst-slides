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

// ---------- 章節狀態（取代 0.1.0 的 section-slide 分隔頁）----------
#let section-muted = rgb("#B7C3C6")   // 頁尾章節導覽中非目前章節的顏色

#let _chapter = counter("dlcv-chapter")
#let _chapter-title = state("dlcv-chapter-title", none)
#let _chapter-pending = state("dlcv-chapter-pending", false)
#let _pad2(n) = if n < 10 { "0" + str(n) } else { str(n) }

// 目前頁面所屬的章節 heading（沒有章節時回傳 none）
#let _current-chapter(page-no) = {
  let hs = query(heading.where(level: 1)).filter(h => h.location().page() <= page-no)
  if hs.len() > 0 { hs.last() } else { none }
}

// 頁尾的章節導覽：列出所有章節，目前章節以深藍粗體標示
#let _chapter-nav(page-no) = {
  let all = query(heading.where(level: 1))
  if all.len() == 0 { return none }
  let cur = _current-chapter(page-no)
  let items = all.map(h => {
    let active = cur != none and h.location() == cur.location()
    link(h.location(), text(
      font: sans-font, size: 13pt,
      fill: if active { navy } else { section-muted },
      weight: if active { "bold" } else { "regular" },
      h.body,
    ))
  })
  items.join(text(font: sans-font, size: 13pt, fill: section-muted)[#h(6pt)·#h(6pt)])
}

// ---------- 頁尾（畫在 page background，所以不受頁邊距影響）----------
// 有章節時在頁碼前加上章節導覽；頁尾文字太長放不下時，導覽移到頁尾線上方靠右。
#let _footer(label) = context {
  let n = counter(page).get().first()
  let page-no = here().page()
  let rule = 2.25pt + navy
  let nav = _chapter-nav(page-no)
  let label-text = text(font: sans-font, size: 16pt, fill: navy)[#label]
  let number = text(font: sans-font, size: 16pt, fill: gray-text)[#n]
  let inline = nav != none and {
    let fixed = 3 * 18pt + 6 * 10pt + 30pt + measure(number).width
    measure(label-text).width + measure(nav).width + fixed <= page.width - 34pt
  }
  if nav != none and not inline {
    place(bottom + right, dy: -38pt, pad(x: 43pt, nav))
  }
  let sources = query(<dlcv-slide-source>).filter(m => m.location().page() == page-no)
  if sources.len() > 0 {
    let reserve = if nav != none and not inline { measure(nav).width + 20pt } else { 0pt }
    place(bottom + left, dy: -38pt, pad(x: 43pt, box(width: page.width - 86pt - reserve, text(
      font: sans-font, size: 12pt, fill: gray-text, sources.last().value,
    ))))
  }
  let cells = (line(length: 18pt, stroke: rule), label-text, line(length: 100%, stroke: rule))
  if inline { cells += (nav, line(length: 18pt, stroke: rule)) }
  cells += (number, line(length: 18pt, stroke: rule))
  place(bottom + left, dy: -13pt, pad(x: 17pt, grid(
    columns: (auto, auto, 1fr) + if inline { (auto, auto) } else { () } + (auto, auto),
    column-gutter: 10pt,
    align: horizon,
    ..cells,
  )))
}

// ---------- 全域設定：  #show: deck.with(footer: [...]) ----------
//   list-sizes：第 1–3 層清單字級，內容較多時可整體調小
#let deck(footer: [], list-sizes: (28pt, 24pt, 20pt), doc) = {
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
      set text(size: list-sizes.at(calc.min(n, 3) - 1))
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

// ---------- 標題區塊：章節小字 + 左側直條 + 標題 + 副標題 ----------
// 章節小字延續 0.1.0 章節頁的「CHAPTER 02」樣式，取代獨立的章節分隔頁。
#let _chapter-label(prefix) = context {
  let title = _chapter-title.get()
  if title != none {
    text(
      font: sans-font, size: 13pt, weight: "bold",
      fill: gray-text, tracking: 3pt,
      upper[#prefix #_pad2(_chapter.get().first()) #h(4pt)·#h(4pt) #title],
    )
  }
}

#let _title-block(title, subtitle, prefix, title-size: 40pt, sub-size: 28pt) = pad(
  left: 11pt,
  {
    _chapter-label(prefix)
    block(
      above: 4pt,
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
    )
  },
)

// ---------- 章節標記（不產生新頁）----------
//   #section[Methodology]               // 編號自動遞增：01、02、…
//   #section(number: 5)[Results]        // 手動指定編號
//   #section(outlined: false)[...]      // 不列入 Outline
// 只記錄章節；下一張 slide 才放入 level-1 heading，
// 因此 Outline、PDF 書籤與頁尾導覽都指向該章的第一張投影片。
#let section(title, number: auto, outlined: true) = {
  if number == auto { _chapter.step() } else { _chapter.update(number) }
  _chapter-title.update(title)
  _chapter-pending.update((title: title, outlined: outlined))
}

// ---------- 一般投影片 ----------
//   #slide[Title][body]
//   #slide(subtitle: [DeZero])[Implement Detail][body]
//   #slide(outlined: false)[Title][body]   // 不列入 Outline / PDF 書籤
//   #slide(source: [Source: ...])[Title][body]   // 來源印在頁尾線上方
//   #slide(prefix: [Part])[Title][body]          // 章節小字改成 PART 03
//
// 標題本身是 level-2 heading（level-1 留給 section 的章節）：
// Outline 與 PDF 書籤會自動對應，外觀仍由 _title-block 負責
// （show rule 只作用在這個 heading，不影響其他地方）。
#let slide(title, subtitle: none, outlined: false, source: none, prefix: [Chapter], body) = {
  pagebreak(weak: true)
  context {
    let pending = _chapter-pending.get()
    if pending != false {
      show heading.where(level: 1): it => none
      heading(level: 1, outlined: pending.outlined, pending.title)
    }
  }
  _chapter-pending.update(false)
  if source != none { [#metadata(source) <dlcv-slide-source>] }
  {
    show heading.where(level: 2): it => _title-block(it.body, subtitle, prefix)
    heading(level: 2, outlined: outlined, title)
  }
  v(14pt)
  pad(left: 26pt, right: 11pt, body)
}

// ---------- 自動 Outline 頁 ----------
//   #outline-slide()
// 有 section 時列出各章節；沒有時列出各投影片標題
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
  affiliations: none, // 作者任職機構（選用）
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
      #if affiliations != none [
        #v(4pt)
        #text(size: 18pt, fill: gray-text)[#affiliations]
      ]
      #v(8pt)
      #text(size: 22pt, fill: gray-text)[#venue#if year != [] [, #year]]

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
#let timeline(items: (), palette: (:), sizes: academic-sizes) = kit.timeline(
  items: items, 
  palette: academic-palette + palette, 
  sizes: sizes
)
