#import "@local/theme-academic:0.2.1": *
#import "@preview/cetz:0.5.2"
#import "assets/sorting-network.typ": sorting-network
#import "assets/swap-move.typ": swap-move
#import "assets/mcts-loop.typ": mcts-loop

#let title-text = "Faster Sorting Algorithms Discovered Using Deep Reinforcement Learning"

#show: deck.with(footer: [AlphaDev (Mankowitz et al., Nature 2023)], text-size: 21pt)

#let palette = default-palette + (:)

#set figure(supplement: "Figure", numbering: none)
#show figure: set block(below: 0.6em)
#show table: set text(size: 16pt)
#show footnote.entry: set text(size: 13pt, fill: palette.muted)
#set footnote.entry(clearance: 8pt, gap: 4pt)
#show list: set block(above: 0.55em, below: 0.55em)
#show math.equation.where(block: true): set block(above: 0.5em, below: 0.5em)

#let note(body) = text(size: 15pt, fill: palette.muted, body)
#let src(body) = [Source: Mankowitz et al. (Nature 2023), #body]
#let eq(n, e) = math.equation(block: true, numbering: (..) => [(#n)], e.body)

// ───────── 封面 ─────────
#title-slide(
  title: title-text,
  authors: text(size: 16pt)[Daniel~J.~Mankowitz#super[1,3], Andrea~Michi#super[1,3], Anton~Zhernov#super[1,3], Marco~Gelmi#super[1,3], Marco~Selvi#super[1,3], Cosmin~Paduraru#super[1,3], Edouard~Leurent#super[1,3], Shariq~Iqbal#super[1], Jean-Baptiste~Lespiau#super[1], Alex~Ahern#super[1], Thomas~Köppe#super[1], Kevin~Millikin#super[1], Stephen~Gaffney#super[1], Sophie~Elster#super[1], Jackson~Broshear#super[1], Chris~Gamble#super[1], Kieran~Milan#super[1], Robert~Tung#super[1], Minjae~Hwang#super[2], Taylan~Cemgil#super[1], Mohammadamin~Barekatain#super[1], Yujia~Li#super[1], Amol~Mandhane#super[1], Thomas~Hubert#super[1], Julian~Schrittwieser#super[1], Demis~Hassabis#super[1], Pushmeet~Kohli#super[1], Martin~Riedmiller#super[1], Oriol~Vinyals#super[1], David~Silver#super[1]],
  affiliations: [#super[1]DeepMind, London, UK #h(1em) #super[2]Google, Mountain View, CA, USA #h(1em) #super[3]Equal contribution],
  venue: [Nature, Vol. 618, pp. 257–263 (2023)],
  year: [],
  presenters: ([11557028 楊育哲]),
  date: [2026/11/18],
)

#section[Problem]

#slide(source: src[pp. 257–259, Fig. 2; Methods: Action pruning rules; objective summarized from p. 258])[Research Problem & Optimization Problem][
  - Small sorts (sort 3–5, VarSort3–5) in LLVM libc++ `std::sort`, called trillions of times a day
  #set text(size: 16pt)
  #equal-row(
    columns: (1fr, 1fr),
    h => card([Optimization problem], height: h)[
      $ min_(P = (a_1, ..., a_T)) "Latency"(P) quad "s.t." quad P(x) = "sort"(x), forall x in X $
      *Adjustable*: program $P$, a sequence of x86 instructions \
      #note[`mov`, `cmp`, `cmovX`, `jX` over registers and memory] \
      *Given*: test inputs $X$ with expected outputs \
      #note[sort 3: all unsorted sequences of length 3] \
      *Objective*: measured latency, or length $|P|$ as a proxy \
      *Constraints*: correct on every $x in X$; limited steps; pruned actions
    ],
    h => block(height: h, align(horizon, figure(
      image("assets/fig-2.png", width: 100%),
      caption: [(a) append an instruction; (b) outputs vs. expected outputs give $r_t$ (Figure 2)],
    ))),
  )
  #card([As a single-player game: AssemblyGame])[
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 14pt,
      row-gutter: 0.5em,
      [*State* $S_t = chevron.l P_t, Z_t chevron.r$ #note[program; memory + registers on $X$]],
      [*Action* $a_t$: append one legal instruction],
      [*Reward* $r_t$: correctness + latency],
      [*Win*: correct, low latency; *Lose*: incorrect or slow],
    )
    *Why hard*: search space like chess ($10^120$) and Go ($10^700$); one wrong instruction invalidates the program
  ]
]

#section[Background]

