/// 小標籤（badge）
#import "palette.typ": default-palette

#let tag(body, color: default-palette.primary) = box(
  fill: color.lighten(85%), stroke: 0.5pt + color.lighten(40%),
  radius: 3pt, inset: (x: 5pt, y: 2pt), baseline: 1pt,
  text(size: 16pt, weight: "bold", fill: color.darken(20%), body),
)
