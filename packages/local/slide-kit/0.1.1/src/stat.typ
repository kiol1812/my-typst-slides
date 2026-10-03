/// 大數字卡片
#import "palette.typ": default-palette

#let stat(value, label, color: default-palette.surface, note: none, height: auto) = block(
  width: 100%, height: height, fill: color.lighten(92%), stroke: 0.6pt + color.lighten(60%),
  radius: 6pt, inset: 10pt,
)[
  #align(center)[
    #text(20pt, weight: "bold", fill: color)[#value] \
    #text(16pt, fill: default-palette.text)[#label]
    #if note != none [ \ #text(16pt, fill: default-palette.tip)[#note]]
  ]
]
