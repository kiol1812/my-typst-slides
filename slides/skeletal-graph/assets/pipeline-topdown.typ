#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.2.2": default-palette, academic-sizes

// Top-down toy scene: a building at the origin, cameras as (angle in deg, radius).
// The skeletal graph is computed below with the paper's steps (Sec. 3-4), so the
// panels stay consistent if the scene changes.
#let _cams = (
  // dense front plaza (popular viewpoint)
  (-138, 1.9), (-128, 1.4), (-124, 2.4), (-114, 1.8), (-108, 1.3), (-102, 2.3), (-94, 1.6),
  (-86, 2.5), (-80, 1.3), (-74, 2.0), (-66, 1.5), (-58, 2.4), (-50, 1.8), (-42, 1.4),
  // second popular cluster on the side
  (-4, 1.9), (4, 1.4), (12, 2.4), (20, 1.7), (28, 2.2), (36, 1.4), (44, 2.0),
  // sparse views around the rest of the building
  (80, 2.0), (120, 2.2), (160, 1.9), (200, 2.1),
  // near-duplicates of cameras 6, 9, 17, 3, 16
  (-90, 1.72), (-77, 2.16), (24, 1.82), (-110, 1.96), (9, 2.55),
)
#let _building-r = 0.55
#let _max-angle = 40      // cameras this close in viewing angle share features
#let _dup-dist = 0.25     // camera centers this close count as near-duplicates
#let _t = 8               // stretch factor
#let _tau = 4 / _t        // importance threshold used in the paper

#let _xy(i) = {
  let (a, r) = _cams.at(i)
  (r * calc.cos(a * 1deg), r * calc.sin(a * 1deg))
}
#let _dist(i, j) = {
  let (x0, y0) = _xy(i)
  let (x1, y1) = _xy(j)
  calc.sqrt(calc.pow(x1 - x0, 2) + calc.pow(y1 - y0, 2))
}
#let _angle-diff(a, b) = {
  let d = calc.rem(calc.abs(a - b), 360)
  calc.min(d, 360 - d)
}
#let _same(e, f) = (e.at(0) == f.at(0) and e.at(1) == f.at(1)) or (e.at(0) == f.at(1) and e.at(1) == f.at(0))
#let _has(list, e) = list.any(f => _same(e, f))
#let _degree(edges, u) = edges.filter(e => e.at(0) == u or e.at(1) == u).len()

// Single-source shortest paths; edges are (a, b, w).
#let _dijkstra(n, edges, src) = {
  let inf = 1e9
  let d = range(n).map(_ => inf)
  let done = range(n).map(_ => false)
  d.at(src) = 0
  for _ in range(n) {
    let u = none
    let best = inf
    for i in range(n) {
      if not done.at(i) and d.at(i) < best { best = d.at(i); u = i }
    }
    if u == none { break }
    done.at(u) = true
    for (a, b, w) in edges {
      let v = if a == u { b } else if b == u { a } else { none }
      if v != none and d.at(u) + w < d.at(v) { d.at(v) = d.at(u) + w }
    }
  }
  d
}
#let _sp(n, edges, a, b) = _dijkstra(n, edges, a).at(b)

#let _compute() = {
  let n = _cams.len()
  // 1. Matched pairs; uncertainty of a two-frame reconstruction grows with the baseline.
  let matched = ()
  for i in range(n) {
    for j in range(i + 1, n) {
      if _angle-diff(_cams.at(i).at(0), _cams.at(j).at(0)) <= _max-angle {
        matched.push((i, j, calc.pow(_dist(i, j), 2)))
      }
    }
  }
  // 2. Near-duplicates: drop the later camera of any very close pair.
  let dup = ()
  for (i, j, w) in matched {
    if _dist(i, j) < _dup-dist and not dup.contains(i) and not dup.contains(j) { dup.push(j) }
  }
  let gi = matched.filter(((a, b, w)) => not dup.contains(a) and not dup.contains(b))
  // 3a. Importance pruning: imp = d(I, J; G_I) / w_IJ.
  let important = gi.filter(((a, b, w)) => _sp(n, gi, a, b) / w >= _tau)
  // 3b. Greedy max-leaf spanning tree (white 0, gray 1, black 2).
  let nbrs(u) = important.filter(((a, b, w)) => a == u or b == u).map(((a, b, w)) => if a == u { b } else { a })
  let color = range(n).map(i => if dup.contains(i) { -1 } else { 0 })
  let start = range(n).filter(i => color.at(i) == 0).sorted(key: i => -nbrs(i).len()).first()
  let tree = ()
  let cur = start
  while cur != none {
    color.at(cur) = 2
    for v in nbrs(cur).filter(v => color.at(v) == 0) {
      color.at(v) = 1
      tree.push(gi.find(e => _same(e, (cur, v))))
    }
    let score(i) = nbrs(i).filter(v => color.at(v) == 0).len()
    let grays = range(n).filter(i => color.at(i) == 1 and score(i) > 0)
    cur = if grays.len() == 0 { none } else { grays.sorted(key: i => -score(i)).first() }
  }
  // 4. Add edges until every pair is stretched by at most t (black-black edges first).
  let black(e) = color.at(e.at(0)) == 2 and color.at(e.at(1)) == 2
  let rest = gi.filter(e => not _has(tree, e))
  let order = rest.filter(black) + rest.filter(e => not black(e)).sorted(key: e => e.at(2))
  let gs = tree
  let added = ()
  for e in order {
    let (a, b, w) = e
    if _sp(n, gs, a, b) > _t * _sp(n, gi, a, b) { gs.push(e); added.push(e) }
  }
  let skeletal = range(n).filter(i => not dup.contains(i) and _degree(gs, i) >= 2)
  (n: n, matched: matched, dup: dup, gi: gi, tree: tree, added: added, skeletal: skeletal)
}

