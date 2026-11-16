#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.2.1": default-palette, academic-sizes

// Small fixed MVC instance; node i is labeled v_(i+1). {v2, v3} is a minimum cover.
#let _nodes = ((0, 0.5), (1, 1), (1, 0), (2, 1.5), (2, 0.7), (2, -0.3))
#let _edges = ((0, 1), (0, 2), (1, 2), (1, 3), (1, 4), (2, 5))

#let _graph(origin, k, p, sizes, chosen: (), node-r: 0.3) = {
  import cetz.draw: *
  let (ox, oy) = origin
  let pos(i) = (ox + _nodes.at(i).at(0) * k, oy + _nodes.at(i).at(1) * k)
  for (a, b) in _edges {
    let covered = chosen.contains(a) or chosen.contains(b)
    line(pos(a), pos(b), stroke: if covered { 2pt + p.accent } else { 0.8pt + p.muted })
  }
  for i in range(_nodes.len()) {
    let hot = chosen.contains(i)
    circle(pos(i), radius: node-r,
      fill: if hot { p.accent } else { p.primary.lighten(85%) },
      stroke: 1.2pt + if hot { p.accent } else { p.primary })
    content(pos(i), text(size: sizes.small, fill: if hot { white } else { p.text })[$v_#(i + 1)$])
  }
}

#let mvc-instance(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.label)
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let k = 1.4
    let gap = 7.2
    let steps = (
      ((), [$S = ()$], [$c = 0$, #h(0.3em) $t = $ false]),
      ((1,), [$S = (v_2)$], [$c = 1$, #h(0.3em) $t = $ false]),
      ((1, 2), [$S = (v_2, v_3)$], [$c = |S| = 2$, #h(0.3em) $t = $ true]),
    )
    for (j, (chosen, head, status)) in steps.enumerate() {
      let ox = j * gap
      _graph((ox, 0), k, p, sizes, chosen: chosen)
      content((ox + k, -0.75), anchor: "north", align(center)[
        #head \
        #text(size: sizes.small, fill: if j == 2 { p.accent } else { p.muted }, status)
      ])
    }
    for j in range(2) {
      let x0 = j * gap + 2 * k + 0.6
      let x1 = (j + 1) * gap - 0.6
      line((x0, 0.7), (x1, 0.7), stroke: 1.2pt + p.text, mark: (end: "stealth", fill: p.text))
      content(((x0 + x1) / 2, 0.7), anchor: "south", padding: 0.12,
        text(size: sizes.small)[add $v_#(j + 2)$])
    }
  })
}
