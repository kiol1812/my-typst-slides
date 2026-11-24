/// 資訊卡片（上方有標籤）
///   color：整張卡片的顏色；head-color：只改標籤顏色（預設同 color）。兩者都可用 palette key，例如 "accent"
///   head 為 none 時不畫標籤
#import "style.typ": default-palette, default-sizes, as-content, resolve-color
#import "tag.typ": tag

#let card(head, sub: none, color: auto, head-color: auto, height: auto, palette: (:), sizes: default-sizes, body) = {
  let p = default-palette + palette
  let c = resolve-color(color, p, p.primary)
  let hc = resolve-color(head-color, p, c)
  block(
    width: 100%, height: height, fill: c.lighten(92%),
    stroke: 0.8pt + c.lighten(40%), radius: 6pt, inset: 10pt, breakable: false,
  )[
    #if head != none [#tag(head, color: hc, palette: p, sizes: sizes) \ #v(3pt)]
    #if sub != none [#text(weight: "bold", size: sizes.subtitle, as-content(sub)) \ #v(2pt)]
    #text(size: sizes.body, as-content(body))
  ]
}