#let _panel(origin, k, p, g, step) = {
  import cetz.draw: *
  let (ox, oy) = origin
  let at((x, y)) = (ox + x * k, oy + y * k)
  let polar(a, r) = at((r * calc.cos(a * 1deg), r * calc.sin(a * 1deg)))
  let pos(i) = at(_xy(i))
  let in-s(i) = g.skeletal.contains(i)
  let dotted = (paint: p.muted, thickness: 0.6pt, dash: "dotted")

  circle((ox, oy), radius: _building-r * k, fill: p.muted.lighten(80%), stroke: 1.2pt + p.muted)

  if step <= 4 {
    let edges = if step <= 2 { g.matched } else { g.gi }
    for e in edges {
      let (a, b, w) = e
      let gone = g.dup.contains(a) or g.dup.contains(b)
      let st = if step == 1 { 0.6pt + p.text }
        else if step == 2 { if gone { dotted } else { 0.6pt + p.text } }
        else if step == 4 and _has(g.added, e) { 1.8pt + p.accent }
        else if _has(g.tree, e) { 1.2pt + p.text }
        else { dotted }
      line(pos(a), pos(b), stroke: st)
    }
    for i in range(g.n) {
      let d = g.dup.contains(i)
      if d and step >= 3 { continue }
      // Step 3 grays the tree's leaves; step 4 grays everything outside S.
      let leaf = (step == 3 and _degree(g.tree, i) == 1) or (step == 4 and not in-s(i))
      let c = if d and step == 2 { p.accent } else if leaf { p.muted } else { p.primary }
      circle(pos(i), radius: 0.09, fill: if leaf { c.lighten(60%) } else { c }, stroke: 0.6pt + c)
      if d and step == 2 { circle(pos(i), radius: 0.22, stroke: 1.2pt + p.accent) }
    }
    return
  }

  // Steps 5-6: cameras as frustums looking at the building, plus scene points.
  let frustum(i, c, filled) = {
    let (a, r) = _cams.at(i)
    line(pos(i), polar(a + 8, r - 0.32), polar(a - 8, r - 0.32), close: true,
      fill: if filled { c.lighten(60%) } else { none },
      stroke: if filled { 0.8pt + c } else { dotted })
  }
  if step == 6 {
    for i in range(g.n) {
      line(pos(i), polar(_cams.at(i).at(0), _building-r), stroke: 0.4pt + p.primary.lighten(55%))
    }
  }
  for a in range(0, 360, step: 30) {
    circle(polar(a + 15, _building-r), radius: 0.05, fill: p.primary, stroke: none)
  }
  for i in range(g.n) {
    if in-s(i) { frustum(i, p.primary, true) }
    else if step == 5 { frustum(i, p.muted, false) }
    else { frustum(i, p.accent, true) }
  }
}

// steps: which panels (1-6) to draw, laid out in `cols` columns; k scales the scene.
#let pipeline-topdown(steps: range(1, 7), cols: 3, k: 0.8, palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  let g = _compute()
  let n-in = g.n - g.dup.len()
  let heads = (
    [1\. Match & pair recon],
    [2\. Drop duplicates (#g.dup.len() of #g.n)],
    [3\. Prune & max-leaf tree],
    [4\. Enforce $t$: $|S| = #g.skeletal.len()$ of #n-in],
    [5\. Reconstruct $S$],
    [6\. Pose estimation + BA],
  )
  set text(size: sizes.small)
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let col-gap = 5.2 * k + 1.4   // leave room for the captions
    let row-gap = 4.9 * k + 1.3
    for (j, step) in steps.enumerate() {
      let origin = (calc.rem(j, cols) * col-gap, -calc.floor(j / cols) * row-gap)
      _panel(origin, k, p, g, step)
      content((origin.at(0), origin.at(1) - 2.7 * k), anchor: "north",
        text(weight: "bold", heads.at(step - 1)))
    }
  })
}
