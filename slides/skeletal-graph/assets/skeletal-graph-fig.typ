#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.2.2": default-palette, academic-sizes

// Toy image graph in the spirit of Figure 1 of Snavely et al. 2008.
// 0 = P, 3 = I, 7 = J, 10 = Q.
#let _nodes = (
  (0, 0.6), (0.9, 1.4), (0.9, -0.2), (1.8, 0.6), (2.3, -0.3), (3.1, -0.3),
  (3.6, 0.5), (3.6, 1.3), (4.4, 1.8), (4.4, 0.6), (5.2, 1.3),
)
#let _edges = (
  (0, 1), (0, 2), (1, 2), (0, 3), (1, 3), (2, 3), (3, 4), (3, 5), (4, 5), (5, 6),
  (6, 7), (3, 7), (7, 8), (7, 9), (8, 9), (8, 10), (9, 10), (7, 10),
)
// (node, label, anchor of the label relative to the node)
#let _names = ((0, $P$, "east"), (3, $I$, "north"), (7, $J$, "south-east"), (10, $Q$, "west"))

// Skeletal graph used in panel (d): a spanning tree whose interior nodes form S.
#let _skeletal = ((0, 3), (1, 3), (2, 3), (3, 7), (3, 4), (3, 5), (5, 6), (6, 7), (7, 8), (7, 9), (7, 10))
#let _interior = (3, 5, 6, 7)

#let _panel(ox, k, p, sizes, path: (), growth: 0.07, removed: (), skeletal: false, label-edge: false) = {
  import cetz.draw: *
  let pos(i) = (ox + _nodes.at(i).at(0) * k, _nodes.at(i).at(1) * k)
  let same(e, f) = (e.at(0) == f.at(0) and e.at(1) == f.at(1)) or (e.at(0) == f.at(1) and e.at(1) == f.at(0))
  let has(list, e) = list.any(f => same(e, f))

  for e in _edges {
    let (a, b) = e
    let st = if has(removed, e) or (skeletal and not has(_skeletal, e)) {
      (paint: p.muted, thickness: 0.8pt, dash: "dotted")
    } else { 1.2pt + p.text }
    line(pos(a), pos(b), stroke: st, name: "e" + str(a) + "-" + str(b))
  }
  if label-edge {
    content("e3-7.mid", anchor: "south", padding: 0.12, text(size: sizes.small)[$C_(I J)$])
  }

  // Covariance ellipses grow along the path, then the path itself as arrows.
  for (j, i) in path.enumerate() {
    if j > 0 {
      let r = 0.12 + growth * j
      circle(pos(i), radius: (r, r * 1.5), fill: p.accent.lighten(85%), stroke: 0.8pt + p.accent)
    }
  }
  for j in range(path.len() - 1) {
    // Stop the arrow at the target node's rim instead of its center.
    let (x0, y0) = pos(path.at(j))
    let (x1, y1) = pos(path.at(j + 1))
    let d = calc.sqrt(calc.pow(x1 - x0, 2) + calc.pow(y1 - y0, 2))
    let end = (x1 - (x1 - x0) * 0.14 / d, y1 - (y1 - y0) * 0.14 / d)
    line((x0, y0), end, stroke: 2pt + p.accent,
      mark: (end: "stealth", fill: p.accent, scale: 0.8))
  }

  for i in range(_nodes.len()) {
    let leaf = skeletal and not _interior.contains(i)
    circle(pos(i), radius: 0.12,
      fill: if leaf { p.muted.lighten(60%) } else { p.primary },
      stroke: 0.8pt + if leaf { p.muted } else { p.primary })
  }
  if not skeletal {
    for (i, name, anchor) in _names {
      content(pos(i), anchor: anchor, padding: 0.2,
        text(size: sizes.small, name))
    }
  }
}

#let skeletal-graph-fig(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.label)
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let k = 1.2
    let gap = 7.1
    let panels = (
      ([(a) Image graph $G_I$], (:)),
      ([(b) Shortest path $P -> Q$], (path: (0, 3, 7, 10))),
      ([(c) Edge $(I, J)$ removed], (path: (0, 3, 5, 6, 7, 10), removed: ((3, 7),))),
      ([(d) Skeletal graph $G_S$], (skeletal: true)),
    )
    for (j, (caption, args)) in panels.enumerate() {
      let ox = j * gap
      _panel(ox, k, p, sizes, label-edge: j == 0, ..args)
      content((ox + 2.6 * k, -0.9), anchor: "north", text(size: sizes.small, caption))
    }
  })
}