#slide(source: src[pp. 257, 261; Methods: Brute-force approach, AlphaDev-S, Related work])[Existing Approaches & Difficulties][
  #table(
    columns: (auto, auto, auto, 1fr),
    align: left + horizon,
    inset: (x: 8pt, y: 5pt),
    fill: (_, y) => if y == 0 { palette.primary },
    [*Approach*], [*How it works*], [*Strength*], [*Difficulty*],
    [Sorting networks (human)], [Fixed comparators, `cmp` + `cmov`], [Branchless; in libc++], text(fill: palette.accent)[Already optimized; VarSort needs branches],
    [Enumerative search], [Enumerate programs, prune], [Proves optimality], text(fill: palette.accent)[Sort 3: $approx 10^32$ programs, $>$ 3 days],
    [Stochastic search#footnote[Schkufza et al., 2013 (STOKE)]], [MCMC: mutate, keep low cost], [Good with warm start], text(fill: palette.accent)[Local optima; length as latency proxy],
    [Symbolic search], [SAT / SMT / MIP solvers], [Exact], text(fill: palette.accent)[Scaling; expert formulation],
    [Deep learning for code], [LLMs, input–output synthesis], [Correct programs], text(fill: palette.accent)[Not aimed at low latency],
  )
  #callout(title: [Goal of the authors], kind: "info")[Correct, lower-latency sorting routines from scratch, by optimizing measured latency at the instruction level]
  - *Length $!=$ latency* once branching appears (VarSort)
]

#slide(source: src[Methods: AlphaZero (Eqs. (1), (3)), Sorting networks, AlphaDev-S; diagram self-drawn from Extended Data Fig. 2])[Prerequisite Methods: Core Formulas][
  #{
    set text(size: 16pt)
    equal-row(
    columns: (1fr, 1.25fr),
    h => card([A. Sorting network (human benchmark)], height: h)[
      #align(center, sorting-network(gap: 0.6))
      #note[input (2, 3, 1, 4); red: comparators that swap] \
      Comparator on wires $(i, j)$, $i < j$:
      $ (x_i, x_j) <- (min(x_i, x_j), max(x_i, x_j)) $
      #note[assembly: `cmp` + `cmovl` / `cmovg`, no branch] \
      *Role*: fixed, branchless sort \
      *Difficulty*: comparator count is already optimal
    ],
    h => block(height: h, stack(
      spacing: 10pt,
      card([B. AlphaZero#footnote[Silver et al., 2018]: MCTS + learned policy / value])[
        #grid(
          columns: (1fr, 1fr),
          column-gutter: 8pt,
          eq(1, $ h_t = f^"rep" (S_t) $),
          eq(3, $ hat(v)_t, hat(pi)_t = f^"pred" (h_t) $),
        )
        $ P(a_t = a) = N(S_t, a) \/ sum_b N(S_t, b), quad hat(pi)_t -> "visit counts" $
        #note[$hat(v)_t$: expected return; tree search uses the true dynamics and reward; $N$: visit count] \
        *Role*: search distilled into a policy, no human data \
        *Difficulty*: one value head; board-game state
      ],
      card([C. Stochastic search, as AlphaDev-S (baseline)])[
        $ c = "correctness" + alpha times "performance" $
        #note[correctness: share of misplaced items $(P - P C_t) \/ P$; performance: program length; mutate, accept lower $c$ w.h.p.]
      ],
    )),
    )
  }
  *AlphaDev keeps* B's MCTS + policy / value net; *replaces* board state with program + CPU state; *adds* a latency value head and correctness / latency rewards
]

#section[Method]

#slide(source: src[pp. 258–259 (DRL for discovering faster algorithms; Transformer encoder; Latency value functions); Methods: AlphaZero, Action pruning rules; Extended Data Fig. 1; diagram self-drawn])[Main Method: AlphaZero on AssemblyGame][
  #{
    set text(size: 15pt)
    equal-row(
    columns: (1fr, 1.15fr),
    h => block(height: h, {
      layout(size => {
        let fig = mcts-loop()
        scale(size.width / measure(fig).width * 100%, reflow: true, fig)
      })
      v(1fr)
      set text(size: 21pt)
      [*Changes vs. AlphaZero*: \ program + CPU-state encoder; two value heads; latency predicted during search, \ measured on $< 0.002%$ of programs]
    }),
    h => block(height: h, stack(
      spacing: 8pt,
      card([(A) State representation: replaces the board encoder])[
        $ S_t = chevron.l P_t, Z_t chevron.r, quad h_t = f^"rep" (S_t) $
        #note[$P_t$: one-hot opcode + operands per instruction #sym.arrow.r Transformer encoder; $Z_t$: each register and memory location #sym.arrow.r MLP (CPU state encoder); the two embeddings are combined]
      ],
      card([(B) Reward: correctness + latency])[
        $ r_t = r_t^"corr" + r_t^"lat" $
        #note[$r_t^"corr"$: outputs of $P_t$ on $N$ test inputs vs. expected outputs; $r_t^"lat"$: penalty on program length, or measured latency]
      ],
      card([(C) Dual value heads: new vs. AlphaZero])[
        $ hat(v)_t^"corr", hat(v)_t^"lat", hat(pi)_t = f^"pred" (h_t) $
        #note[latency head trained with the program's actual latency as a Monte Carlo target; substantially better than one value head (p. 259)]
      ],
    )),
    )
  }
]

#section[Evidence]

