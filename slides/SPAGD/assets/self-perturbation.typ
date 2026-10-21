#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4": plot
#import "@local/theme-academic:0.1.0": default-palette, academic-sizes

#let _signal(x) = 0.6 * calc.sin(1.3 * x) + 0.3 * calc.sin(3.1 * x)

// Reconstruction error shrinks as training goes on: `amp` controls the deviation size.
#let _recon(amp) = x => _signal(x) + amp * calc.exp(-calc.pow(x - 6, 2) / 2) * calc.sin(2 * x + 1)

#let _panel(title, amp, p, sizes) = {
  let normal = (stroke: 1.8pt + p.primary)
  let perturbed = (stroke: (paint: p.accent, thickness: 1.8pt, dash: "dashed"))
  stack(
    dir: ttb,
    spacing: 6pt,
    text(size: sizes.label, weight: "bold", fill: p.text, title),
    cetz.canvas({
      import cetz.draw: *
      set-style(
        axes: (stroke: 0.8pt + p.muted, tick: (stroke: none)),
      )
      plot.plot(
        size: (10, 2.6),
        axis-style: "left",
        x-tick-step: none,
        y-tick-step: none,
        x-label: [$t$],
        y-label: none,
        y-min: -1.8,
        y-max: 1.8,
        {
          plot.add(domain: (0, 12), samples: 200, _signal, style: normal)
          plot.add(domain: (0, 12), samples: 200, _recon(amp), style: perturbed)
        },
      )
    }),
  )
}

#let _key(stroke, body) = box(baseline: -0.3em, line(length: 24pt, stroke: stroke)) + h(6pt) + body

#let self-perturbation(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.small)
  let panels = grid(
    columns: (auto, auto, auto),
    column-gutter: 14pt,
    align: horizon,
    _panel([Early training], 1.1, p, sizes),
    stack(
      dir: ttb,
      spacing: 4pt,
      text(size: sizes.small, fill: p.muted)[training],
      text(size: sizes.title, fill: p.muted, sym.arrow.r.long),
      text(size: sizes.small, fill: p.muted)[$cal(L)_"sp" arrow.b$],
    ),
    _panel([Late training], 0.3, p, sizes),
  )
  stack(
    dir: ttb,
    spacing: 10pt,
    panels,
    text(size: sizes.label)[
      #_key(1.8pt + p.primary)[$bold(X)$ normal ($y = 0$)]
      #h(28pt)
      #_key((paint: p.accent, thickness: 1.8pt, dash: "dashed"))[$tilde(bold(X))$ self-perturbed ($y = 1$)]
    ],
  )
}
