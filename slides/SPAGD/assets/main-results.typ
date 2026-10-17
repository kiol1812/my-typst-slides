#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4": chart
#import "@local/theme-academic:0.1.0": default-palette, academic-sizes

// AUC (%) from Table 2 of the paper: GDN, TranAD, USAD, Deep IF, COUTA, SPAGD.
#let _methods = ([GDN], [TranAD], [USAD], [Deep IF], [COUTA], [*SPAGD*])
#let _auc = (
  ([SWaT], 81.55, 81.85, 79.67, 80.77, 82.95, 86.30),
  ([SMAP], 58.09, 56.44, 39.51, 60.89, 47.20, 62.38),
  ([MSL], 49.73, 42.97, 61.67, 55.97, 52.17, 66.50),
)

#let main-results(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  let shades = (
    p.primary.lighten(80%),
    p.primary.lighten(65%),
    p.primary.lighten(50%),
    p.primary.lighten(30%),
    p.primary,
    p.accent,
  )
  set text(size: sizes.small)
  cetz.canvas({
    import cetz.draw: *
    set-style(
      axes: (stroke: 0.8pt + p.text, tick: (stroke: 0.8pt + p.text)),
      legend: (stroke: none, fill: none, item: (spacing: 0.2)),
    )
    chart.columnchart(
      mode: "clustered",
      size: (20, 5.5),
      value-key: (1, 2, 3, 4, 5, 6),
      labels: _methods,
      bar-style: i => (fill: shades.at(i), stroke: none),
      y-label: [AUC (%)],
      x-min: -0.5,
      x-max: 2.5,
      y-min: 30,
      y-max: 90,
      y-tick-step: 20,
      legend: "east",
      _auc,
    )
  })
}
