/// 提示框：kind = "info" | "warn" | "tip"
#import "palette.typ": default-palette

#let callout(title: none, kind: "info", palette: (:), body) = {
  let p = default-palette + palette // 右邊覆蓋左邊
  let (c, icon) = if kind == "warn" { (p.warn, "!") } else if kind == "tip" { (p.tip, "✓") } else { (p.info, "i") }

  let badge = circle(
    radius: 7pt, inset: 0pt, fill: c,
    align(center + horizon, text(
      8pt, fill: white, weight: "bold",
      top-edge: "bounds", bottom-edge: "bounds",
      icon,
    )),
  )

  block(
    width: 100%, fill: c.lighten(90%), stroke: (left: 3pt + c),
    radius: (right: 4pt), inset: (x: 12pt, y: 10pt), breakable: false,
  )[
    #set text(size: 20pt)
    #set par(leading: 0.6em)

    #if title != none {
      grid(
        columns: (auto, 1fr), column-gutter: 6pt, align: horizon,
        badge,
        text(size: 24pt, weight: "bold", fill: c.darken(15%), title),
      )
      v(4pt)
    }
    #body
  ]
}
