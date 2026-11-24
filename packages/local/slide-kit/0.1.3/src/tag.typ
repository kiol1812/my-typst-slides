/// 小標籤（badge）。body 可為任何內容；none 時不輸出。color 可為 color 或 palette key
#import "style.typ": default-palette, default-sizes, as-content, resolve-color

#let tag(body, color: auto, palette: (:), sizes: default-sizes) = {
  if body == none { return none }
  let p = default-palette + palette
  let c = resolve-color(color, p, p.primary)
  box(
    fill: c.lighten(85%), stroke: 0.5pt + c.lighten(40%),
    radius: 3pt, inset: (x: 5pt, y: 2pt), baseline: 1pt,
    text(size: sizes.badge, weight: "bold", fill: c.darken(20%), as-content(body)),
  )
}
