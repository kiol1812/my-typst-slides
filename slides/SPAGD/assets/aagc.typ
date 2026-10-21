#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.1.0": default-palette, academic-sizes

// Example values follow Eq. (3)-(6) with K = 2, m = 40%, phi = Sigmoid,
// and self-loops excluded from top-K (GAT adds them via N(i) ∪ {i}).
// Source cosine similarities: c12 = .8, c13 = .6, c14 = .4, c15 = -.2, c23 = .7,
// c24 = .5, c25 = 0, c34 = .2, c35 = .5, c45 = -.3.
#let _A = (
  (0, 0.69, 0.65, 0, 0),
  (0.69, 0, 0.67, 0, 0),
  (0.65, 0.67, 0, 0, 0),
  (0.60, 0.62, 0, 0, 0),
  (0, 0.50, 0.62, 0, 0),
)
#let _A-adj = (
  (0, 0, 1.36, 0, 1.12),
  (0, 0, 1.38, 0, 1.17),
  (0, 1.38, 0, 0, 2.00),
  (0, 0, 1.26, 0, 1.09),
  (0, 1.17, 2.00, 0, 0),
)
#let _residuals = (0.2, 0.35, 0.9, 0.25, 0.7)
#let _candidates = (2, 4)
#let _focus = 2

// Pentagon layout; the visiting order keeps most static edges on the outline.
#let _slot = (0, 2, 3, 1, 4)
#let _pos(origin, i) = {
  let a = 90deg - _slot.at(i) * 72deg
  (origin.at(0) + 1.3 + 1.2 * calc.cos(a), origin.at(1) + 1.2 + 1.2 * calc.sin(a))
}

#let _edges(X) = {
  let out = ()
  for i in range(X.len()) {
    for j in range(i + 1, X.len()) {
      if X.at(i).at(j) != 0 or X.at(j).at(i) != 0 { out.push((i, j)) }
    }
  }
  out
}

#let _graph(origin, X, p, sizes, adjusted: false) = {
  import cetz.draw: *
  let base = _edges(_A)
  for (a, b) in _edges(X) {
    let style = if not adjusted {
      1pt + p.muted
    } else if (a, b) in base {
      2.2pt + p.accent
    } else {
      (paint: p.accent, thickness: 2.2pt, dash: "dashed")
    }
    line(_pos(origin, a), _pos(origin, b), stroke: style)
  }
  for i in range(X.len()) {
    let hot = adjusted and i in _candidates
    circle(
      _pos(origin, i),
      radius: 0.28,
      fill: if hot { p.accent } else { p.primary.lighten(85%) },
      stroke: 1.2pt + if hot { p.accent } else { p.primary },
    )
    content(_pos(origin, i), text(fill: if hot { white } else { p.text })[#(i + 1)])
  }
}

#let _fmt(v) = {
  let c = int(calc.round(v * 100))
  let frac = calc.rem(c, 100)
  str(calc.quo(c, 100)) + "." + (if frac < 10 { "0" } else { "" }) + str(frac)
}

#let _matrix(origin, X, p, sizes) = {
  import cetz.draw: *
  let (x0, y0) = origin
  let (w, h) = (1.1, 0.55)
  let n = X.len()
  for j in range(n) {
    content((x0 + (j + 0.5) * w, y0 + 0.35), text(size: sizes.small, fill: p.muted)[#(j + 1)])
  }
  for (i, row) in X.enumerate() {
    let y = y0 - (i + 0.5) * h
    content((x0 - 0.3, y), text(size: sizes.small, fill: p.muted)[#(i + 1)])
    for (j, v) in row.enumerate() {
      let cell = if v == 0 { text(fill: p.muted)[0] } else { text(fill: p.text, _fmt(v)) }
      content((x0 + (j + 0.5) * w, y), text(size: sizes.small, cell))
    }
  }
  let bottom = y0 - n * h
  for (x, d) in ((x0, 0.12), (x0 + n * w, -0.12)) {
    line((x + d, y0), (x, y0), (x, bottom), (x + d, bottom), stroke: 1pt + p.text)
  }
}

#let aagc(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.small)
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let title(pos, body) = content(pos, text(size: sizes.label, weight: "bold", fill: p.text, body))
    let note(pos, body) = content(pos, text(fill: p.muted, body))
    let arrow(x) = line((x, 1.2), (x + 0.8, 1.2), stroke: 1.2pt + p.text, mark: (end: "stealth", fill: p.text))

    // 1. static graph from normal data
    title((4.5, 3.4), [Static graph $bold(A)$])
    _graph((0, 0), _A, p, sizes)
    _matrix((3.6, 2.6), _A, p, sizes)
    note((4.5, -0.95), [Sigmoid(cosine), top-$K$ ($K = 2$)])

    arrow(9.5)

    // 2. residuals sorted in descending order; the first m% are candidates
    title((12.5, 3.4), [Sorted residual $r_i$])
    let order = range(_residuals.len()).sorted(key: i => -_residuals.at(i))
    let bar-w = 0.6
    for (k, i) in order.enumerate() {
      let x = 10.7 + k * 0.75
      let hot = i in _candidates
      rect((x, 0), (x + bar-w, _residuals.at(i) * 2.4), fill: if hot { p.accent } else { p.primary.lighten(60%) }, stroke: none)
      content((x + bar-w / 2, -0.3), [#(i + 1)])
    }
    let cut = 10.7 + _candidates.len() * 0.75 - 0.075
    line((cut, -0.1), (cut, 2.8), stroke: (paint: p.text, thickness: 1pt, dash: "dashed"))
    content((cut - 0.1, 2.6), anchor: "east", text(fill: p.accent)[top-$m%$])
    note((12.5, -0.95), [$cal(M) = {3, 5}$ ($m = 40%$)])

    arrow(14.8)

    // 3. adjusted graph after boosting edges that touch candidates
    title((20.5, 3.4), [Adjusted graph $tilde(bold(A))$])
    _graph((16, 0), _A-adj, p, sizes, adjusted: true)
    _matrix((19.6, 2.6), _A-adj, p, sizes)
    note((20.5, -0.95), [$tilde(S)$ boosted, top-$K$ again])
  })
}
