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
// TODO, page 2.
// tablealize old methods

#section[Method]

#slide(source: src[Figure 3, p. 5 (cropped); agent states and action spaces from Sec. 3.2, pp. 4–5; table re-typeset])[Main Method (1): Hierarchical Masked Agents][
  #figure(
    image("assets/fig-3.png", width: 78%),
    caption: [LLVM builds $G$ and MIR2Vec features; agents decide via gRPC; LLVM applies splits and the final color map (Figure 3)],
  )
  #set text(size: 16pt)
  #table(
    columns: (auto, 1fr, 1.15fr),
    align: (left + horizon, left + horizon, left + horizon),
    stroke: none,
    inset: (x: 6pt, y: 3.5pt),
    table.hline(stroke: 0.8pt + palette.text),
    [*Agent* (level)], [*State*], [*Legal action space* (mask)],
    table.hline(stroke: 0.6pt + palette.muted),
    [Node selector $omega_upsilon$ (top)], [$chevron.l [|G|], M(V) chevron.r$ #note[GGNN embeddings]], [$A(omega_upsilon) = V_"nclr"$ (uncolored nodes)],
    [Task selector $omega_tau$ (mid)], [$chevron.l [|v|], |chi(v)|, delta(v), |K(v)|, M(v) chevron.r$], [${phi, chi}$ if $|K(v)| >= k$ ($k = 2$), else $chi$],
    [Splitter $omega_phi$ (low)], [$chevron.l [|v|], cal(M)(v), D_v chevron.r$ #note[use weights, distances]], [$A(omega_phi) = K$ (use points of $v$)],
    [Coloring $omega_xi$ (low)], [$chevron.l [|v|], |chi(v)|, |V_"nclr"| chevron.r$], [$chi(v)$ if $|chi(v)| > 0$, $mu(v)$ otherwise],
    table.hline(stroke: 0.8pt + palette.text),
  )
  #v(2pt)
  Order $omega_upsilon prec omega_tau prec {omega_phi, omega_xi}$; illegal registers are never offered #sym.arrow.r no correction phase
]

