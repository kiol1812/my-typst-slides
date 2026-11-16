#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.2.1": default-palette, academic-sizes

#let mcts-loop(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.small)
  cetz.canvas({
    import cetz.draw: *
    set-style(mark: (end: "stealth", fill: p.text, scale: 0.8))
    let arrow-stroke = 1.2pt + p.text
    let func-box(a, b, name, sub) = {
      rect(a, b, radius: 0.15, fill: p.primary.lighten(85%), stroke: 1.2pt + p.primary)
      let cx = (a.at(0) + b.at(0)) / 2
      let cy = (a.at(1) + b.at(1)) / 2
      if sub == none {
        content((cx, cy), text(size: sizes.label, name))
      } else {
        content((cx, cy + 0.22), text(size: sizes.label, name))
        content((cx, cy - 0.3), text(fill: p.muted, sub))
      }
    }

    // functions and variables
    content((1.6, 0), text(size: sizes.label)[$S_t = chevron.l P_t, Z_t chevron.r$])
    line((3.25, 0), (3.8, 0), stroke: arrow-stroke)
    func-box((3.8, -0.5), (5.6, 0.5), $f^"rep"$, none)
    content((4.7, -0.85), text(fill: p.muted)[Transformer + MLP])
    line((5.6, 0), (6.2, 0), stroke: arrow-stroke)
    content((6.55, 0), text(size: sizes.label)[$h_t$])
    line((6.9, 0), (7.5, 0), stroke: arrow-stroke)
    func-box((7.5, -0.5), (9.3, 0.5), $f^"pred"$, none)
    line((9.3, 0), (9.9, 0), stroke: arrow-stroke)
    content((10.0, 0), anchor: "west", text(size: sizes.label)[$hat(pi)_t, hat(v)_t^"corr", hat(v)_t^"lat"$])

    // MCTS region
    rect((0, -1.5), (15.8, -6.4), radius: 0.2, fill: p.primary.lighten(94%),
      stroke: (paint: p.muted, thickness: 0.8pt, dash: "dashed"))
    content((0.25, -1.85), anchor: "west", text(fill: p.primary, weight: "bold")[MCTS from $S_t$ (true dynamics)])
    line((8.4, -0.5), (8.4, -1.5), stroke: arrow-stroke)
    content((8.55, -1.0), anchor: "west", text(fill: p.muted)[prior $hat(pi)$, values $hat(v)$])

    let root = (3.2, -2.6)
    let kids = ((1.8, -3.9), (3.2, -3.9), (4.6, -3.9))
    let leaves = ((4.0, -5.2), (5.2, -5.2))
    let muted-edge = 1pt + p.muted
    let hot-edge = 2pt + p.accent
    line(root, kids.at(0), stroke: muted-edge, mark: none)
    line(root, kids.at(1), stroke: muted-edge, mark: none)
    line(root, kids.at(2), stroke: hot-edge, mark: none)
    line(kids.at(2), leaves.at(0), stroke: muted-edge, mark: none)
    line(kids.at(2), leaves.at(1), stroke: hot-edge, mark: none)
    for pt in (root,) + kids + (leaves.at(0),) {
      circle(pt, radius: 0.22, fill: white, stroke: 1.2pt + p.primary)
    }
    circle(leaves.at(1), radius: 0.22, fill: p.accent.lighten(70%), stroke: 1.2pt + p.accent)
    content((2.85, -2.6), anchor: "east")[$S_t$]
    content((4.15, -3.15), text(fill: p.accent, weight: "bold")[1])
    content((5.65, -5.2), anchor: "west", text(fill: p.accent, weight: "bold")[2])
    bezier((5.45, -4.95), (3.5, -2.45), (6.3, -3.4),
      stroke: (paint: p.primary, thickness: 1.2pt, dash: "dashed"), mark: (end: "stealth", fill: p.primary))
    content((6.15, -3.0), text(fill: p.primary, weight: "bold")[3])

    content((7.0, -2.3), anchor: "north-west", box(width: 8.5cm, {
      set par(leading: 0.45em, spacing: 0.7em)
      [*1 Select*: PUCT; follow $hat(pi)$ first, then predicted values]
      parbreak()
      [*2 Expand* the leaf by the true dynamics; evaluate it by $f^"rep"$, $f^"pred"$]
      parbreak()
      [*3 Back up*: visit counts $N(s, a)$; $hat(pi)$ is trained to match them]
    }))

    // acting in the environment
    line((3.2, -6.4), (3.2, -7.0), stroke: arrow-stroke)
    content((3.2, -7.4))[sample $a_t prop N(S_t, a)$]
    line((5.5, -7.4), (6.1, -7.4), stroke: arrow-stroke)
    func-box((6.1, -8.0), (12.7, -6.8), [AssemblyGame], [append $a_t$, run on $N$ inputs])
    line((12.7, -7.4), (13.3, -7.4), stroke: arrow-stroke)
    content((13.35, -7.4), anchor: "west", text(size: sizes.label)[$r_t, S_(t+1)$])
    line((14.5, -7.8), (14.5, -8.5), (-0.4, -8.5), (-0.4, 0), (-0.05, 0), stroke: 1pt + p.muted,
      mark: (end: "stealth", fill: p.muted))
    content((7.0, -8.5), anchor: "north", padding: 0.08, text(fill: p.muted)[$t <- t + 1$])
  })
}
