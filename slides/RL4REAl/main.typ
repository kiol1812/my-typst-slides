#import "@local/theme-academic:0.2.1": *
#import "@preview/cetz:0.5.2"
#import "assets/ops.typ": ops

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

// ───────── 封面 ─────────
#title-slide(
  title: title-text,
  authors: [S. VenkataKeerthy#super[†], Siddharth Jain#super[†], Anilava Kundu#super[†], Rohit Aggarwal#super[†], Albert Cohen#super[‡], Ramakrishna Upadrasta#super[†]],
  affiliations: [#super[†]IIT Hyderabad, India #h(1em) #super[‡]Google, France],
  venue: [CC 2023 (32nd ACM SIGPLAN International Conference on Compiler Construction); read: author's version, arXiv:2204.02013v3],
  year: [],
  presenters: ([11557028 楊育哲]),
  date: [2026/11/18],
)

#section[Problem]

#slide(source: src[Figure 2, p. 3; Sec. 1, p. 1; Sec. 2.1–2.2, pp. 2–3; Sec. 6.1–6.2, pp. 7–8; objective summarized from Sec. 2.2])[Research Problem & Optimization Problem][
  #figure(
    image("assets/fig-2.png", width: 52%),
    caption: [3 registers: without splitting, $i$ is spilled; splitting $i$ at point 5 makes $G$ 3-colorable (Figure 2)],
  )
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 14pt,
    card([Instance level: one function, interference graph $G(V, E)$])[
      *Adjustable*: per virtual register $v$: register $r in chi(v)$, spill $mu(v)$, or split $phi(v, k)$ \
      *Objective*: fewer spills, low spill cost $M(v)$ #sym.arrow.r faster code \
      *Constraints*: $chi(v^t) = chi^cal(T)(v^t) inter chi^cal(C)(v^t) inter chi^cal(I)(v^t)$, exact
    ],
    card([Learning level: the allocation policies], color: palette.accent)[
      *Adjustable*: policies $pi_omega$ of four agents $omega in Omega$ \
      *Given*: MIR functions with 120–500 vertices; LLVM spill weights $M$ \
      *Goal*: maximize rewards built from $M$ (and throughput) \
      *No labels*: optimal allocation unknown (NP-complete)
    ],
  )
  - *Interference*: $E = {(v_i, v_j) : L(v_i) inter L(v_j) != emptyset}$, live range $L(v) = [P_v^"def", P_v^"end"]$
]

#section[Background]

