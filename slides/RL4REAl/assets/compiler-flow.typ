// assets/compiler-flow.typ

#let compiler-flow() = {
  let arrow = align(center + horizon)[
    #polygon(fill: luma(100), (0pt, -6pt), (12pt, 0pt), (0pt, 6pt))
  ]

  let doc(icon, label, icon-color: blue, t-size: 22pt) = stack(
    dir: ttb,
    spacing: 8pt,
    align(center)[
      #block(
        width: 50pt, height: 60pt,
        fill: white,
        stroke: 1.5pt + luma(200),
        radius: (top-right: 12pt, rest: 2pt),
        align(center + horizon, text(size: t-size, weight: "bold", fill: icon-color, icon))
      )
    ],
    align(center, text(size: 10pt, weight: "bold", fill: luma(60), label))
  )

  let node(title, sub) = block(
    fill: rgb("#e8ecf2"),
    stroke: 1.5pt + rgb("#b0bec5"),
    radius: 10pt,
    inset: 14pt,
    align(center + horizon)[
      #text(size: 14pt, weight: "bold", title) \
      #text(size: 10pt, fill: luma(100), sub)
    ]
  )

  let backend = block(
    fill: rgb("#dbe2e8"),
    stroke: 1.5pt + rgb("#b0bec5"),
    radius: 12pt,
    inset: 14pt,
    align(center)[
      #text(size: 14pt, weight: "bold", "Backend (llc)")
      #grid(
        columns: (auto, auto, auto, auto, auto),
        column-gutter: 8pt,
        align: horizon,
        block(fill: rgb("#cfd8df"), radius: 6pt, inset: 8pt, text(size: 9pt, weight: "bold", "LLVM\nIR")),
        text(size: 12pt, fill: luma(100), sym.arrow.r),
        block(fill: rgb("#cfd8df"), radius: 6pt, inset: 8pt, align(center)[
          #text(size: 9pt, weight: "bold", "MIR")\
          #text(size: 7pt, "(Machine IR)")
        ]),
        text(size: 12pt, fill: luma(100), sym.arrow.r),
        block(fill: rgb("#cfd8df"), radius: 6pt, inset: 8pt, align(center)[
          #text(size: 9pt, weight: "bold", "CodeGen")\
          #text(size: 7pt, "(Obj)")
        ])
      )
    ]
  )

  let container = block(
    stroke: (dash: "dashed", paint: rgb("#5a82a0"), thickness: 2pt),
    radius: 20pt,
    inset: 20pt,
    fill: rgb("#f4f8fa").transparentize(50%),
    grid(
      columns: (auto, auto, auto, auto, auto, auto, 1fr, auto, auto),
      column-gutter: 6pt,
      align: center + horizon,
      node("Frontend", "(Clang)"),
      arrow,
      doc("LLVM\nIR", "main.ll", icon-color: black, t-size: 11pt),
      arrow,
      node("Optimizer", "(opt)"),
      arrow,
      doc("LLVM\nIR", "optimized.ll", icon-color: black, t-size: 11pt),
      arrow,
      backend
    )
  )

  grid(
    columns: (auto, auto, auto, auto, auto),
    column-gutter: 12pt,
    align: center + horizon,
    doc("C", "main.c", icon-color: rgb("#4b70a3")),
    arrow,
    container,
    arrow,
    doc("O", "main.o", icon-color: rgb("#4b70a3"))
  )
}
