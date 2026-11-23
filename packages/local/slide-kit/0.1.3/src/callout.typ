/// 提示框。kind：預設樣式 "info" | "warn" | "tip"，或 palette key / color（圖示為 i）
#import "style.typ": default-palette, default-sizes, as-content, resolve-color

#let callout(title: none, kind: "info", palette: (:), sizes: default-sizes, body) = {
  let p = default-palette + palette
  let presets = (info: (p.primary, "i"), warn: (p.caution, "!"), tip: (p.positive, "✓"))
  let (c, icon) = if type(kind) == str and kind in presets { presets.at(kind) } else {
    assert(
      type(kind) == color or (type(kind) == str and kind in p),
      message: "callout kind must be \"info\", \"warn\", \"tip\", a palette key, or a color",
    )
    (resolve-color(kind, p, p.primary), "i")
  }

  let badge = circle(
    radius: 7pt, inset: 0pt, fill: c,
    align(center + horizon, text(
      sizes.icon, fill: white, weight: "bold",
      top-edge: "bounds", bottom-edge: "bounds",
      icon,
    )),
  )

  block(
    width: 100%, fill: c.lighten(90%), stroke: (left: 3pt + c),
    radius: (right: 4pt), inset: (x: 12pt, y: 10pt), breakable: false,
  )[
    #set text(size: sizes.body)
    #set par(leading: 0.6em)

    #if title != none {
      grid(
        columns: (auto, 1fr), column-gutter: 6pt, align: horizon,
        badge,
        text(size: sizes.title, weight: "bold", fill: c.darken(15%), as-content(title)),
      )
      v(4pt)
    }
    #as-content(body)
  ]
}