#slide(source: src[Sec. 1, pp. 1–2; Sec. 2.3, p. 3; Sec. 7, p. 10 (summarized in own words); diagram drawn by the presenter from Sec. 2.3])[Existing Approaches & Difficulties][
  #figure(scale(85%, reflow: true, ops()), caption: [Four strategies of LLVM Greedy: spill, split, coalesce, evict (Sec. 2.3)])
  #grid(
    columns: (1fr, 1fr, 1.15fr),
    column-gutter: 10pt,
    card([Solver-based: ILP, PBQP])[Exact or near-optimal \ #text(fill: palette.accent)[Scalability issues]],
    card([Heuristics: LLVM Greedy])[Near-linear time \ #text(fill: palette.accent)[Man-decades of tuning, per architecture]],
    card([Prior ML: LSTM; RL for PBQP#footnote[Das et al. 2020; Kim et al. 2022 (refs. [20], [32] of VenkataKeerthy et al.). Described from VenkataKeerthy et al., pp. 2, 10; not read by the presenter.]], color: palette.accent)[
      Coloring only, or prune PBQP search \
      #text(fill: palette.accent)[Correction phase; not end-to-end in LLVM]
    ],
  )
  - *Why ML is hard here*: many sub-tasks; hard correctness constraints; Python models vs. C++ compiler
  #callout(title: [What the authors want to improve], kind: "info")[Learn all main sub-tasks end-to-end inside LLVM, legal by construction, without hand-tuned heuristics.]
]

#slide(source: src[Sec. 2.2, p. 3; Sec. 2.3, p. 3; Sec. 3.2, p. 5; Sec. 6.1, p. 7. C: Schulman et al. 2017, Eq. (7), supplementary source])[Prerequisite Methods: Core Formulas][
  #set text(size: 16pt)
  #grid(
    columns: (1fr, 0.8fr, 1.3fr),
    column-gutter: 12pt,
    card([A. Coloring with split / spill#footnote[Chaitin et al. 1981 (ref. [11] of VenkataKeerthy et al.). Described from VenkataKeerthy et al., p. 3; not read by the presenter.]])[
      $k$ registers $=$ $k$ colors on $G$ \
      Not $k$-colorable: spill $mu(v)$ (cost $M(v)$) or split
      $ phi(v, k): L(v) ~> (L(v'), L(v'')) $
      $ L(v') = [P_v^"def", P_v^k], L(v'') = [P_v^(k+1), P_v^"end"] $
      *Difficulty*: which $v$, which $k$, which order
    ],
    card([B. LLVM Greedy])[
      Priority queue: spill cost, live-range size \
      Per $v$: assign, evict, split, or spill \
      *Role*: default allocator at `-O3` \
      *Difficulty*: hand-tuned heuristics; regressions fixed case by case
    ],
    card([C. PPO#footnote[Schulman et al. 2017 (ref. [46] of VenkataKeerthy et al.), Eq. (7). Supplementary source: RL4ReAl only names PPO with standard hyperparameters (pp. 3, 7).]: policy update], color: palette.accent)[
      $ r_t (theta) = (pi_theta (a_t | s_t)) / (pi_(theta_"old") (a_t | s_t)) $
      $ L^"CLIP" (theta) = hat(EE)_t [min(r_t hat(A)_t, \ "clip"(r_t, 1 - epsilon, 1 + epsilon) hat(A)_t)] $
      #note[$hat(A)_t$: advantage estimate; $epsilon$: clip range] \
      *Role*: learns $pi$ from rewards, no labels \
      *Clip*: small, stable policy steps
    ],
  )
  #v(4pt)
  *RL4ReAl keeps* $chi(v)$ as hard action masks and Greedy's decision types; *replaces* hand-tuned choices with four learned policies; *trains* them with C; *adds* MIR2Vec + GGNN states
]

#section[Method]

#slide(source: src[Figure 3, p. 5 (cropped); agent states and action spaces from Sec. 3.2, pp. 4–5; table re-typeset, notation unchanged])[Main Method (1): Hierarchical Masked Agents][
  #figure(
    image("assets/fig-3.png", width: 64%),
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
    [Coloring $omega_xi$ (low)], [$chevron.l [|v|], |chi(v)|, |V_"nclr"| chevron.r$], [$chi(v)$ if $|chi(v)| > 0$, else spill $mu(v)$],
    table.hline(stroke: 0.8pt + palette.text),
  )
  #v(2pt)
  Order $omega_upsilon prec omega_tau prec {omega_phi, omega_xi}$; illegal registers are never offered #sym.arrow.r no correction phase
]

#slide(source: src[rewards from Sec. 3.2, pp. 4–6; loop arranged by the presenter from Sec. 3.2, Sec. 5 (p. 6) and Algorithm 1 (p. 5); PPO update schedule not stated in the paper])[Main Method (2): Rewards & Allocation Loop][
  #set text(size: 16pt)
  #grid(
    columns: (1fr, 1.1fr),
    column-gutter: 14pt,
    [
      *Coloring* #note[high spill weight $=$ important node]
      $ R(omega_xi) = cases(+M(v) & "if colored, " r in chi(v), -M(v) & "if spilled, " mu(v)) $
      *Splitting* #note[positive if total spill weight drops]
      $ R(omega_phi) = M(v) - sum_(i in {v', v''}) M(i) $
      *Task / node selector* #note[split reward deferred]
      $ R(omega_tau) = R(omega_upsilon) = cases(R(omega_xi) & quad tau = chi, 0 & quad tau = phi) $
      *Global* (model G only) #note[LLVM-MCA throughput]
      $ R_G = cases(+10 & quad "if Th"_"RL4ReAl" >= "Th"_"Greedy", -10 & quad "otherwise") $
    ],
    block(
      fill: palette.highlight.lighten(85%),
      inset: 10pt,
      radius: 4pt,
      width: 100%,
      {
        [*One function, restated* (own arrangement)]
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

#slide(source: src[Table 3 and Sec. 6.3, p. 8; Sec. 6.1–6.2, pp. 7–8; table re-typeset, values unchanged; marks added by the presenter])[Evidence: Runtime on x86 SPEC CPU][
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
  #grid(
    columns: (1fr, 1.1fr),
    column-gutter: 16pt,
    card([Setup. Claim: on par with LLVM allocators])[
      *Machine*: Xeon W2133; LLVM 10.0.1; median of 3 runs \
      *Train*: PPO, 5K random SPEC 2017 functions; others by Greedy \
      *Compared*: Basic, PBQP, Greedy; L $=$ local, G $=$ + global reward \
      *Not stated*: whether test functions were held out
    ],
    card([Reading], color: palette.accent)[
      Speedup over Basic: L 14 / 18, G 11 / 18 benchmarks \
      Beats Greedy: L 5, G 6; average still below Greedy \
      *Supports*: competitive with tuned heuristics, x86 \
      *Cannot infer*: gain of each agent; G not better than L (hmmer $-37.6$)
    ],
  )
]

#section[Summary]

#slide(source: [Assignment note: generative AI (Claude) was used to organize slides, draw diagrams and typeset formulas; all statements were checked against the paper.])[Summary, Open Question & Next Steps][
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 12pt,
    mini("1", [Legal by construction])[$chi(v)$ masks the coloring actions; no repair step],
    mini("2", [Decomposition])[Four agents mirror Greedy's sub-tasks: order, task, split, color],
    mini("3", [Rewards, no labels])[Spill weights per step; throughput vs. Greedy per function],
  )
  #v(6pt)
  #callout(title: [Open question: how is the global reward used in training?], kind: "warn")[
    $R_G = plus.minus 10$ is computed once per function, but the agents get per-step rewards. \
    Which agents receive $R_G$, at which step, with what discount? Not stated (pp. 5–7).
  ]
  - *Directions for the 40-minute in-depth study*
    - PPO with four cooperating agents: joint or separate updates#footnote[Schulman et al. 2017 (ref. [46] of VenkataKeerthy et al.). Not read yet; planned for the in-depth study.]
    - Ablation idea: remove the splitter, or replace masks by penalties
]

#appendix()

#slide(source: src[Figure 1, p. 3 (re-typeset); Sec. 2.1, pp. 2–3; notation unchanged])[Appendix A: Correctness Constraints in Detail][
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 16pt,
    figure(
      rect(
        inset: 0pt,
        width: 100%,
        stroke: 0.8pt + palette.text,
        grid(
          columns: (1fr, 1.9fr),
          stroke: (x, y) => if x == 1 { (left: 0.8pt + palette.text) } else { none },
          pad(0.3em)[
            #set text(size: 12pt)
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
          ],
          pad(0.3em)[
            #set text(size: 12pt)
            ```text
            MOV32ri 0, %i:gr32
            MOV32ri 10, %x:gr32
            MOV32ri 20, %y:gr32
            <call print on %x>
            $eax = COPY %y:gr32
            <clear $edx>
            IDIV32r %x:gr32,
              implicit-def $eax,
              implicit-def $edx
            %z:gr32 = COPY $eax
            %i:gr32 = ADD32ri %i:gr32, 1
            ...
            ```
          ],
        ),
      ),
      caption: [(a) Source and (b) its Machine IR (Figure 1)],
    ),
    [
      #set text(size: 17pt)
      *Type*: register file $cal(R) = union.big_t R_t$
      $ chi^cal(T)(v^t) = {v^t ▶ r : r in R_t} $
      #note[`%x:gr32` may only take a 32-bit general register]

      *Congruence*: $C(r)$ = chunks of one register \
      #note[`$al`, `$ah` $subset.eq.sq$ `$ax` $subset.eq.sq$ `$eax` $subset.eq.sq$ `$rax`]
      $ chi^cal(C)(v^t) = {v_i^t ▶ r : forall v_i, v_j in cal(V), v_i != v_j, v_j ▶ r' in L(v_i)} $ \
      #note[for all $r' in C(r)$]

      *Interference*: no neighbor holds $r$
      $ chi^cal(I)(v^t) = R^t without {r : forall u ((u, v) in E and (u ▶ r))} $
      #note[pre-assigned: `IDIV32r` fixes `$eax`, `$edx`]
    ],
  )
]

