#import "@local/theme-academic:0.2.1": *
#import "@preview/cetz:0.5.2"
#import "assets/ops.typ": ops
#import "assets/live-split.typ": live-split
#import "assets/x86-constraints.typ": type-fig, congruence-fig, interference-fig

#let title-text = "RL4ReAl: Reinforcement Learning for Register Allocation"

#show: deck.with(footer: [RL4ReAl (VenkataKeerthy et al., CC 2023)], text-size: 21pt)

#let palette = default-palette + (:)

#set figure(supplement: "Figure", numbering: none)
#show figure: set block(below: 0.6em)
#show table: set text(size: 16pt)
#show footnote.entry: set text(size: 13pt, fill: palette.muted)
#set footnote.entry(clearance: 8pt, gap: 4pt)
#show list: set block(above: 0.55em, below: 0.55em)
#show math.equation.where(block: true): set block(above: 0.5em, below: 0.5em)

#let note(body) = text(size: 15pt, fill: palette.muted, body)
#let src(body) = [Source: VenkataKeerthy et al. (CC 2023), #body]
// Items are functions of a height; every item in the row gets the tallest natural height.
#let equal-row(columns: (), gutter: 14pt, ..items) = layout(size => {
  let items = items.pos()
  let autos = columns.zip(items).map(((c, it)) => if c == auto { measure(it(auto)).width } else { 0pt })
  let fr-total = columns.filter(c => type(c) == fraction).map(c => c / 1fr).sum(default: 0)
  let free = size.width - gutter * (items.len() - 1) - autos.sum()
  let widths = columns.zip(autos).map(((c, a)) => if c == auto { a } else { free * (c / 1fr) / fr-total })
  let h = calc.max(..items.zip(widths).map(((it, w)) => measure(it(auto), width: w).height))
  grid(columns: widths, column-gutter: gutter, ..items.map(it => it(h)))
})

// ───────── 封面 ─────────
#title-slide(
  title: title-text,
  authors: [S. VenkataKeerthy#super[†], Siddharth Jain#super[†], Anilava Kundu#super[†], Rohit Aggarwal#super[†], Albert Cohen#super[‡], Ramakrishna Upadrasta#super[†]],
  affiliations: [#super[†]IIT Hyderabad, India #h(1em) #super[‡]Google, France],
  venue: [CC 2023 (32nd ACM SIGPLAN International Conference on Compiler Construction)],
  year: [],
  presenters: ([11557028 楊育哲]),
  date: [2026/11/18],
)

#section[Problem]

#slide(source: src[Figure 2, p. 3; Sec. 1, p. 1; Sec. 2.1–2.2, pp. 2–3; Sec. 6.1–6.2, pp. 7–8; objective summarized from Sec. 2.2])[Research Problem & Optimization Problem][
  - *Adjustable*: per virtual register $v$: register $r in chi(v^t)$, spill $mu(v)$, or split $phi(v, k)$
  - *Given*: MIR function, interference graph $G(V, E)$, spill weights $M(v)$
  - *Objective*: fewer spills, low spill cost $M(v)$ #sym.arrow.r faster code
  - *Constraints*: every assignment must be legal, with no approximation
    - *Type*: a register must belong to the class of the variable's type
    - *Congruence*: registers that share one physical register cannot hold two live variables
    - *Interference*: variables live at the same time get different registers
  - *Why is it hard to solve?*: #box[NP-complete] (reducible to graph coloring)
  #figure(
    kind: image,
    grid(
      columns: (auto, auto),
      column-gutter: 2em,
      align: horizon,
      rect(
        inset: 0pt,
        stroke: 0.8pt + palette.text,
        grid(
          columns: (auto, auto),
          stroke: (x, y) => if x == 1 { (left: 0.8pt + palette.text) } else { none },
          pad(0.3em)[
            #set text(size: 12pt)
            #set par(leading: 0.4em)
            #grid(
              columns: (auto, auto),
              gutter: 1em,
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
              ```,
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
              ```,
            )
          ],
          pad(0.3em)[
            #set text(size: 12pt)
            #set par(leading: 0.4em)
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
          ],
        ),
      ),
      image("assets/fig-2.png", width: 21em),
    ),
    caption: [*Left*: source & Machine IR (Figure 1). *Right*: Register allocation with and without splitting (Figure 2)],
  )
]

#section[Background]

