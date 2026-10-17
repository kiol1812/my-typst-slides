#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.1.0": default-palette, academic-sizes

#let _nodes = ((0, 2), (2, 2.4), (1, 0.9), (3, 0.6), (-0.2, 0))
#let _static-edges = ((0, 1), (0, 2), (1, 2), (2, 4), (3, 1))
#let _residuals = (0.2, 0.35, 0.9, 0.25, 0.7)
#let _candidates = (2, 4)
// After boosting, node 3 gains a top-K neighbor that is a candidate.
#let _new-edges = ((3, 2),)

#let _graph(origin, edges, p, highlight: false) = {
  import cetz.draw: *
  let pos(i) = (origin.at(0) + _nodes.at(i).at(0), origin.at(1) + _nodes.at(i).at(1))
  for (a, b) in edges {
    let hot = highlight and (a in _candidates or b in _candidates)
    line(pos(a), pos(b), stroke: if hot { 2.4pt + p.accent } else { 1pt + p.muted })
  }
  if highlight {
    for (a, b) in _new-edges {
      line(pos(a), pos(b), stroke: (paint: p.accent, thickness: 2.4pt, dash: "dashed"))
    }
  }
  for i in range(_nodes.len()) {
    let hot = highlight and i in _candidates
    circle(
      pos(i),
      radius: 0.28,
      fill: if hot { p.accent } else { p.primary.lighten(85%) },
      stroke: 1.2pt + if hot { p.accent } else { p.primary },
    )
    content(pos(i), text(fill: if hot { white } else { p.text })[#(i + 1)])
  }
}

#let aagc(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.small)
  cetz.canvas(length: 1.25cm, {
    import cetz.draw: *
    let title(pos, body) = content(pos, text(size: sizes.label, weight: "bold", fill: p.text, body))

    // 1. static graph from normal data
    title((1.4, 3.4), [Static graph $bold(A)$])
    _graph((0, 0), _static-edges, p)
    content((1.4, -0.9), text(fill: p.muted)[cosine sim. + top-$K$])

    line((4.2, 1.2), (5.2, 1.2), stroke: 1.2pt + p.text, mark: (end: "stealth", fill: p.text))

    // 2. per-variable reconstruction residuals
    title((7.4, 3.4), [Residual $r_i$])
    let bar-w = 0.6
    for (i, r) in _residuals.enumerate() {
      let x = 5.8 + i * 0.75
      let hot = i in _candidates
      rect((x, 0), (x + bar-w, r * 2.6), fill: if hot { p.accent } else { p.primary.lighten(60%) }, stroke: none)
      content((x + bar-w / 2, -0.3), [#(i + 1)])
    }
    line((5.6, 1.6), (9.6, 1.6), stroke: (paint: p.text, thickness: 1pt, dash: "dashed"))
    content((9.7, 1.6), anchor: "west", text(fill: p.text)[top-$m%$])
    content((7.4, -0.9), text(fill: p.muted)[candidates $cal(M)$])

    line((10.9, 1.2), (11.9, 1.2), stroke: 1.2pt + p.text, mark: (end: "stealth", fill: p.text))

    // 3. adjusted graph
    title((13.6, 3.4), [Adjusted graph $tilde(bold(A))$])
    _graph((12.2, 0), _static-edges, p, highlight: true)
    content((13.6, -0.9), text(fill: p.muted)[edges to $cal(M)$ boosted])
  })
}
