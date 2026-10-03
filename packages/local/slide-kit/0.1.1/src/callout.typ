/// 提示框：kind = "info" | "warn" | "tip"
#import "palette.typ": default-palette

#let callout(title: none, kind: "info", palette: (:), body) = {
  let p = default-palette + palette // left overwrited by right
  let (c, icon) = if kind == "warn" { (p.warn, "!") } else if kind == "tip" { (p.tip, "✓") } else { (p.info, "i") }
  block(
    width: 100%, fill: c.lighten(90%), stroke: (left: 3pt + c),
    radius: (right: 4pt), inset: (x: 12pt, y: 10pt), breakable: false,
  )[
    #if title != none [
      #box(circle(radius: 7pt, fill: c, align(center + horizon, text(8pt, fill: white, weight: "bold", icon))), baseline: 3pt)
      #h(4pt)#text(weight: "bold", fill: c.darken(15%))[#title] \
    ]
    #body
  ]
}
