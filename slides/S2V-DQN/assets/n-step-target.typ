#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.2.0": default-palette, academic-sizes

// 1-step vs n-step Q-learning target: observed rewards (primary) + bootstrapped estimate (accent).
#let n-step-target(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.label)
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    set-style(stroke: 1.2pt + p.text)

    let _state(pos, body, name, color: p.primary) = {
      circle(pos, radius: 0.7, name: name, fill: color.lighten(85%), stroke: 1.2pt + color)
      content(name, body)
    }
    let _step(a, b, body, color: p.primary) = {
      line(a + ".east", b + ".west", name: a + "-" + b,
        stroke: 1.2pt + color, mark: (end: "stealth", fill: color))
      content(a + "-" + b + ".mid", anchor: "south", padding: 0.12, text(fill: color, body))
    }
    let _bootstrap(from, pos, body, name) = {
      rect((pos.at(0), pos.at(1) - 0.45), (pos.at(0) + 6.2, pos.at(1) + 0.45), radius: 0.12,
        name: name, fill: p.accent.lighten(88%), stroke: 1.2pt + p.accent)
      content(name, text(fill: p.accent, body))
      line(from + ".east", name + ".west", stroke: (paint: p.accent, thickness: 1.2pt, dash: "dashed"),
        mark: (end: "stealth", fill: p.accent))
    }

    // row 1: 1-step target (prerequisite C)
    content((-0.9, 2.2), anchor: "east", text(fill: p.muted)[1-step])
    _state((0, 2.2), $S_t$, "a0", color: p.muted)
    _state((3.2, 2.2), $S_(t+1)$, "a1", color: p.muted)
    _step("a0", "a1", $r_t$, color: p.muted)
    _bootstrap("a1", (4.9, 2.2), $max_(v') hat(Q)(h(S_(t+1)), v')$, "qa")

    // row 2: n-step target (S2V-DQN)
    content((-0.9, 0), anchor: "east", text(fill: p.text)[*n-step*])
    _state((0, 0), $S_t$, "b0")
    _state((3.2, 0), $S_(t+1)$, "b1")
    content((5.45, 0), $dots.c$, name: "dots")
    _state((8.2, 0), $S_(t+n)$, "bn")
    _step("b0", "b1", $r_t$)
    line("b1.east", (4.9, 0), stroke: 1.2pt + p.primary)
    line((6.0, 0), "bn.west", stroke: 1.2pt + p.primary, mark: (end: "stealth", fill: p.primary))
    content((6.75, 0), anchor: "south", padding: 0.12, text(fill: p.primary)[$r_(t+n-1)$])
    _bootstrap("bn", (9.9, 0), $max_(v') hat(Q)(h(S_(t+n)), v')$, "qb")

    cetz.decorations.flat-brace((7.5, -0.85), (-0.7, -0.85), amplitude: 0.25,
      stroke: 0.8pt + p.primary, name: "br")
    content("br.content", anchor: "north", padding: 0.05,
      text(fill: p.primary)[observed: $sum_(i=0)^(n-1) r(S_(t+i), v_(t+i))$])
    content((13.0, -0.6), anchor: "north", padding: 0.15,
      text(fill: p.accent)[estimated by current $Theta$])
  })
}
