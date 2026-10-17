#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4": chart
#import "@local/theme-academic:0.1.0": default-palette, academic-sizes

// Average of AUC / AUPRC / F1 over three datasets, from Table 3 of the paper.
#let _rows = (
  ([w/o JT], 40.55),
  ([SP w/ Recon], 40.66),
  ([w/o SP], 43.60),
  ([w/o AAGC (Both)], 45.27),
  ([w/o AAGC (Temporal)], 45.65),
  ([w/o AAGC (Spatial)], 45.82),
  ([*SPAGD*], 52.11),
)

#let ablation(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.small)
  cetz.canvas({
    import cetz.draw: *
    set-style(axes: (stroke: 0.8pt + p.text, tick: (stroke: 0.8pt + p.text)))
    chart.barchart(
      size: (9, 6),
      bar-style: i => (fill: if i == _rows.len() - 1 { p.accent } else { p.primary.lighten(40%) }, stroke: none),
      x-label: [Avg. score (%)],
      x-min: 35,
      x-max: 55,
      x-tick-step: 5,
      labels: none,
      _rows,
    )
  })
}
