#import "style.typ": default-palette, default-sizes

#let timeline(
  items: (), 
  palette: (:), 
  sizes: default-sizes
) = {
  let p = default-palette + palette
  let color-line = p.muted.lighten(50%)
  let color-surface = p.surface
  let color-title = p.text
  let color-desc = p.muted
  block(
    width: 100%,
    stroke: (left: 2pt + color-line),
    inset: (left: 20pt, top: 15pt, bottom: 15pt),
    {
      for (i, item) in items.enumerate() {
        let is-last = (i == items.len() - 1)
        block(
          width: 100%,
          inset: (bottom: if is-last { 0pt } else { 5pt }),
          {
            place(left, dx: -24pt, dy: 0.1em)[
              #circle(radius: 4pt, fill: color-surface, stroke: none)
            ]
            grid(
              columns: (auto, 1fr), 
              column-gutter: 20pt,
              text(fill: color-surface, weight: "bold", size: sizes.label, item.year),
              {
                text(fill: color-title, weight: "bold", size: sizes.body, item.title)
                v(4pt, weak: true)
                set par(leading: 0.6em)
                text(fill: color-desc, size: sizes.label, item.desc)
              }
            )
          }
        )
      }
    }
  )
}
