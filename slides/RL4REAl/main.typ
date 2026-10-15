#import "@local/theme-academic:0.1.0": *
#import "@preview/cetz:0.5.2"

#import "assets/compiler-flow.typ": compiler-flow
#import "assets/ops.typ": ops

#let title-text = "RL4ReAl: Reinforcement Learning for Register Allocation"

#show: deck.with(footer: title-text)

#let palette = default-palette + (:)

#set figure(supplement: "Figure")
#show table: set text(size: 16pt)
#show footnote.entry: set text(size: 16pt)
#show list: set block(above: 0.65em, below: 0.65em)

// ───────── 封面 ─────────
#title-slide(
  title: title-text,
  authors: [VenkataKeerthy, S. and Jain, Siddharth and Kundu, Anilava and Aggarwal, Rohit and Cohen, Albert and Upadrasta, Ramakrishna],
  venue: [Compiler Construction],
  year: [2023],
  presenters: ([11557028 楊育哲]),
  date: [2026/10/07],
)

// ───────── Outline ─────────
#outline-slide()

#section-slide[Introduction]

#slide[Problem Defination][
  - Register allocation is reducible to *graph coloring*, which is one of the classical *NP-Complete* problems (combinatorial problem)
  - the applicability and effectiveness of ML methods to compiler optimizations under *hard semantic constraints* remains poorly understood

  #v(20pt)

  #figure(
    kind: image,
    rect(
      fill: none,
      inset: 20pt,
      radius: 8pt,
      compiler-flow()
    ),
    caption: [LLVM compiler flow diagram]
  )
]

#slide[Past Solutions][
  - Register allocators #text(size: 20pt)[(no single best allocator, but Greedy performs better in general)]
    - Constraints-based: PBQP
    - Heuristic approaches: Greedy, Basic, Fast
  - Operations
    - PBQP: Coalescing and Spilling
    - Greedy: Splitting, Coalescing, Eviction and Spilling

  #v(20pt)
  
  #figure(
    kind: image,
    ops(),
    caption: [Operations]
  )
]

#slide[Problem Analysis][
  - Complex problem with *multiple sub-tasks* #text(size: 20pt)[(Splitting, Coalescing, etc)]
  - ML schemes should ensure *correctness constraints*
  - Integration of ML solutions with compiler frameworks #text(size: 20pt)[(python, c++)]
]

#section-slide[Methodology]

#slide[Correctness Constraints][
  - Register Constraints
  - Type Constraints
  - Congruence Constraints
  - Interference Constraints

  #v(12pt)

  #figure(
    kind: image,
    grid(
      columns: (1fr, 1.2fr),
      gutter: 0em,
      [
        // Figure 1
        #rect(
          inset: 0pt,
          width: 100%,
          [
            #grid(
              columns: (1fr, 1.9fr),
              stroke: (x, y) => if x == 1 { (left: 1pt) } else { none },
              [
                // Source Code
                #pad(
                  0.3em,
                  [
                    #set text(size: 14pt)
                    #grid(
                      columns: (auto, 1fr),
                      gutter: 1em,
                      [
                        // Line numbers
                        ```text
                        0
                        1
                        2
                        3
                        4
                        5
                        6
                        7
                        8
                        9
                        10
                        11
                        ```
                      ],
                      [
                        // Code
                        ```text
                        // Source
                        i = 0
                        x = 10
                        y = 20
                        print x
                        z = y / x
                        i++
                        z = z + 10
                        i++
                        print y
                        print z
                        print i
                        ```
                      ]
                    )
                  ]
                )
              ],
              [
                // Machine IR
                #pad(
                  0.3em,
                  [
                    #set text(size: 14pt)
                    ```text
                    MOV32ri 0, %i:gr32
                    MOV32ri 10, %x:gr32
                    MOV32ri 20, %y:gr32
                    <call print on %x>
                    $eax = COPY %y:gr32
                    <clear $edx>
                    IDIV32r %x:gr32, implicit-def $eax,
                          implicit-def $edx
                    %z:gr32 = COPY $eax
                    %i:gr32 = ADD32ri %i:gr32, 1
                    ...
                    <call print on %y, %z, %i>
                    ```
                  ]
                )
              ]
            )
          ]
        )
      ],
      [
        // Figure 2 (Placeholder)
        #align(center+bottom)[
          #image("assets/fig-2.png")
        ]
      ]
    ),
    caption: [*Left*: (a) Example source code and (b) its Machine IR *Right*: Register allocation with and without splitting \ (Source: venkatakeerthy et al. 2022 @venkatakeerthy2022)],
  )
]

#slide[Reinforcement Learning for Register Allocation (Re4ReAl)][
  #figure(
    image("assets/fig-3.jpg"),
    caption: [Overview of RL4ReAl (Source: venkatakeerthy et al. 2022 @venkatakeerthy2022)]
  )
]

#section-slide[Experiments]

#section-slide[]

#slide()[References][
  #set text(lang: "en")
  #bibliography("refs.bib")
]
