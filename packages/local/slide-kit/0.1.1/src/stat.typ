/// 大數字卡片
#import "style.typ": default-palette, default-sizes

#let stat(value, label, color: auto, note: none, height: auto, palette: (:), sizes: default-sizes) = {
  let p = default-palette + palette
  let c = if color == auto { p.surface } else { color }
  block(
  width: 100%, height: height, fill: c.lighten(92%), stroke: 0.6pt + c.lighten(60%),
  radius: 6pt, inset: 10pt,
)[
  #align(center)[
    #text(sizes.stat-value, weight: "bold", fill: c)[#value] \
    #text(sizes.label, fill: p.text)[#label]
    #if note != none [ \ #text(sizes.label, fill: p.positive)[#note]]
  ]
]
}