#slide(source: src[p. 259 (Fixed sorting algorithms); Figure 3a–c (network self-drawn); Methods: AlphaDev-S, Fixed sort, p. 261])[Evidence (1): Setup of Fixed Sort][
  #set text(size: 16pt)
  #table(
    columns: (auto, 1fr),
    align: (left + horizon, left + horizon),
    stroke: none,
    inset: (x: 8pt, y: 3pt),
    fill: (_, y) => if y == 0 { palette.text } else if calc.even(y) { palette.text.lighten(93%) },
    table.hline(stroke: 0.8pt + palette.text),
    [*Term*], [*Description*],
    [*Claim*], [Shorter fixed sorts than human benchmarks, found from scratch],
    [*Task / data*], [Sort 3 / 4 / 5, branchless (`cmp` + `cmov` only)],
    [*Model*], [AlphaDev: AlphaZero MCTS + Transformer and CPU-state encoders],
    [*Compared*], [Human sorting networks (libc++); AlphaDev-S-CS (cold start: empty program); AlphaDev-S-WS (warm start: near-optimal program)],
    [*Same*], [Instruction set, action pruning, correctness check; AlphaDev-S given $>=$ same compute and wall-clock time],
    [*Changed*], [Search method and starting program],
    [*Metric*], [Program length, lower is better #note[length $approx$ latency when branchless]],
    table.hline(stroke: 0.8pt + palette.text),
  )
  #figure(
    swap-move(),
    caption: [Sort 3: swap move removes one instruction (Figure 3a–c)],
  )
]

#slide(source: src[Table 1a, p. 259; Extended Data Table 2a–c (values unchanged); Methods: Fixed sort, p. 261; Supplementary Information, Appendix B])[Evidence (2): Reading Fixed Sort][
  #set text(size: 15pt)
  #grid(
    columns: (1.1fr, 1fr),
    column-gutter: 14pt,
    align: horizon,
    {
      set figure(supplement: "Table")
      figure(
        kind: table,
        {
          table(
            columns: (auto, 1fr, 1fr, 1fr),
            align: (left + horizon,) + (center + horizon,) * 3,
            stroke: none,
            inset: (x: 6pt, y: 2.5pt),
            fill: (_, y) => if y == 0 { palette.text },
            table.hline(stroke: 0.8pt + palette.text),
            [], [*Sort 3*], [*Sort 4*], [*Sort 5*],
            [Length: human], [18], [28], [46],
            [Length: AlphaDev], [*17*], [*28*], [*42*],
            [Length: S-WS / S-CS], [17 / N/S], [28 / N/S], [42 / N/S],
            table.hline(stroke: 0.6pt + palette.muted),
            [\# programs: AlphaDev], [446K], [1.3M], [6.23M],
            [\# programs: S-WS], [51.7M], [338K], [170B],
            [\# programs: S-CS], [77.5B], [325B], [1.9T],
            table.hline(stroke: 0.8pt + palette.text),
          )
          note[N/S: no sorting program found]
        },
        caption: [Length and programs explored (Table 1a; Extended Data Table 2a–b)],
      )
    },
    {
      card([Reading])[
        Length vs. human: sort 3 $18 -> 17$, sort 4 tie (28), sort 5 $46 -> 42$ \
        S-WS matches AlphaDev; S-CS finds no sorting program \
        Programs explored: fewer than S-WS on sort 3 / 5, more on sort 4 (1.3M vs. 338K)
      ]
      card([Support range])[
        *Supports*: shorter branchless sort 3 / 5 without a starting program \
        *Cannot infer*: latency gain (length is the objective here; Supp. App. B) \
        *Cannot infer*: edge over warm-started search (S-WS ties, less wall-clock; ED Table 2c)
      ]
    },
  )
]

#section[Summary]

#slide(source: [#src[pp. 258–262 (Generalization to additional domains; Discussion); Figure 3; Table 1.] Assignment note: generative AI (Claude) was used to organize slides and typeset formulas; all statements were checked against the paper.])[Summary, Open Question & Next Steps][
  #equal-row(
    columns: (1fr, 1fr, 1fr),
    gutter: 12pt,
    ..(
      ("1", [Program search as a game], [Append one instruction per step; reward $=$ correctness + latency]),
      ("2", [Search + two values], [AlphaZero MCTS; correctness and latency heads guide search without timing every program]),
      ("3", [Evidence], [Fixed sort: sort 3 $18 -> 17$, sort 5 $46 -> 42$; swap move drops one instruction (Figure 3)]),
    ).map(((k, name, body)) => h => { set block(height: h); mini(k, name, body) }),
  )
  #v(6pt)
  #callout(title: [Open question: how far does AlphaDev generalize?], kind: "warn")[
    Beyond sorting: VarInt (27 vs. 31 instructions, $approx 3 times$ faster), competitive coding (Table 1) \
    Hashing, logic in large functions: possible "in theory", not tested (Discussion, p. 262) \
    Without an exhaustive test set, how are correctness and reward defined?
  ]
  - *Directions for the 40-minute in-depth study*
    - Search: how MCTS combines $hat(v)^"corr"$ and $hat(v)^"lat"$
    - Baseline: MCMC acceptance in stochastic superoptimization (STOKE) vs. MCTS exploration
]
