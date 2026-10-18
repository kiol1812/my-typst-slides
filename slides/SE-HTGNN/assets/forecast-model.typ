#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.1.0": default-palette, academic-sizes

// Forecasting model F: gamma snapshots in, beta predictions out.
// detail: true opens F up into SE-HTGNN's modules and highlights the linear project.
#let forecast-model(detail: false, palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.label)
  cetz.canvas(length: if detail { 1.15cm } else { 1.2cm }, {
    import cetz.draw: *
    set-style(stroke: 1.2pt + p.text)
    let arrow = (mark: (end: "stealth", fill: p.text))

    let in-xs = (0, 2.8, 5.6)
    let out-xs = (12.6, 15.4, 18.2)
    let in-labels = ($G^(t-gamma+1)$, $G^t$)
    let out-labels = ($hat(Y)^(t+1)$, $hat(Y)^(t+beta)$)

    let _box(c, w, h, body, name, color: p.primary) = {
      let (x, y) = c
      rect((x - w / 2, y - h / 2), (x + w / 2, y + h / 2), radius: 0.12,
        fill: color.lighten(88%), stroke: 1.2pt + color, name: name)
      content(name, align(center, body))
    }

    // a row of three columns: box, dots, box
    let _row(xs, y, w, h, labels, prefix, color: p.primary) = {
      _box((xs.at(0), y), w, h, labels.at(0), prefix + "0", color: color)
      content((xs.at(1), y), [$dots.c$])
      _box((xs.at(2), y), w, h, labels.at(1), prefix + "2", color: color)
    }

    _row(in-xs, 0, 1.9, 0.9, in-labels, "g", color: p.muted)
    _row(out-xs, 0, 1.9, 0.9, out-labels, "y", color: p.muted)

    cetz.decorations.flat-brace((in-xs.at(0) - 0.95, -0.6), (in-xs.at(2) + 0.95, -0.6), flip: true,
      amplitude: 0.25, stroke: 0.8pt + p.muted, name: "bin")
    content("bin.content", anchor: "north", text(fill: p.muted)[$gamma$ snapshots])
    cetz.decorations.flat-brace((out-xs.at(0) - 0.95, -0.6), (out-xs.at(2) + 0.95, -0.6), flip: true,
      amplitude: 0.25, stroke: 0.8pt + p.muted, name: "bout")
    content("bout.content", anchor: "north", text(fill: p.muted)[$beta$ steps])

    if not detail {
      _box((9.1, 0), 2.6, 1.3, text(size: sizes.body)[$F(dot.c ; theta)$], "f")
      line("g2.east", "f.west", ..arrow)
      line("f.east", "y0.west", ..arrow)
    } else {
      // spatial learning with dynamic attention, one per snapshot (shared weights)
      let gl = [Graph \ learning]
      _row(in-xs, 2.1, 2.4, 1.2, (gl, gl), "gl")
      _row(in-xs, 4.2, 1.9, 0.9, ($H^(t-gamma+1)$, $H^t$), "h")
      for i in ("0", "2") {
        line("g" + i + ".north", "gl" + i + ".south", ..arrow)
        line("gl" + i + ".north", "h" + i + ".south", ..arrow)
      }

      // GRU hidden state carries attention coefficients across snapshots
      let e-style = (stroke: 1.2pt + p.surface, mark: (end: "stealth", fill: p.surface))
      _box((-3.2, 2.1), 2.2, 1.2, [LLM \ prompt], "llm", color: p.surface)
      line("llm.east", "gl0.west", ..e-style, name: "e0")
      content("e0.mid", anchor: "south", padding: 0.12, text(fill: p.surface)[$e^0$])
      line("gl0.east", (in-xs.at(1) - 0.35, 2.1), ..e-style, name: "e1")
      line((in-xs.at(1) + 0.35, 2.1), "gl2.west", ..e-style)
      content("e1.mid", anchor: "south", padding: 0.12, text(fill: p.surface)[$e$])

      // stacked representations Z -> linear project -> Z'
      rect((in-xs.at(0) - 1.15, 3.6), (in-xs.at(2) + 1.15, 4.8), radius: 0.12,
        stroke: (paint: p.muted, thickness: 0.8pt, dash: "dashed"), name: "z")
      content("z.north", anchor: "south", padding: 0.1,
        text(fill: p.muted)[$Z in RR^(N times d times gamma)$])
      _row(out-xs, 4.2, 1.9, 0.9, ($H^(t+1)$, $H^(t+beta)$), "ho")
      rect((out-xs.at(0) - 1.15, 3.6), (out-xs.at(2) + 1.15, 4.8), radius: 0.12,
        stroke: (paint: p.muted, thickness: 0.8pt, dash: "dashed"), name: "zo")
      content("zo.north", anchor: "south", padding: 0.1,
        text(fill: p.muted)[$Z' in RR^(N times d times beta)$])

      _box((9.1, 4.2), 2.4, 1.2, text(size: sizes.body, fill: p.accent)[*Linear*], "lp",
        color: p.accent)
      content("lp.south", anchor: "north", padding: 0.15,
        text(fill: p.accent)[$Z' = Z W + b$])
      line("z.east", "lp.west", ..arrow)
      line("lp.east", "zo.west", ..arrow)

      _box((out-xs.at(1), 2.1), 7.5, 1.1, [MLP head (per step)], "mlp")
      line("zo.south", "mlp.north", ..arrow)
      for i in ("0", "2") {
        line(("y" + i + ".north", "|-", "mlp.south"), "y" + i + ".north", ..arrow)
      }

      // F encloses everything between inputs and predictions
      rect((-4.6, 1.2), (19.6, 5.8), radius: 0.2,
        stroke: (paint: p.text, thickness: 0.8pt, dash: "dotted"), name: "f")
      content("f.north-west", anchor: "north-west", padding: 0.15,
        text(size: sizes.body)[$F(dot.c ; theta)$])
    }
  })
}
