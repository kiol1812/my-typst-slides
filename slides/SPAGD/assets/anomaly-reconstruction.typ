#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4": plot
#import "@local/theme-academic:0.1.0": default-palette, academic-sizes

#let _spike(x, h, w) = h * calc.exp(-w * calc.pow(x - 12, 2))
#let _input(x) = 0.5 * calc.sin(2 * x) + 0.3 * calc.cos(5.5 * x) + _spike(x, 3.2, 4)
// The reconstructor also reproduces the spike, so the error stays small.
#let _recon(x) = 0.5 * calc.sin(1.95 * x) + 0.3 * calc.cos(5.5 * x) + _spike(x, 2.9, 6)

#let _key(stroke, body) = box(baseline: -0.3em, line(length: 24pt, stroke: stroke)) + h(6pt) + body

#let anomaly-reconstruction(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.small)
  let input = (stroke: 1.8pt + p.primary)
  let recon = (stroke: (paint: p.accent, thickness: 1.8pt, dash: "dashed"))
  stack(
    dir: ttb,
    spacing: 6pt,
    text(size: sizes.label, weight: "bold", fill: p.text)[Anomaly reconstruction],
    cetz.canvas({
      import cetz.draw: *
      set-style(axes: (stroke: 0.8pt + p.muted, tick: (stroke: none)))
      plot.plot(
        size: (11, 2.6),
        axis-style: "left",
        x-tick-step: none,
        y-tick-step: none,
        x-label: [$t$],
        y-label: none,
        y-min: -1.2,
        y-max: 4,
        {
          plot.add-fill-between(
            x => 4, x => -1.2, domain: (11, 13),
            style: (fill: p.accent.lighten(85%), stroke: none),
          )
          plot.add(domain: (0, 20), samples: 300, _input, style: input)
          plot.add(domain: (0, 20), samples: 300, _recon, style: recon)
          plot.annotate({
            content((13.3, 3.2), anchor: "west", text(size: sizes.small, fill: p.accent)[small error $->$ missed])
          })
        },
      )
    }),
    text(size: sizes.small)[
      #_key(input.stroke)[input (anomaly)]
      #h(20pt)
      #_key(recon.stroke)[reconstruction]
    ],
  )
}
