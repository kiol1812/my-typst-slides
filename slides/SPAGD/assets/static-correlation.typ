#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4": plot
#import "@local/theme-academic:0.1.0": default-palette, academic-sizes

// Smooth 0 -> 1 -> 0 window over the anomaly segment [11, 16].
#let _window(x) = 1 / (1 + calc.exp(-4 * (x - 11))) - 1 / (1 + calc.exp(-4 * (x - 16)))
#let _s1(x) = calc.sin(1.2 * x)
#let _s2(x) = 0.9 * calc.sin(1.2 * x) - 0.4 + _window(x) * (-0.9 * calc.sin(1.2 * x) - 0.6 + 0.15 * calc.sin(6 * x))

#let _key(stroke, body) = box(baseline: -0.3em, line(length: 24pt, stroke: stroke)) + h(6pt) + body

#let _edge-graph(p, sizes) = cetz.canvas({
  import cetz.draw: *
  line((0, 0), (0, 2), stroke: 2.4pt + p.muted, name: "e")
  content("e.mid", anchor: "west", padding: 0.15, text(size: sizes.small, fill: p.text)[$A_(12)$ fixed])
  for (i, y) in ((1, 2), (2, 0)) {
    circle((0, y), radius: 0.32, fill: p.primary.lighten(85%), stroke: 1.2pt + p.primary)
    content((0, y), text(size: sizes.small, fill: p.text)[#i])
  }
})

#let static-correlation(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.small)
  let s1 = (stroke: 1.8pt + p.primary)
  let s2 = (stroke: 1.8pt + p.surface.lighten(30%))
  stack(
    dir: ttb,
    spacing: 6pt,
    text(size: sizes.label, weight: "bold", fill: p.text)[Static correlation],
    grid(
      columns: (auto, auto),
      column-gutter: 10pt,
      align: horizon,
      cetz.canvas({
        import cetz.draw: *
        set-style(axes: (stroke: 0.8pt + p.muted, tick: (stroke: none)))
        plot.plot(
          size: (9, 2.6),
          axis-style: "left",
          x-tick-step: none,
          y-tick-step: none,
          x-label: [$t$],
          y-label: none,
          y-min: -2,
          y-max: 1.6,
          {
            plot.add-fill-between(
              x => 1.6, x => -2, domain: (11, 16),
              style: (fill: p.accent.lighten(85%), stroke: none),
            )
            plot.add(domain: (0, 20), samples: 300, _s1, style: s1)
            plot.add(domain: (0, 20), samples: 300, _s2, style: s2)
            plot.annotate({
              content((13.5, 1.35), text(size: sizes.small, fill: p.accent)[decoupled])
            })
          },
        )
      }),
      _edge-graph(p, sizes),
    ),
    text(size: sizes.small)[
      #_key(s1.stroke)[sensor 1]
      #h(20pt)
      #_key(s2.stroke)[sensor 2]
    ],
  )
}
