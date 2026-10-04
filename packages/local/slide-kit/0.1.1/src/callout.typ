/// 提示框：kind = "info" | "warn" | "tip"
#import "style.typ": default-palette, default-sizes

#let callout(title: none, kind: "info", palette: (:), sizes: default-sizes, body) = {
  let p = default-palette + palette // 右邊覆蓋左邊
  let (c, icon) = if kind == "warn" { (p.caution, "!") } else if kind == "tip" { (p.positive, "✓") } else { (p.primary, "i") }

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
        text(size: sizes.title, weight: "bold", fill: c.darken(15%), title),
      )
      v(4pt)
    }
    #body
  ]
}