#slide(source: src[Sec. 4, pp. 6–7; Sec. 5, p. 6; Sec. 6.1, p. 7])[Appendix B: Representing the Interference Graph][
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 16pt,
    card([MIR2Vec: instruction embedding])[
      Triplets: $"NextInst"$, $"Arg"_i$ #sym.arrow.r TransE, 100-dim seed vocabulary \
      Opcodes grouped by kind (x86: 15.3K opcodes, e.g. $approx 200$ MOVs)
      $ W_o dot [|O|] + W_a dot ([|A_1|] + dots.c + [|A_n|]), quad W_o > W_a $
      $W_o, W_a in (0, 1]$; vertex $[|v|] in RR^(m times n)$, $m$ instructions in $L(v)$
    ],
    card([GGNN: graph state], color: palette.accent)[
      $RR^(m times n) -> RR^d$, $d = n$ \
      Node types: not visited, spill, colored; plus spill weights \
      Message passing, GRU update #sym.arrow.r $[|G|]$ for $omega_upsilon$
    ],
  )
  - *LLVM-gRPC*: bidirectional RPC between Python agents and the C++ `MLRegAlloc` pass
  - Splits are applied by LLVM, which returns new interferences and live ranges
  - Python bindings were rejected: large overhead #note[(p. 6)]
]

