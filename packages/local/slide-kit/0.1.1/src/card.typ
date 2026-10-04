/// 資訊卡片（上方有標籤）
#import "style.typ": default-palette, default-sizes
#import "tag.typ": tag

#let card(head, sub: none, color: auto, height: auto, palette: (:), sizes: default-sizes, body) = {
  let p = default-palette + palette
  let c = if color == auto { p.primary } else { color }
  block(
  width: 100%, height: height, fill: c.lighten(92%),
  stroke: 0.8pt + c.lighten(40%), radius: 6pt, inset: 10pt,
)[
  #tag(head, color: c, palette: p, sizes: sizes) \
  #v(3pt)
  #if sub != none [#text(weight: "bold", size: sizes.subtitle)[#sub] \ #v(2pt)]
  #text(size: sizes.label)[#body]
]
}
