/// 小標籤（badge）
#import "style.typ": default-palette, default-sizes

#let tag(body, color: auto, palette: (:), sizes: default-sizes) = {
  let p = default-palette + palette
  let c = if color == auto { p.primary } else { color }
  box(
  fill: c.lighten(85%), stroke: 0.5pt + c.lighten(40%),
  radius: 3pt, inset: (x: 5pt, y: 2pt), baseline: 1pt,
  text(size: sizes.badge, weight: "bold", fill: c.darken(20%), body),
  )
}
