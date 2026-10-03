/// 資訊卡片（上方有標籤）
#import "palette.typ": default-palette
#import "tag.typ": tag

#let card(head, sub: none, color: default-palette.primary, height: auto, body) = block(
  width: 100%, height: height, fill: color.lighten(92%),
  stroke: 0.8pt + color.lighten(40%), radius: 6pt, inset: 10pt,
)[
  #tag(head, color: color) \
  #v(3pt)
  #if sub != none [#text(weight: "bold", size: 20pt)[#sub] \ #v(2pt)]
  #text(size: 16pt)[#body]
]
