/// 大數字卡片。value / label / note 可為數字、字串或任何內容；color 可為 palette key
#import "style.typ": default-palette, default-sizes, as-content, resolve-color

#let stat(value, label, color: auto, note: none, height: auto, palette: (:), sizes: default-sizes) = {
  let p = default-palette + palette
  let c = resolve-color(color, p, p.surface)
  block(
    width: 100%, height: height, fill: c.lighten(92%), stroke: 0.6pt + c.lighten(60%),
    radius: 6pt, inset: 10pt, breakable: false,
  )[
    #align(center)[
      #text(sizes.stat-value, weight: "bold", fill: c, as-content(value))
      #if label != none [ \ #text(sizes.body, fill: p.text, as-content(label))]
      #if note != none [ \ #text(sizes.label, fill: p.positive, as-content(note))]
    ]
  ]
}