#slide(source: src[rewards from Sec. 3.2, pp. 4–6; loop self-arranged from Sec. 3.2, Sec. 5 (p. 6) and Algorithm 1 (p. 5); PPO update schedule not stated in the paper])[Main Method (2): Rewards & Allocation Loop][
  #set text(size: 16pt)
  #grid(
    columns: (1fr, 1.1fr),
    column-gutter: 14pt,
    [
      *Coloring* #note[high spill weight $=$ important node]
      $ R(omega_xi) = cases(+M(v) & "if" chi(v), -M(v) & "if" mu(v)) $
      *Splitting* #note[positive if total spill weight drops]
      $ R(omega_phi) = M(v) - sum_(i in {v', v''}) M(i) $
      *Task / node selector* #note[split reward deferred]
      $ R(omega_tau) = R(omega_upsilon) = cases(R(omega_xi) & quad tau = chi, 0 & quad tau = phi) $
      *Global* (model G only) #note[LLVM-MCA throughput]
      $ R_G = cases(+10 & quad italic("Th")_italic("RL4ReAl") >= italic("Th")_italic("Greedy"), -10 & quad italic("Otherwise")) $
    ],
    block(
      fill: palette.highlight.lighten(85%),
      inset: 10pt,
      radius: 4pt,
      width: 100%,
      {
        [*One function, restated*]
        set par(leading: 0.5em)
        set enum(numbering: "1:", spacing: 0.6em)
        enum(
          [LLVM: MIR #sym.arrow.r $G$, MIR2Vec features; GGNN #sym.arrow.r $[|G|]$],
          [*while* $V_"nclr" != emptyset$:],
          [#h(1em)$v <- omega_upsilon$ over $V_"nclr"$; #h(4pt) $tau <- omega_tau$ (masked)],
          [#h(1em)*if* $tau = phi$: $k <- omega_phi$; LLVM splits $v -> v', v''$ (Alg. 1), returns new $G$],
          [#h(1em)*else*: $omega_xi$ picks $r in chi(v)$, or spills $v$ if $chi(v) = emptyset$],
          [Color map #sym.arrow.r LLVM: assign, spill, code generation],
          [Rewards above #sym.arrow.r PPO update of each $pi_omega$],
        )
      },
    ),
  )
]

#section[Evidence]

#slide(source: src[Table 3 and Sec. 6.3, p. 8; Sec. 6.1–6.2, pp. 7–8; table re-typeset, values unchanged; add marks])[Evidence: Runtime on x86 SPEC CPU][
  #let rl(v) = best[#v]
  #let rows06 = (
    ([401.bzip2], [-7.3], [7.5], [-1.1], rl[10.8]),
    ([429.mcf], [1.4], [-2.9], rl[2.7], [-3.6]),
    ([445.gobmk], [-3.3], [6.4], [2.4], [1.7]),
    ([456.hmmer], [1.8], [6.1], [5.0], [-37.6]),
    ([462.libquantum], [-10.1], [-1.1], [-2.2], [-6.7]),
    ([471.omnetpp], [0.7], [0.4], rl[1.2], rl[1.2]),
    ([433.milc], [-16.6], [0.1], [-13.8], [-7.0]),
    ([470.lbm], [-7.9], [3.0], [2.3], [1.4]),
    ([482.sphinx3], [-37.5], [1.6], [-3.1], [-2.7]),
  )
  #let rows17 = (
    ([505.mcf_r], [4.5], [-1.6], rl[8.6], [-4.7]),
    ([520.omnetpp_r], [6.4], [6.4], [2.4], [2.8]),
    ([531.deepsjeng_r], [4.6], [16.0], [9.9], [12.8]),
    ([541.leela_r], [1.6], [7.1], [0.4], [1.9]),
    ([557.xz_r], [-0.6], [11.9], rl[12.1], [-8.5]),
    ([508.namd_r], [2.5], [23.5], [9.1], rl[23.8]),
    ([519.lbm_r], [1.4], [57.7], [50.9], rl[58.1]),
    ([538.imagick_r], [-16.9], [115.5], rl[118.8], rl[118.4]),
    ([544.nab_r], [5.8], [132.1], [131.3], rl[134.4]),
  )
  #let tab(head, rows) = {
    set text(size: 13pt)
    table(
      columns: (auto, 1fr, 1fr, 1fr, 1fr),
      align: (left,) + (right,) * 4,
      stroke: none,
      inset: (x: 5pt, y: 2.2pt),
      table.hline(stroke: 0.8pt + palette.text),
      [*#head*], [PBQP], [Greedy], [RL-L], [RL-G],
      table.hline(stroke: 0.6pt + palette.muted),
      ..rows.flatten(),
      table.hline(stroke: 0.8pt + palette.text),
    )
  }
  #set figure(supplement: "Table")
  #figure(
    kind: table,
    grid(columns: (1fr, 1fr), column-gutter: 16pt, tab([SPEC CPU 2006], rows06), tab([SPEC CPU 2017], rows17)),
    caption: [Runtime gain over Basic, Basic $-$ x (s), higher is better; #best[bold]: RL4ReAl beats Greedy (Table 3). Average: PBQP $-3.9$, Greedy *21.7*, L 18.7, G 16.5],
  )
  #set text(size: 15pt)
  #show list: set block(above: 0.4em, below: 0.4em)
  #equal-row(
    columns: (1fr, 1.1fr),
    gutter: 16pt,
    h => card([Setup. Claim: on par with LLVM allocators], height: h)[
      *Machine*: Xeon W2133; LLVM 10.0.1; median of 3 runs \
      *Train*: PPO, 5K random SPEC 2017 functions; others by Greedy \
      *Compared*: Basic, PBQP, Greedy; L $=$ local, G $=$ + global reward \
      *Not stated*: whether test functions were held out
    ],
    h => card([Reading], height: h)[
      Speedup over Basic: L 14 / 18, G 11 / 18 benchmarks \
      Beats Greedy: L 5, G 6; average still below Greedy \
      *Supports*: competitive with tuned heuristics, x86 \
      *Cannot infer*: gain of each agent; G not better than L (hmmer $-37.6$)
    ],
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
  #callout(title: [Open question: how is the global reward used in training?], kind: "warn")[
    $R_G = plus.minus 10$ is computed once per function, but the agents get per-step rewards. \
    Which agents receive $R_G$, at which step, with what discount? Not stated (pp. 5–7).
  ]
  - *Directions for the 40-minute in-depth study*
    - PPO with four cooperating agents: joint or separate updates#footnote[Schulman et al., 2017]
    - Ablation idea: remove the splitter, or replace masks by penalties
]

// #include "appendix.typ"
