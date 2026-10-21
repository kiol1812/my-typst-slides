#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4": plot
#import "@local/theme-academic:0.1.0": default-palette, academic-sizes

// Values (%) from Table 2 of the paper. COPOD is kept because it has the best F1 on MSL.
#let _methods = ([GDN], [TranAD], [USAD], [COPOD], [Deep IF], [COUTA], [*SPAGD*])
#let _metrics = (
  (
    name: [AUC], y-min: 30, y-max: 90, step: 20,
    rows: (
      ([SWaT], 81.55, 81.85, 79.67, 81.66, 80.77, 82.95, 86.30),
      ([SMAP], 58.09, 56.44, 39.51, 40.04, 60.89, 47.20, 62.38),
      ([MSL], 49.73, 42.97, 61.67, 60.56, 55.97, 52.17, 66.50),
    ),
  ),
  (
    name: [AUPRC], y-min: 0, y-max: 80, step: 20,
    rows: (
      ([SWaT], 71.33, 71.62, 70.24, 71.57, 70.67, 74.78, 77.20),
      ([SMAP], 16.97, 15.24, 11.41, 12.02, 17.33, 12.56, 18.15),
      ([MSL], 12.13, 10.03, 12.86, 18.17, 10.98, 11.84, 21.45),
    ),
  ),
  (
    name: [F1], y-min: 0, y-max: 80, step: 20,
    rows: (
      ([SWaT], 75.23, 76.45, 72.60, 70.85, 72.97, 78.68, 78.77),
      ([SMAP], 19.24, 26.51, 22.69, 25.08, 28.48, 22.69, 27.32),
      ([MSL], 22.68, 19.35, 27.12, 32.77, 23.09, 19.08, 30.89),
    ),
  ),
)

#let _shades(p) = (
  p.primary.lighten(85%),
  p.primary.lighten(72%),
  p.primary.lighten(58%),
  p.primary.lighten(44%),
  p.primary.lighten(25%),
  p.primary,
  p.accent,
)

// Same layout as chart.columnchart, rebuilt with plot.plot so reference lines can share its axes.
#let _chart(metric, p) = cetz.canvas({
  import cetz.draw: *
  set-style(axes: (
    stroke: 0.8pt + p.text,
    tick: (length: 0, stroke: 0.8pt + p.text),
    grid: (stroke: (dash: "dotted")),
  ))
  let shades = _shades(p)
  let n = _methods.len()
  let bar-width = 0.8
  plot.plot(
    size: (21, 3.0),
    axis-style: "scientific-auto",
    y-grid: true,
    x-label: none,
    y-label: metric.name,
    x-min: -0.5,
    x-max: metric.rows.len() - 0.5,
    x-tick-step: none,
    x-ticks: metric.rows.enumerate().map(((i, row)) => (i, row.at(0))),
    y-min: metric.y-min,
    y-max: metric.y-max,
    y-tick-step: metric.step,
    plot-style: i => (fill: shades.at(calc.rem(i, n)), stroke: none),
    {
      plot.add-bar(
        metric.rows.enumerate().map(((i, row)) => (i, row.slice(1))),
        x-key: 0,
        y-key: 1,
        mode: "clustered",
        bar-width: bar-width,
      )
      // SPAGD level across each dataset's cluster
      for (i, row) in metric.rows.enumerate() {
        let v = row.last()
        plot.add(
          ((i - bar-width / 2, v), (i + bar-width / 2, v)),
          style: (stroke: (paint: p.accent, thickness: 1.2pt, dash: "dashed")),
        )
      }
    },
  )
})

#let _legend(p, sizes) = {
  let shades = _shades(p)
  stack(
    dir: ttb,
    spacing: 8pt,
    .._methods.enumerate().map(((i, m)) => {
      box(width: 14pt, height: 10pt, fill: shades.at(i)) + h(6pt) + text(size: sizes.small, m)
    }),
  )
}

#let main-results(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.small)
  grid(
    columns: (auto, auto),
    column-gutter: 14pt,
    align: (right + horizon, left + horizon),
    stack(dir: ttb, spacing: 6pt, .._metrics.map(m => _chart(m, p))),
    _legend(p, sizes),
  )
}
