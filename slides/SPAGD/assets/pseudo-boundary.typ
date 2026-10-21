#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.1.0": default-palette, academic-sizes

// Normal data lives in a rotated ellipse; rho = 1 is its edge.
#let _shape = (a: 1.5, b: 0.85, rot: 20deg)
#let _anomaly = (rho: 1.55, theta: 70deg)

#let _at(c, rho, theta) = {
  let (x, y) = (_shape.a * rho * calc.cos(theta), _shape.b * rho * calc.sin(theta))
  (
    c.at(0) + x * calc.cos(_shape.rot) - y * calc.sin(_shape.rot),
    c.at(1) + x * calc.sin(_shape.rot) + y * calc.cos(_shape.rot),
  )
}

// Deterministic jitter in [-1, 1].
#let _jitter(k) = calc.sin(k * 12.9898) * 0.5 + calc.sin(k * 4.1414) * 0.5

#let _normal-points(c) = range(28).map(k => _at(c, 0.95 * calc.sqrt((k + 0.5) / 28), k * 2.39996rad))

#let _ring(c, n, rho, spread, phase) = range(n).map(k => {
  _at(c, rho + spread * _jitter(k + phase), k * 360deg / n + 9deg * _jitter(k * 3 + phase))
})

#let _boundary(c, rho, outline) = {
  import cetz.draw: *
  line(..range(72).map(k => _at(c, rho, k * 5deg)), close: true, stroke: outline)
}

#let _dot(pt, p, kind) = {
  import cetz.draw: *
  if kind == "normal" {
    circle(pt, radius: 0.07, fill: p.primary, stroke: none)
  } else if kind == "early" {
    circle(pt, radius: 0.08, fill: white, stroke: 1pt + p.accent.lighten(30%))
  } else if kind == "late" {
    circle(pt, radius: 0.08, fill: p.accent, stroke: none)
  } else {
    n-star(pt, 5, radius: 0.2, inner-radius: 45%, fill: p.text, stroke: none, angle: 90deg)
  }
}

#let pseudo-boundary(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.small)
  cetz.canvas(length: 1.3cm, {
    import cetz.draw: *
    let title(pos, body) = content(pos, text(size: sizes.label, weight: "bold", fill: p.text, body))
    let left = (2.8, 2.2)
    let right = (9.6, 2.2)

    // 1. only normal data: many boundaries fit
    title((2.8, 4.6), [Normal data only])
    for (rho, dash) in ((1.2, "dotted"), (1.6, "dashed"), (1.95, "dotted")) {
      _boundary(left, rho, (paint: p.muted, thickness: 1pt, dash: dash))
    }
    for pt in _normal-points(left) { _dot(pt, p, "normal") }
    _dot(_at(left, _anomaly.rho, _anomaly.theta), p, "anomaly")
    content((rel: (0.35, 0), to: _at(left, _anomaly.rho, _anomaly.theta)), anchor: "west",
      text(fill: p.muted)[missed?])
    content((2.8, -0.1), text(fill: p.muted)[where is the boundary?])

    line((5.8, 2.2), (6.6, 2.2), stroke: 1.2pt + p.text, mark: (end: "stealth", fill: p.text))

    // 2. normal vs. self-perturbed: the boundary is pulled tight
    title((9.6, 4.6), [With self-perturbed $tilde(bold(X))$])
    for pt in _ring(right, 11, 2.0, 0.18, 1) { _dot(pt, p, "early") }
    for pt in _ring(right, 14, 1.22, 0.07, 5) { _dot(pt, p, "late") }
    _boundary(right, 1.08, 1.6pt + p.primary)
    for pt in _normal-points(right) { _dot(pt, p, "normal") }
    _dot(_at(right, _anomaly.rho, _anomaly.theta), p, "anomaly")
    content((rel: (0.35, 0), to: _at(right, _anomaly.rho, _anomaly.theta)), anchor: "west",
      text(fill: p.text, weight: "bold")[caught])
    content((9.6, -0.1), text(fill: p.muted)[tight boundary around $bold(X)$])

    // legend
    let items = (
      ("normal", [normal $bold(X)$]),
      ("early", [$tilde(bold(X))$ early]),
      ("late", [$tilde(bold(X))$ late]),
      ("anomaly", [test anomaly]),
    )
    for (k, (kind, label)) in items.enumerate() {
      let x = 0.9 + k * 3.0
      _dot((x, -0.85), p, kind)
      content((x + 0.3, -0.85), anchor: "west", label)
    }
  })
}