#slide(source: src[Sec. 1, pp. 1–2; Sec. 2.3, p. 3; Sec. 6.2, p. 8; Sec. 7, p. 11; diagram self-drawn from Sec. 2.3])[Existing Approaches & Difficulties][
  #let frame = 1.2pt + palette.accent
  #table(
    columns: (auto, 0.9fr, 1.3fr, 1.15fr, 1fr, 1.2fr),
    align: (x, _) => if x == 0 { left + horizon } else { center + horizon },
    fill: (x, y) => if y == 0 { palette.text } else if calc.odd(y) { palette.text.lighten(93%) },
    stroke: none,
    inset: (x: 6pt, y: 3.5pt),
    table.hline(stroke: 0.8pt + palette.text),
    [], table.cell(colspan: 2)[*Solver-based*], table.cell(colspan: 3)[*Heuristic-based*],
    table.hline(start: 1, end: 3, stroke: 0.6pt + palette.muted),
    table.hline(start: 3, end: 6, stroke: 0.6pt + palette.muted),
    [], [ILP], [PBQP], [Fast], [Basic], [Greedy],
    table.hline(stroke: 0.6pt + palette.muted),
    [*How it works*], [Integer linear program + solver], [Partitioned Boolean Quadratic Problem solver], [Linear scan, per basic block], [Improved Fast, per function], [Priority queue; assign, evict, split, or spill],
    [*Strength*], [Exact or near-optimal], [Exact or near-optimal], [Simplest allocator], [Whole-function view], [Near-linear time],
    [*Difficulty*], [Scalability issues], [Scalability issues], [Outperformed by Basic, Greedy, PBQP], [No splitting or coalescing], [Man-decades of tuning, per architecture],
    table.hline(stroke: 0.8pt + palette.text),
    // frame the allocators compared in the experiments: PBQP; Basic and Greedy
    table.hline(y: 1, start: 2, end: 3, stroke: frame),
    table.hline(y: 1, start: 4, end: 6, stroke: frame),
    table.hline(y: 5, start: 2, end: 3, stroke: frame),
    table.hline(y: 5, start: 4, end: 6, stroke: frame),
    ..(2, 3, 4, 6).map(x => table.vline(x: x, start: 1, stroke: frame)),
  )
  #grid(
    columns: (1fr, auto),
    column-gutter: 14pt,
    align: horizon,
    [
      #table(
        columns: (auto, 1fr, 1fr),
        align: (x, _) => if x == 0 { left + horizon } else { center + horizon },
        stroke: none,
        inset: (x: 5pt, y: 3pt),
        table.hline(stroke: 0.8pt + palette.text),
        [], [ILP], [PBQP],
        [*Variables*], [Many 0/1 variables], [One-hot choice \ per node],
        [*Constraints*], [Linear inequalities], [Costs \ ($infinity$ = forbidden)],
        [*Objective*], [Linear], [Quadratic \ (node + edge)],
        [*Solver*], [Generic, #box[branch-and-bound]], [Graph reduction],
        [*Quality*], [Optimal], [Near-optimal],
        [*Speed*], [Slow, hard to scale], [Fast, used in LLVM],
        table.hline(stroke: 0.8pt + palette.text),
      )
    ],
    [
      #figure(ops(), caption: [Four strategies of LLVM Greedy: spill, split, coalesce, evict (Sec. 2.3)])
      - *Why ML is hard*: hard correctness constraints
      - *Prior ML*: not end-to-end in LLVM
    ],
  )
]

