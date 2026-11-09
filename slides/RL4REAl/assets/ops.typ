#import "@local/theme-academic:0.2.1": card, default-palette, academic-sizes

#let _draw-tree(nodes, edges, p, w: 70pt) = box(width: w, height: 60pt)[
  #for e in edges [
    #place(
      dx: e.at(0),
      dy: e.at(1),
      line(
        start: (0pt, 0pt),
        end: (e.at(2) - e.at(0), e.at(3) - e.at(1)),
        stroke: if e.len() > 4 { e.at(4) } else { 0.8pt + p.text },
      )
    )
  ]
  #for n in nodes [
    #place(
      dx: n.at(0) - 12pt,
      dy: n.at(1) - 12pt,
      circle(
        radius: 12pt,
        fill: if n.len() > 3 { n.at(3) } else { white },
        stroke: 0.8pt + p.text,
      )[#set align(center + horizon); #n.at(2)]
    )
  ]
]

// before -> after layout of one operation
#let _operation(before-nodes, before-edges, after-nodes, after-edges, p, bw: 70pt, aw: 70pt) = align(center)[
  #stack(
    dir: ltr,
    spacing: 10pt,
    _draw-tree(before-nodes, before-edges, p, w: bw),
    box(height: 60pt, align(center + horizon)[#text(fill: p.primary, size: 14pt)[$->$]]),
    _draw-tree(after-nodes, after-edges, p, w: aw),
  )
]

#let ops(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.small)
  let ny = (35pt, 15pt, [y])
  let nx = (15pt, 45pt, [x])
  let nz = (55pt, 45pt, [z])
  let base-edges = ((35pt, 15pt, 15pt, 45pt), (35pt, 15pt, 55pt, 45pt))
  let w-ny = (40pt, 15pt, [y])
  let nx1 = (15pt, 45pt, [$x_1$])
  let nx2 = (40pt, 45pt, [$x_2$])
  let w-nz = (65pt, 45pt, [z])

  grid(
    columns: (1fr, 1fr, 1fr, 1fr),
    column-gutter: 12pt,

    card("Spilling", palette: palette, sizes: sizes)[
      #_operation(
        (ny, nx, nz), base-edges,
        (ny, (15pt, 45pt, text(fill: white)[M], p.accent), nz), base-edges,
        p,
      )
    ],

    card("Splitting", palette: palette, sizes: sizes)[
      #_operation(
        (ny, nx, nz), base-edges,
        (w-ny, nx1, nx2, w-nz),
        (
          (40pt, 15pt, 15pt, 45pt),
          (40pt, 15pt, 40pt, 45pt, (paint: p.surface, dash: "dotted", thickness: 0.8pt)),
          (40pt, 15pt, 65pt, 45pt),
        ),
        p,
        aw: 80pt,
      )
    ],

    card("Coalescing", palette: palette, sizes: sizes)[
      #_operation(
        (w-ny, nx1, nx2, w-nz),
        ((40pt, 15pt, 15pt, 45pt), (40pt, 15pt, 40pt, 45pt), (40pt, 15pt, 65pt, 45pt)),
        ((40pt, 15pt, [y]), (25pt, 45pt, [x]), (55pt, 45pt, [z])),
        ((40pt, 15pt, 25pt, 45pt), (40pt, 15pt, 55pt, 45pt)),
        p,
        bw: 80pt,
        aw: 70pt,
      )
    ],

    card("Eviction", palette: palette, sizes: sizes)[
      #_operation(
        (ny, (15pt, 45pt, text(0.9em)[R1], p.primary.lighten(60%)), nz), base-edges,
        (ny, nx, nz), base-edges,
        p,
      )
    ],
  )
}
