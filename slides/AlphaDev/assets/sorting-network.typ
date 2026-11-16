#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.2.1": default-palette, academic-sizes

// layers: comparators sharing one x position; (i, j) with i < j puts the minimum on wire i
// integer values are propagated (swapping comparators in accent); other values are wire labels
// circled: consecutive layer indices enclosed by one ellipse
#let sorting-network(
  values: (2, 3, 1, 4),
  layers: (((0, 2),), ((1, 3),), ((0, 1), (2, 3)), ((1, 2),)),
  circled: (),
  dx: 2.1,
  gap: 0.8,
  palette: (:),
  sizes: academic-sizes,
) = {
  let p = default-palette + palette
  let numeric = values.all(x => type(x) == int)
  set text(size: sizes.small)
  cetz.canvas({
    import cetz.draw: *
    let width = dx * (layers.len() + 1)
    let y(i) = -i * gap
    for i in range(values.len()) {
      line((0, y(i)), (width, y(i)), stroke: 1.2pt + p.text)
    }
    let v = values
    for (k, layer) in layers.enumerate() {
      let x = dx * (k + 1)
      for (i, j) in layer {
        let swap = numeric and v.at(i) > v.at(j)
        let c = if swap { p.accent } else { p.primary }
        line((x, y(i)), (x, y(j)), stroke: 1.6pt + c)
        circle((x, y(i)), radius: 0.09, fill: c, stroke: none)
        circle((x, y(j)), radius: 0.09, fill: c, stroke: none)
        if swap {
          let t = v.at(i)
          v.at(i) = v.at(j)
          v.at(j) = t
        }
      }
    }
    if circled.len() > 0 {
      let x-lo = dx * (calc.min(..circled) + 1)
      let x-hi = dx * (calc.max(..circled) + 1)
      let n = values.len() - 1
      circle(
        ((x-lo + x-hi) / 2, -n * gap / 2),
        radius: ((x-hi - x-lo) / 2 + 0.45, n * gap / 2 + 0.45),
        stroke: 1.2pt + p.accent,
      )
    }
    for i in range(values.len()) {
      content((-0.2, y(i)), anchor: "east", [#values.at(i)])
    }
    if numeric {
      for i in range(values.len()) {
        content((width + 0.2, y(i)), anchor: "west", [#v.at(i)])
      }
      content((-0.2, gap * 0.85), anchor: "east", text(fill: p.muted)[in])
      content((width + 0.2, gap * 0.85), anchor: "west", text(fill: p.muted)[out])
    }
  })
}
