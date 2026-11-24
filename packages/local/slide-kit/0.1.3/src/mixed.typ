#import "style.typ": default-palette, default-sizes, as-content, resolve-color, as-record

/// 「A + B = C」式的圖解；三個參數可為任何內容
#let op(s, palette: default-palette, sizes: default-sizes) = align(center + horizon, circle(
  radius: 9pt, fill: luma(240), stroke: none,
  align(center + horizon, text(size: sizes.label, weight: "bold", fill: palette.surface, s)),
))
#let versus(left, right, result, palette: (:), sizes: default-sizes) = {
  let p = default-palette + palette
  grid(
    columns: (1fr, auto, 1fr, auto, 1fr), column-gutter: 8pt,
    as-content(left), op("+", palette: p, sizes: sizes),
    as-content(right), op("=", palette: p, sizes: sizes), as-content(result),
  )
}

/// 字母方塊 + 說明。letter 可為字母、數字、符號或圖片；color 可為 palette key
#let mini(letter, name, color: auto, palette: (:), sizes: default-sizes, body) = {
  let p = default-palette + palette
  let c = resolve-color(color, p, p.primary)
  block(
    width: 100%, stroke: 0.8pt + c.lighten(40%),
    radius: 6pt, inset: 10pt, breakable: false,
  )[
    #grid(
      columns: (26pt, 1fr), column-gutter: 8pt,
      box(width: 26pt, height: 26pt, radius: 5pt, fill: c,
        align(center + horizon, text(fill: white, weight: "bold", size: sizes.flow-number, as-content(letter)))),
      {
        if name != none { text(weight: "bold", size: sizes.subtitle, as-content(name)) }
        if name != none and body != none { linebreak() }
        if body != none { text(size: sizes.body, fill: p.surface, as-content(body)) }
      },
    )
  ]
}

/// 流程圖。stages 的每一項可以是：
///   [Title]                          只有標題
///   ([Title], [sub])、([Title], [sub], "accent")   陣列，後兩項可省略
///   (title: [Title], sub: [sub], color: "accent")  dictionary，sub / color 可省略
/// 前 split 個（0 到全部）屬於第一區，其餘屬於第二區；zone-a / zone-b 為 none 時不畫該區底線。
/// 顏色參數皆可為 palette key 或 color。
#let flow(
  stages,
  split: 4,
  zone-a: none,
  zone-b: none,
  color-a: auto,        // auto → palette.primary
  color-b: auto,        // auto → palette.accent
  height: 120pt,
  palette: (:),
  sizes: default-sizes,
) = {
  let p = default-palette + palette
  let ca = resolve-color(color-a, p, p.primary)
  let cb = resolve-color(color-b, p, p.accent)
  let stages = stages.map(s => as-record(s, ("title", "sub", "color"), defaults: (color: auto)))

  let n = stages.len()
  if n == 0 { return none }
  let split = calc.clamp(split, 0, n)

  let arrow = align(
    center + horizon,
    polygon(fill: p.primary.lighten(40%), (0pt, 0pt), (7pt, 5pt), (0pt, 10pt)),
  )

  let cols = ()
  let cells = ()

  for (i, s) in stages.enumerate() {
    if i > 0 { cols.push(14pt); cells.push(arrow) }
    cols.push(1fr)

    let c = resolve-color(s.color, p, if i < split { ca } else { cb })

    cells.push(block(
      width: 100%, height: height,
      fill: c.lighten(90%),
      stroke: 1.2pt + c,
      radius: 6pt,
      inset: (x: 5pt, y: 8pt),
    )[
      #align(center + horizon)[
        #stack(
          dir: ttb,
          spacing: 5pt,
          align(center, circle(
            radius: 12pt, inset: 0pt, fill: c,
            align(center + horizon,
              text(sizes.flow-number, fill: white, weight: "bold", str(i + 1))),
          )),
          text(sizes.subtitle, weight: "bold", fill: c.darken(20%), as-content(s.title)),
          ..if s.sub != none { (text(sizes.label, fill: p.text.lighten(35%), as-content(s.sub)),) },
        )
      ]
    ])
  }

  let bar(c, label) = block(width: 100%, stroke: (top: 2pt + c), inset: (top: 4pt))[
    #align(center, text(sizes.label, fill: c, weight: "bold", as-content(label)))
  ]

  // Zone bars span their stages and the arrows between them; the arrow between zones stays empty.
  let bars = ()
  if split > 0 {
    bars.push(grid.cell(colspan: 2 * split - 1, if zone-a != none { bar(ca, zone-a) }))
  }
  if split > 0 and split < n { bars.push([]) }
  if split < n {
    bars.push(grid.cell(colspan: 2 * (n - split) - 1, if zone-b != none { bar(cb, zone-b) }))
  }
  if zone-a != none or zone-b != none { cells += bars }

  grid(columns: cols, row-gutter: 6pt, align: horizon, ..cells)
}
