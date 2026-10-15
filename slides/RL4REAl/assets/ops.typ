#import "@local/theme-academic:0.1.0": card

#let draw-tree(nodes, edges, w: 70pt) = box(width: w, height: 60pt)[
  #for e in edges [
    #place(
      dx: e.at(0), dy: e.at(1), 
      line(
        start: (0pt, 0pt), 
        end: (e.at(2) - e.at(0), e.at(3) - e.at(1)), 
        stroke: if e.len() > 4 { e.at(4) } else { 0.8pt + black }
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
        stroke: 0.8pt + black
      )[#set align(center + horizon); #n.at(2)]
    )
  ]
]

// 定義操作前後的版面配置
#let operation(before-nodes, before-edges, after-nodes, after-edges, bw: 70pt, aw: 70pt) = align(center)[
  #stack(
    dir: ltr,
    spacing: 10pt,
    draw-tree(before-nodes, before-edges, w: bw),
    box(height: 60pt, align(center + horizon)[#text(fill: rgb("#307e71"), size: 14pt)[$->$]]),
    draw-tree(after-nodes, after-edges, w: aw)
  )
]

#let ops() = {
  let ny = (35pt, 15pt, [y])
  let nx = (15pt, 45pt, [x])
  let nz = (55pt, 45pt, [z])
  let base-edges = ((35pt, 15pt, 15pt, 45pt), (35pt, 15pt, 55pt, 45pt))
  
  grid(
    columns: (1fr, 1fr, 1fr, 1fr),
    column-gutter: 12pt,
    
    // 1. Spilling Card
    card("Spilling", color: rgb("#307e71"))[
      #operation(
        (ny, nx, nz), base-edges,
        (ny, (15pt, 45pt, [M], rgb("#ff3333")), nz), base-edges
      )
    ],

    // 2. Splitting Card
    card("Splitting", color: rgb("#307e71"))[
      #let w-ny = (40pt, 15pt, [y])
      #let nx1 = (15pt, 45pt, [$x_1$])
      #let nx2 = (40pt, 45pt, [$x_2$])
      #let w-nz = (65pt, 45pt, [z])
      #operation(
        (ny, nx, nz), base-edges,
        (w-ny, nx1, nx2, w-nz), 
        (
          (40pt, 15pt, 15pt, 45pt), 
          (40pt, 15pt, 40pt, 45pt, (paint: blue.lighten(30%), dash: "dotted", thickness: 0.8pt)), // 虛線
          (40pt, 15pt, 65pt, 45pt)
        ),
        aw: 80pt
      )
    ],

    // 3. Coalescing Card
    card("Coalescing", color: rgb("#307e71"))[
      #let w-ny = (40pt, 15pt, [y])
      #let nx1 = (15pt, 45pt, [$x_1$])
      #let nx2 = (40pt, 45pt, [$x_2$])
      #let w-nz = (65pt, 45pt, [z])
      #operation(
        (w-ny, nx1, nx2, w-nz), 
        ((40pt, 15pt, 15pt, 45pt), (40pt, 15pt, 40pt, 45pt), (40pt, 15pt, 65pt, 45pt)),
        ((40pt, 15pt, [y]), (25pt, 45pt, [x]), (55pt, 45pt, [z])), 
        ((40pt, 15pt, 25pt, 45pt), (40pt, 15pt, 55pt, 45pt)),
        bw: 80pt, aw: 70pt
      )
    ],

    // 4. Eviction Card
    card("Eviction", color: rgb("#307e71"))[
      #operation(
        (ny, (15pt, 45pt, text(0.9em)[R1], rgb("#9bbca3")), nz), base-edges,
        (ny, nx, nz), base-edges
      )
    ]
  )
}