#slide(source: src[Sec. 2.1, pp. 2–3; Sec. 2.2, p. 3; Sec. 3.2, p. 5; Sec. 6.1, p. 7; diagram self-drawn from Sec. 2.1 (x86) and Sec. 2.2 (split)])[Prerequisite Methods: Core Formulas][
  #{
    set text(size: 16pt)
    equal-row(
    columns: (1fr, 1.7fr),
    gutter: 12pt,
    h => card([Coloring with split / spill#footnote[Chaitin et al., 1981]], height: h)[
      $k$ registers $=$ $k$ colors on $G$ \
      Not $k$-colorable: spill $mu(v)$ (cost $M(v)$) or split
      $ phi(v, k): L(v) ~> (L(v'), L(v'')) $
      $ L(v') = [P_v^italic("def"), P_v^k], L(v'') = [P_v^(k+1), P_v^italic("end")] $
      #align(center, live-split())
      *Difficulty*: which $v$, which $k$, which order
    ],
    h => card([Register constraints $chi(v^t)$ on x86], height: h)[
      #grid(
        columns: (auto, 1fr),
        column-gutter: 12pt,
        row-gutter: 6pt,
        align: horizon,
        type-fig(),
        [*Type* $chi^cal(T)(v^t) = {v^t triangle.filled.small.r r : r in R^t}$ \ `%x:gr32` #sym.arrow.r `GR32`, never `GR64`],
        congruence-fig(),
        [*Congruence* $forall r' in C(r)$: \ $chi^C (v^t) = {v_i^t triangle.filled.small.r r : forall v_i, v_j in cal(V), v_i != v_j,$ \ #std.h(4em) $exists.not v_j triangle.filled.small.r r' in L(v_i)}$ \ `$al` held #sym.arrow.r `$ax`, `$eax`, `$rax` blocked],
        interference-fig(),
        [*Interference* \ $chi^cal(I)(v^t) = R^t without {r : forall u ((u, v) in E and (u triangle.filled.small.r r))}$ \ $L(x) inter L(y) != emptyset$ #sym.arrow.r edge #sym.arrow.r different registers],
      )
    ],
    )
  }
  #v(4pt)
  *RL4ReAl keeps* $chi(v)$ as hard action masks and Greedy's decision types; *replaces* hand-tuned choices with four learned policies; *trains* them with PPO (Proximal Policy Optimization)#footnote[Schulman et al., 2017]\; *adds* MIR2Vec + GGNN (Gated Graph Neural Network) states
]

#section[Method]

#slide(source: src[Figure 3, p. 5; agent states, action spaces and rewards from Sec. 3.2, pp. 4–6])[Main Method: Hierarchical Masked Agents][
  #set text(size: 16pt)
  #figure(
    image("assets/fig-3.pdf", width: 86%),
    caption: [LLVM builds $G$ and MIR2Vec features; agents decide via gRPC; LLVM applies splits and the final color map (Figure 3)],
  )
  #table(
    columns: (auto, 1.3fr, 1fr, 1.1fr),
    align: (left + horizon,) * 4,
    stroke: none,
    inset: (x: 6pt, y: 3.5pt),
    table.hline(stroke: 0.8pt + palette.text),
    [*Agent*], [*State*], [*Legal actions* (mask)], [*Reward*],
    table.hline(stroke: 0.6pt + palette.muted),
    [Node selector $omega_upsilon$], [$chevron.l [|G|], M(V) chevron.r$], [$V_"nclr"$ (uncolored)],
    table.cell(rowspan: 2)[$R(omega_xi)$ if $chi$, $0$ if $phi$],
    [Task selector $omega_tau$], [$chevron.l [|v|], |chi(v)|, delta(v), |K(v)|, M(v) chevron.r$], [${phi, chi}$ if $|K(v)| >= 2$, else $chi$],
    [Splitter $omega_phi$], [$chevron.l [|v|], cal(M)(v), D_v chevron.r$], [$K$ (use points of $v$)], [$M(v) - M(v') - M(v'')$],
    [Coloring $omega_xi$], [$chevron.l [|v|], |chi(v)|, |V_"nclr"| chevron.r$], [$chi(v)$, or $mu(v)$ if empty], [$+M(v)$ color, $-M(v)$ spill],
    table.hline(stroke: 0.6pt + palette.muted),
    [Global $R_G$ (G only)], table.cell(colspan: 2)[LLVM-MCA throughput vs. Greedy, per function], [$+10$ if $>=$ Greedy, else $-10$],
    table.hline(stroke: 0.8pt + palette.text),
  )
]

#section[Evidence]

#slide(source: src[Sec. 6.1, p. 7; Figure 4 and Sec. 6.2, p. 8; Sec. 6.3, pp. 8–9; Table 3, p. 8])[Evidence (1): Setup of Runtime on x86 SPEC CPU][
  #set text(size: 16pt)
  #table(
    columns: (auto, 1fr),
    align: (left + horizon, left + horizon),
    stroke: none,
    inset: (x: 8pt, y: 3pt),
    fill: (_, y) => if y == 0 { palette.text } else if calc.even(y) { palette.text.lighten(93%) },
    table.hline(stroke: 0.8pt + palette.text),
    [*Question*], [*Answer from the paper*],
    [*Claim*], [Learned allocator on par with LLVM's tuned allocators in runtime],
    [*Task / data*], [SPEC CPU 2006 + 2017, C/C++ $<$ 1 MLOC; 18 benchmarks compiled #note[4 compile, 4 runtime errors excluded]],
    [*Model*], [Four FC agents + GGNN states; PPO, standard hyperparameters, until reward converges],
    [*Training set*], [5K random SPEC 2017 functions with 120–500 vertices #note[of about 11K]],
    [*Compared*], [Basic (reference), PBQP, Greedy; RL4ReAl-L (local rewards), RL4ReAl-G (+ $R_G$)],
    [*Same*], [LLVM 10.0.1; Xeon W2133 (6 cores, 32 GB); median of 3 runs],
    [*Changed*], [Only the allocator; RL4ReAl handles 120–500-vertex functions, others by Greedy],
    [*Metric*], [Runtime gain over Basic, Basic $-$ x (s); higher is better #note[noise $<$ 1% (95% CI, 8 runs), libquantum up to 1.8%]],
    table.hline(stroke: 0.8pt + palette.text),
  )
  #grid(
    columns: (52%, 1fr),
    column-gutter: 14pt,
    align: horizon,
    figure(
      image("assets/fig-4.pdf", width: 100%),
      caption: [Interference graphs of 45 hot SPEC 2017 functions (Figure 4)],
    ),
    card([Characterization: why 120–500 vertices])[
      Hot: $>=$ 5% of benchmark time (`perf`) \
      44 / 45 have $>$ 120 vertices; 31 in 120–500 \
      Vertices $tilde$ interferences, register pressure: near linear #sym.arrow.r larger graphs are harder
    ],
  )
]

#slide(source: src[Table 3 and Sec. 6.3, pp. 8–9; table re-typeset, values and highlights unchanged])[Evidence (2): Reading Runtime on x86 SPEC CPU][
  // f: highest, s: second highest, as marked in the paper
  #let hi(mark, v) = if mark == "f" { table.cell(fill: palette.accent.lighten(70%), v) } else if mark == "s" { table.cell(fill: palette.highlight.lighten(40%), v) } else { v }
  #let row(name, ..cells) = ([#name],) + cells.pos().map(c => if type(c) == array { hi(..c) } else { c })
  #let rows06 = (
    row([401.bzip2], [360.6], [-7.3], ("s", [7.5]), [-1.1], ("f", [10.8])),
    row([429.mcf], [233.8], ("s", [1.4]), [-2.9], ("f", [2.7]), [-3.6]),
    row([445.gobmk], [322.3], [-3.3], ("f", [6.4]), ("s", [2.4]), [1.7]),
    row([456.hmmer], [284.3], [1.8], ("f", [6.1]), ("s", [5.0]), [-37.6]),
    row([462.libquantum], ("f", [256.4]), [-10.1], ("s", [-1.1]), [-2.2], [-6.7]),
    row([471.omnetpp], [305.7], ("s", [0.7]), ("s", [0.4]), ("f", [1.2]), ("f", [1.2])),
    row([433.milc], ("f", [349.1]), [-16.6], ("f", [0.1]), [-13.8], ("s", [-7.0])),
    row([470.lbm], [184.0], [-7.9], ("f", [3.0]), ("s", [2.3]), [1.4]),
    row([482.sphinx3], [366.0], [-37.5], ("f", [1.6]), [-3.1], ("s", [-2.7])),
  )
  #let rows17 = (
    row([505.mcf_r], [344.9], ("s", [4.5]), [-1.6], ("f", [8.6]), [-4.7]),
    row([520.omnetpp_r], [475.7], ("f", [6.4]), ("f", [6.4]), ("s", [2.4]), ("s", [2.8])),
    row([531.deepsjeng_r], [299.9], [4.6], ("f", [16.0]), [9.9], ("s", [12.8])),
    row([541.leela_r], [439.5], [1.6], ("f", [7.1]), [0.4], ("s", [1.9])),
    row([557.xz_r], [371.5], [-0.6], ("s", [11.9]), ("f", [12.1]), [-8.5]),
    row([508.namd_r], [236.5], [2.5], ("f", [23.5]), [9.1], ("f", [23.8])),
    row([519.lbm_r], [261.8], [1.4], ("f", [57.7]), ("s", [50.9]), ("f", [58.1])),
    row([538.imagick_r], [479.3], [-16.9], ("s", [115.5]), ("f", [118.8]), ("f", [118.4])),
    row([544.nab_r], [417.5], [5.8], ("s", [132.1]), ("s", [131.3]), ("f", [134.4])),
  )
  #set figure(supplement: "Table")
  #grid(
    columns: (60%, 1fr),
    column-gutter: 16pt,
    align: horizon,
    figure(
      kind: table,
      {
        set text(size: 13pt)
        let hd(body) = text(fill: white, weight: "bold", body)
        table(
          columns: 6,
          align: (left,) + (right,) * 5,
          stroke: none,
          inset: (x: 5pt, y: 1.6pt),
          fill: (_, y) => if y < 3 { palette.text },
          table.hline(stroke: 0.8pt + palette.text),
          table.cell(rowspan: 3, align: center + horizon)[*Benchmarks*],
          table.cell(rowspan: 3, align: center + horizon)[*Runtime* \ *Basic*],
          table.cell(colspan: 4, align: center)[*Diff. from Basic (Basic $-$ x)*],
          table.hline(start: 2, stroke: 0.5pt + palette.muted.lighten(40%)),
          table.cell(rowspan: 2, align: center + horizon)[#hd[PBQP]],
          table.cell(rowspan: 2, align: center + horizon)[#hd[Greedy]],
          table.cell(colspan: 2, align: center)[#hd[RL4ReAl]],
          table.hline(start: 4, end: 6, stroke: 0.5pt + palette.muted.lighten(40%)),
          table.cell(align: center)[#hd[L]], table.cell(align: center)[#hd[G]],
          table.hline(stroke: 0.6pt + palette.text),
          ..rows06.flatten(),
          table.hline(stroke: 0.6pt + palette.text),
          ..rows17.flatten(),
          table.hline(stroke: 0.6pt + palette.text),
          table.cell(colspan: 2, align: right)[*Average*], [-3.9], [21.7], [18.7], [16.5],
          table.hline(stroke: 0.8pt + palette.text),
        )
      },
      caption: [Runtime improvement (s) on x86 over Basic, highlighting the #box(fill: palette.accent.lighten(70%), outset: 2pt)[Highest] and #box(fill: palette.highlight.lighten(40%), outset: 2pt)[Second highest] improvements (Table 3)],
    ),
    {
      set text(size: 15pt)
      card([Reading])[
        Speedup over Basic: L 14 / 18, G 11 / 18 \
        Beats Greedy: L 5, G 6; most slow-downs within 1% of Greedy \
        Average below Greedy: 21.7 vs. L 18.7, G 16.5
      ]
      card([Support range])[
        *Supports*: competitive with tuned heuristics, x86 \
        *Cannot infer*: gain of each agent (no ablation) \
        *Cannot infer*: benefit of $R_G$; G worse than L (hmmer $-37.6$)
      ]
    },
  )
]

#section[Summary]

#slide(source: [Assignment note: generative AI (Claude) was used to organize slides, draw diagrams and typeset formulas; all statements were checked against the paper.])[Summary, Open Question & Next Steps][
  #equal-row(
    columns: (1fr, 1fr, 1fr),
    gutter: 12pt,
    ..(
      ("1", [Legal by construction], [$chi(v)$ masks the coloring actions; no repair step]),
      ("2", [Decomposition], [Four agents mirror Greedy's sub-tasks: order, task, split, color]),
      ("3", [Rewards, no labels], [Spill weights per step; throughput vs. Greedy per function]),
    ).map(((k, name, body)) => h => { set block(height: h); mini(k, name, body) }),
  )
  #v(6pt)
  #callout(title: [Open question: how are the highlights in Table 3 decided?], kind: "warn")[
    Near-equal values share a mark (namd_r: 23.5 / 23.8); Basic counts as 0 (libquantum, milc). \
    But sphinx3 marks G $-2.7$ second over Basic 0; otherwise "17 / 18" becomes 16 / 18. \
    Rule not stated (Sec. 6.3, p. 8).
  ]
  - *Directions for the 40-minute in-depth study*
    - Training: PPO over four agents; where $R_G$ enters#footnote[Schulman et al., 2017]
]

// #include "appendix.typ"
