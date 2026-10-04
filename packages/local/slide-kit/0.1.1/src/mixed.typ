#import "style.typ": default-palette, default-sizes

/// 「A + B = C」式的圖解
#let op(s, palette: default-palette, sizes: default-sizes) = align(center + horizon, circle(
  radius: 9pt, fill: luma(240), stroke: none,
  align(center + horizon, text(weight: "bold", fill: palette.surface, s)),
))
#let versus(left, right, result, palette: (:), sizes: default-sizes) = {
  let p = default-palette + palette
  grid(
  columns: (1fr, auto, 1fr, auto, 1fr), column-gutter: 8pt,
  left, op("+", palette: p, sizes: sizes), right, op("=", palette: p, sizes: sizes), result,
  )
}

/// 字母方塊 + 說明
#let mini(letter, name, color: auto, palette: (:), sizes: default-sizes, body) = {
  let p = default-palette + palette
  let c = if color == auto { p.primary } else { color }
  block(
  width: 100%, stroke: 0.8pt + c.lighten(40%),
  radius: 6pt, inset: 10pt,
)[
  #grid(
    columns: (26pt, 1fr), column-gutter: 8pt,
    box(width: 26pt, height: 26pt, radius: 5pt, fill: c,
      align(center + horizon, text(fill: white, weight: "bold", size: sizes.flow-number, letter))),
    [#text(weight: "bold", size: sizes.subtitle)[#name] \ #text(size: sizes.label, fill: p.surface)[#body]],
  )
]
}

/// 流程圖。stages: 每項 (title, sub, color)；前 split 個屬於第一區（2D），其餘屬於第二區（3D）
#let arrow-r(c: default-palette.surface) = align(center + horizon, polygon(fill: c, (0pt, 0pt), (7pt, 5pt), (0pt, 10pt)))
#let flow(
  stages,
  split: 4,
  zone-a: "",
  zone-b: "",
  color-a: auto,        // auto → palette.primary
  color-b: auto,        // auto → palette.accent
  height: 120pt,
  palette: (:),
  sizes: default-sizes,
) = {
  let p = default-palette + palette
  let ca = if color-a == auto { p.primary } else { color-a }
  let cb = if color-b == auto { p.accent } else { color-b }

  let n = stages.len()
  let split = calc.min(split, n)   // 避免 colspan 超出欄數

  let arrow = align(
    center + horizon,
    polygon(fill: p.primary.lighten(40%), (0pt, 0pt), (7pt, 5pt), (0pt, 10pt)),
  )

  let cols = ()
  let cells = ()

  for (i, s) in stages.enumerate() {
    if i > 0 { cols.push(14pt); cells.push(arrow) }
    cols.push(1fr)

    let c = if i < split { ca } else { cb }

    cells.push(block(
      width: 100%, height: height,
      fill: c.lighten(90%),
      stroke: 1.2pt + c,
      radius: 6pt,
      inset: (x: 5pt, y: 8pt),
    )[
      #align(center + horizon)[        // ← 水平＋垂直都置中
        #stack(
          dir: ttb,
          spacing: 5pt,
          align(center, circle(
            radius: 12pt, inset: 0pt, fill: c,
            align(center + horizon,
                text(sizes.flow-number, fill: white, weight: "bold", str(i + 1))),
          )),
              text(sizes.subtitle, weight: "bold", fill: c.darken(20%), s.at(0)),
              text(sizes.small, fill: p.text.lighten(35%), s.at(1)),
        )
      ]
    ])
  }

  let bar(c, label) = block(width: 100%, stroke: (top: 2pt + c), inset: (top: 4pt))[
    #align(center, text(sizes.small, fill: c, weight: "bold", label))
  ]

  cells.push(grid.cell(colspan: 2 * split - 1, bar(ca, zone-a)))
  if split < n {
    cells.push([])   // 跳過中間的箭頭欄
    cells.push(grid.cell(colspan: 2 * (n - split) - 1, bar(cb, zone-b)))
  }

  grid(columns: cols, row-gutter: 6pt, align: horizon, ..cells)
}
}
