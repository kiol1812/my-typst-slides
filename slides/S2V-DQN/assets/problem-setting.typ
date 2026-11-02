#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.2.0": default-palette, academic-sizes

// Small fixed graph used for every instance; `chosen` nodes are drawn as the solution S.
#let _nodes = ((0, 0.5), (1, 1), (1, 0), (2, 1.5), (2, 0.7), (2, -0.3))
#let _edges = ((0, 1), (0, 2), (1, 2), (1, 3), (1, 4), (2, 5))

#let _graph(origin, k, p, prefix, chosen: (), node-r: 0.13) = {
  import cetz.draw: *
  let (ox, oy) = origin
  let pos(i) = (ox + _nodes.at(i).at(0) * k, oy + _nodes.at(i).at(1) * k)
  for (a, b) in _edges {
    let hot = chosen.contains(a) or chosen.contains(b)
    line(pos(a), pos(b), stroke: if hot { 1.2pt + p.accent } else { 0.8pt + p.muted })
  }
  for i in range(_nodes.len()) {
    let hot = chosen.contains(i)
    circle(pos(i), radius: node-r, name: prefix + str(i),
      fill: if hot { p.accent } else { p.primary.lighten(80%) },
      stroke: 1pt + if hot { p.accent } else { p.primary })
  }
}

#let problem-setting(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.label)
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    set-style(stroke: 1.2pt + p.text)
    let arrow = (mark: (end: "stealth", fill: p.text))

    // distribution D: several instances sharing the same structure
    rect((-0.4, -1.3), (5.0, 2.9), radius: 0.2, name: "d",
      stroke: (paint: p.muted, thickness: 0.8pt, dash: "dashed"))
    content("d.north", anchor: "south", padding: 0.1, text(fill: p.muted)[instances $G tilde DD$])
    _graph((0, 1.2), 0.7, p, "a")
    _graph((2.6, 1.2), 0.7, p, "b")
    _graph((1.3, -0.8), 0.7, p, "c")

    // learned greedy policy: the parameters Theta are what training adjusts
    rect((5.8, -0.1), (14.0, 1.9), radius: 0.15, name: "pol",
      fill: p.accent.lighten(90%), stroke: 1.2pt + p.accent)
    content("pol", align(center)[
      Greedy policy \
      $v^* = op("argmax")_(v in overline(S)) hat(Q)(h(S), v; #text(fill: p.accent)[$Theta$])$
    ])
    line("d.east", "pol.west", ..arrow)

    // one instance solved: chosen nodes form S
    _graph((15.4, 0.3), 0.9, p, "s", chosen: (1, 2))
    line("pol.east", (15.1, 0.9), ..arrow)
    content((16.3, -0.75), anchor: "north", align(center)[
      solution $S$ (MVC) \
      #text(fill: p.muted)[cost $c(h(S), G) = |S|$]
    ])

    // reward closes the loop back to Theta
    line((16.3, 2.15), (16.3, 3.2), (9.7, 3.2), "pol.north",
      stroke: 1.2pt + p.accent, mark: (end: "stealth", fill: p.accent))
    content((13.0, 3.2), anchor: "south", padding: 0.12,
      text(fill: p.accent)[reward $r = Delta c$ #sym.arrow.r update $Theta$])
  })
}
