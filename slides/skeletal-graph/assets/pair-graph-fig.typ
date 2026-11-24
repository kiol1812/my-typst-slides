#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.2.2": default-palette, academic-sizes

// Why G_I paths can be infeasible. Left: top-down cut of a building (arc) with feature
// points on its wall, seen by cameras A-D with the same field of view. Each colored span
// is the part of the wall a pair sees together. (A, B) and (B, C) share no points, but
// (B, C) and (C, D) do (points seen by B, C and D). Right: G_P links (B, C)-(C, D) only.
#let pair-graph-fig(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.label)
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let cams = (($A$, 0), ($B$, 3.4), ($C$, 6.8), ($D$, 8.2))
    let half = 35deg                         // half field of view, same for all cameras
    let (ox, oy, r) = (4.1, 34, 30)          // building circle, center above the cameras
    let wall(x) = oy - calc.sqrt(r * r - calc.pow(x - ox, 2))
    // Where a ray from (x0, 0) at angle phi from vertical first meets the wall.
    let hit(x0, phi) = {
      let (dx, dy) = (calc.sin(phi), calc.cos(phi))
      let (ux, uy) = (x0 - ox, -oy)
      let b = ux * dx + uy * dy
      let t = -b - calc.sqrt(b * b - (ux * ux + uy * uy - r * r))
      (x0 + t * dx, t * dy)
    }
    let sees(x0, (px, py)) = calc.abs(calc.atan2(py, px - x0)) <= half
    let cam-x(i) = cams.at(i).at(1)

    // (camera i, camera j, color, depth of its span inside the wall)
    let pairs = ((0, 1, p.primary, 0.35), (1, 2, p.surface, 0.35), (2, 3, p.primary, 1.05))
    let span(i, j) = (
      calc.max(hit(cam-x(i), -half).at(0), hit(cam-x(j), -half).at(0)),
      calc.min(hit(cam-x(i), half).at(0), hit(cam-x(j), half).at(0)),
    )
    let shared-by(pt) = range(pairs.len()).filter(k => {
      let (i, j, ..) = pairs.at(k)
      sees(cam-x(i), pt) and sees(cam-x(j), pt)
    })

    // Building cut: wall arc spanning the outermost views, shaded above
    let x-min = hit(cam-x(0), -half).at(0) - 0.6
    let x-max = hit(cam-x(cams.len() - 1), half).at(0) + 0.6
    let along(x0, x1, dy) = range(31).map(i => {
      let x = x0 + i * (x1 - x0) / 30
      (x, wall(x) + dy)
    })
    let y-top = wall(x-min) + 1.0
    line(..along(x-min, x-max, 0), (x-max, y-top), (x-min, y-top), close: true,
      fill: p.muted.lighten(80%), stroke: none)
    line(..along(x-min, x-max, 0), stroke: 1.2pt + p.muted)

    // Spans each pair sees together, labeled at their middle
    for (i, j, c, d) in pairs {
      let (lo, hi) = span(i, j)
      line(..along(lo, hi, d), stroke: 2pt + c)
      let x = (lo + hi) / 2
      content((x, wall(x) + d), anchor: "south", padding: 0.08,
        text(size: sizes.small, fill: c)[#cams.at(i).at(0), #cams.at(j).at(0)])
    }

    // Feature points on the wall: span color, or dark and larger when two pairs share it
    let n = 40
    for k in range(n) {
      let x = x-min + 0.3 + k * (x-max - x-min - 0.6) / (n - 1)
      let pt = (x, wall(x))
      let by = shared-by(pt)
      if by.len() >= 2 {
        circle(pt, radius: 0.14, fill: p.text, stroke: none)
      } else {
        let c = if by.len() == 1 { pairs.at(by.first()).at(2) } else { p.muted }
        circle(pt, radius: 0.09, fill: c, stroke: none)
      }
    }

    // Cameras: frustum glyph plus dashed field of view up to the wall
    let fov = (paint: p.muted, thickness: 0.9pt, dash: "dashed")
    for (name, x) in cams {
      line((x, 0), hit(x, -half), stroke: fov)
      line((x, 0), hit(x, half), stroke: fov)
      let w = 0.6 * calc.tan(half)
      line((x, 0), (x - w, 0.6), (x + w, 0.6), close: true,
        fill: p.primary.lighten(60%), stroke: 0.8pt + p.primary)
      content((x, 0), anchor: "north", padding: 0.15, name)
    }

    // G_I and G_P, with the pair nodes colored like their spans
    let (gx, top, bot) = (13.0, 4.4, 1.2)
    let xs = (14.2, 17.7, 21.2, 24.7)
    content((gx, top), $G_I$)
    line((xs.first(), top), (xs.last(), top), stroke: 1.2pt + p.text)
    for (x, (name, _)) in xs.zip(cams) {
      circle((x, top), radius: 0.14, fill: p.primary, stroke: 0.8pt + p.primary)
      content((x, top), anchor: "south", padding: 0.25, name)
    }
    content((gx, bot), $G_P$)
    for (k, (i, j, c, _)) in pairs.enumerate() {
      let x = (xs.at(i) + xs.at(j)) / 2
      line((x, top - 0.1), (x, bot + 0.45), stroke: (paint: p.muted, thickness: 0.9pt, dash: "dotted"))
      rect((x - 1.0, bot - 0.45), (x + 1.0, bot + 0.45), radius: 0.15,
        fill: c.lighten(85%), stroke: 1.2pt + c, name: "n" + str(k))
      content("n" + str(k), $(#cams.at(i).at(0), #cams.at(j).at(0))$)
    }
    // (A, B)-(B, C): no shared points, so no edge
    line("n0.east", "n1.west", stroke: (paint: p.muted, thickness: 0.8pt, dash: "dashed"))
    let (cx, d) = ((xs.at(0) + 2 * xs.at(1) + xs.at(2)) / 4, 0.2)
    line((cx - d, bot - d), (cx + d, bot + d), stroke: 2pt + p.accent)
    line((cx - d, bot + d), (cx + d, bot - d), stroke: 2pt + p.accent)
    content((cx, bot - 0.45), anchor: "north", padding: 0.2,
      text(size: sizes.small, fill: p.accent)[no shared points])
    // (B, C)-(C, D): shared points, so an edge
    line("n1.east", "n2.west", stroke: 1.2pt + p.text, name: "e12")
    content((rel: (0, -0.45), to: "e12.mid"), anchor: "north", padding: 0.2,
      text(size: sizes.small, fill: p.text)[shared points])
  })
}