#slide(source: src[Table 5 (cropped) and Sec. 6.4, p. 9])[Appendix C: Runtime on AArch64][
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 16pt,
    figure(
      image("assets/tab-5.png", height: 305pt),
      caption: [Runtime gain over Basic on ARM Cortex A72, Basic $-$ x (s); green: highest, yellow: second (Table 5)],
    ),
    [
      - Only RL4ReAl-G is reported
      - Average: Greedy 19.1 s, RL4ReAl 18.4 s, PBQP 5.3 s
      - Highest or second highest on all but four benchmarks
      - Cross-compiled from x86; median of 3 runs (5 if runs differ by $approx$ 20 s)
      - Some benchmarks skipped #note[(cross-compilation issues or baseline failures)]
    ],
  )
]

#slide(source: src[Table 2, p. 8 (cropped); Sec. 6.3, pp. 8–9; Sec. 6.5, pp. 9–10])[Appendix D: Hot Functions & Policy Improvement][
  #figure(
    image("assets/tab-2.png", width: 38%),
    caption: [% runtime difference over Basic on hot functions; bold: best per row (Table 2)],
  )
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 16pt,
    [
      - SPEC 2017: L 7.3% vs. Greedy 6.2% on average
      - SPEC 2006: all three slower than Basic
      - BZ2_compressBlock: Greedy $-51.3%$, RL4ReAl-G $-5.2%$
    ],
    [
      - Fine-tune on hot functions of regressions
      - milc (L) $+12$ s; hmmer, xz (G) $+10$ s, $+6$ s
      - Authors: a case for online / continuous learning
    ],
  )
]
