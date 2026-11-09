#import "@local/theme-academic:0.2.1": *
#import "@preview/cetz:0.5.2"
#import "assets/problem-setting.typ": problem-setting
#import "assets/greedy-loop.typ": greedy-loop
#import "assets/n-step-target.typ": n-step-target

#let title-text = "Learning Combinatorial Optimization Algorithms over Graphs"

#show: deck.with(footer: [S2V-DQN (Khalil et al., NIPS 2017)], text-size: 21pt)

#let palette = default-palette + (:)

#set figure(supplement: "Figure", numbering: none)
#show figure: set block(below: 0.6em)
#show table: set text(size: 16pt)
#show footnote.entry: set text(size: 13pt, fill: palette.muted)
#set footnote.entry(clearance: 8pt, gap: 4pt)
#show list: set block(above: 0.55em, below: 0.55em)
#show math.equation.where(block: true): set block(above: 0.5em, below: 0.5em)

#let note(body) = text(size: 15pt, fill: palette.muted, body)
#let src(body) = [Source: Khalil et al. (NIPS 2017), #body]

// ───────── 封面 ─────────
#title-slide(
  title: title-text,
  authors: [Hanjun Dai#super[†\*], Elias B. Khalil#super[†\*], Yuyu Zhang#super[†], Bistra Dilkina#super[†], Le Song#super[†§]],
  affiliations: [#super[†]Georgia Institute of Technology #h(1em) #super[§]Ant Financial #h(1em) #super[\*]Equal contribution],
  venue: [NIPS 2017 (Advances in Neural Information Processing Systems 30), proceedings version],
  year: [],
  presenters: ([11557028 楊育哲]),
  date: [2026/11/18],
)

#section[Problem]

#slide(source: src[Sec. 1, p. 2 (problem statement); Sec. 2, pp. 3–4; Sec. 4.1, p. 5; diagram self-drawn from these sections (MVC as the example)])[Research Problem & Optimization Problem][
  #align(center, problem-setting())
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 14pt,
    card([Instance level: one graph $G(V, E, w)$])[
      *Adjustable*: node subset $S subset.eq V$ (ordered for TSP) \
      *Objective* $c(h(S), G)$: MVC min $|S|$ s.t. all edges covered; MAXCUT max cut weight; TSP min tour length
    ],
    card([Learning level: the evaluation function], color: palette.accent)[
      *Adjustable*: $Theta = {theta_i}_(i=1)^7$ of $hat(Q)(h(S), v; Theta)$ \
      *Given*: $G tilde DD$; helper $h$, cost $c$, termination $t$ \
      *Goal*: cumulative reward $=$ objective of the final $S$
    ],
  )
  - *Constraints*: every partial $S$ stays feasible; no optimal labels; graph sizes vary
]

#section[Background]

#slide(source: src[Sec. 1, pp. 1–2; Sec. 4.2, p. 6 (summarized in own words)])[Existing Approaches & Difficulties][
  #grid(
    columns: (1fr, 1fr, 1fr, 1.25fr),
    column-gutter: 10pt,
    card([Exact], sub: [Branch-and-bound])[Integer programming \ #text(fill: palette.accent)[Too slow for large instances]],
    card([Approximation], sub: [Polynomial time])[Provable ratio \ #text(fill: palette.accent)[Weak or no guarantees]],
    card([Heuristics], sub: [Hand-designed])[Fast in practice \ #text(fill: palette.accent)[Problem-specific trial-and-error]],
    card([Deep learning], sub: [Pointer Net + PG#footnote[Vinyals et al. 2015; Bello et al. 2016 (refs. [37], [6] of Khalil et al.). Described from Khalil et al., p. 2; not read by the presenter.]], color: palette.accent)[
      Seq2seq over nodes \
      #text(fill: palette.accent)[Graph-agnostic; many samples; one update per solution; padding for size]
    ],
  )
  #v(6pt)
  - *Common gap*: none exploit that instances recur from the same $DD$
  - *Policy gradient*: needs on-policy samples after every update#footnote[Gu et al. 2016, Q-Prop (ref. [15] of Khalil et al.). Described from Khalil et al., p. 6; not read by the presenter.]
  #callout(title: [What the authors want to improve], kind: "info")[One learned, graph-aware, data-efficient way to build heuristics for recurring graph problems.]
]

#slide(source: src[Eq. (1) p. 3; Eq. (2) pp. 4–5; Eq. (6) p. 6; diagram self-drawn from Sec. 2])[Prerequisite Methods: Core Formulas][
  #align(center, scale(75%, reflow: true, greedy-loop()))
  #set text(size: 16pt)
  *A. Greedy meta-algorithm* (Eq. 1): #h(4pt) $v^* := op("argmax")_(v in overline(S)) Q(h(S), v)$ #h(4pt) #note[always feasible, but $Q$ is hand-crafted]
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 14pt,
    card([B. structure2vec#footnote[Dai, Dai & Song, ICML 2016 (ref. [9] of Khalil et al.). Described from Khalil et al., pp. 4–5; not read by the presenter.]: node embedding])[
      $ mu_v^((t+1)) <- F(x_v, {mu_u^((t))}_(u in N(v)), {w(v, u)}_(u in N(v)); Theta) $
      *Role*: size-independent features of the $T$-hop neighborhood \
      *Difficulty*: trained with labels (softmax + cross-entropy)
    ],
    card([C. 1-step Q-learning])[
      $ (y - hat(Q)(h(S_t), v_t; Theta))^2 $
      $ y = max_(v') hat(Q)(h(S_(t+1)), v'; Theta) + r(S_t, v_t) $
      *Role*: learns values from rewards, no labels \
      *Difficulty*: objective revealed late $->$ myopic
    ],
  )
  #v(4pt)
  *S2V-DQN keeps* A and the loss of C; *replaces* $Q$ with B; *trains* B by RL; *adds* n-step targets + replay
]

#section[Method]

#slide(source: src[Figure 1, p. 2 (cropped); Eq. (3) p. 4; Eq. (4) p. 5; notation unchanged])[Main Method (1): $hat(Q)$ from Graph Embedding][
  #figure(
    image("assets/fig-1.png", width: 58%),
    caption: [Two greedy iterations on MVC: embed graph + partial solution (yellow), score nodes (green), add the best (Figure 1)],
  )
  #set text(size: 17pt)
  #grid(
    columns: (1.15fr, 1fr),
    column-gutter: 14pt,
    [
      *Embedding* (B with a concrete $F$), $T = 4$ rounds
      $ mu_v^((t+1)) <- "relu"(theta_1 x_v + theta_2 sum_(u in N(v)) mu_u^((t)) + theta_3 sum_(u in N(v)) "relu"(theta_4 w(v, u))) $
      #note[$x_v = 1$ marks the partial solution; re-embedded after every step]
    ],
    [
      *Score* (replaces hand-crafted $Q$)
      $ hat(Q)(h(S), v; Theta) = theta_5^top "relu"([theta_6 sum_(u in V) mu_u^((T)), theta_7 mu_v^((T))]) $
      #note[pooled embedding: state $h(S)$; $mu_v^((T))$: action $v$]
    ],
  )
]

#slide(source: src[Eq. (5) p. 5; Eq. (6), n-step target and Algorithm 1, p. 6; Algorithm 1 restated; diagram self-drawn])[Main Method (2): n-step Fitted Q-learning][
  #figure(n-step-target(), caption: [n-step target: sum $n$ observed rewards, then bootstrap once with the current $hat(Q)$])
  #set text(size: 16pt)
  #grid(
    columns: (1fr, 1.1fr),
    column-gutter: 14pt,
    [
      *Reward* (Eq. 5) #note[cumulative reward $=$ objective]
      $ r(S, v) = c(h(S'), G) - c(h(S), G), quad S' = (S, v) $
      *Target and loss* (C with $n$ steps)
      $ y = sum_(i=0)^(n-1) r(S_(t+i), v_(t+i)) + max_(v') hat(Q)(h(S_(t+n)), v'; Theta) $
      $ min_Theta (y - hat(Q)(h(S_t), v_t; Theta))^2 $
      #note[fitted Q-iteration: SGD on replay batches, not one sample]
    ],
    block(
      fill: palette.highlight.lighten(85%),
      inset: 10pt,
      radius: 4pt,
      width: 100%,
      {
        [*Algorithm 1* (one episode per graph)]
        set par(leading: 0.5em)
        set enum(numbering: "1:", spacing: 0.55em)
        enum(
          [Init replay memory $M$; *for* episode: $G tilde DD$, $S_1 = ()$],
          [#h(1em)*for* $t = 1$ *to* $T$:],
          [#h(2em)$v_t =$ random w.p. $epsilon$, else $op("argmax")_(v in overline(S)_t) hat(Q)(h(S_t), v; Theta)$],
          [#h(2em)$S_(t+1) := (S_t, v_t)$],
          [#h(2em)*if* $t >= n$: add $(S_(t-n), v_(t-n), R_(t-n,t), S_t)$ to $M$],
          [#h(3em)sample $B tilde M$; SGD on $(y - hat(Q))^2$ over $B$],
        )
      },
    ),
  )
]

#section[Evidence]

#slide(source: src[Figure 2 (cropped) and Sec. 5.1, pp. 7–8; Sec. 5 Instance generation, PN-AC, Baselines, Validation and Testing, pp. 6–7])[Evidence: Approximation Ratio on Synthetic Graphs][
  #figure(
    image("assets/fig-2.png", width: 82%),
    caption: [Approximation ratio on 1000 test graphs; train and test from the same distribution (Figure 2)],
  )
  #set text(size: 15pt)
  #show list: set block(above: 0.4em, below: 0.4em)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 16pt,
    card([Setup. Claim: beats heuristics and PN-AC])[
      *Data*: BA graphs (MVC, MAXCUT); random points (TSP) \
      *Compared*: PN-AC (rank-8 SVD input); heuristics \
      *Same*: test graphs; OPT $=$ 1-hour CPLEX / Concorde \
      *Not stated*: training size, PN-AC budget, error bars
    ],
    card([Reading. y: $max(c\/"OPT", "OPT"\/c)$, lower is better], color: palette.accent)[
      *x*: nodes in train / test graphs (same range) \
      MVC $approx 1$; MAXCUT lowest (MaxcutApprox close) \
      TSP: on par with Farthest, 2-opt \
      *Supports*: near-optimal on the training distribution \
      *Cannot infer*: S2V or Q-learning? (both differ from PN-AC)
    ],
  )
]

#section[Summary]

#slide(source: [Assignment note: generative AI (Claude) was used to organize slides, draw diagrams and typeset formulas; all statements were checked against the paper.])[Summary, Open Question & Next Steps][
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 12pt,
    mini("1", [Feasibility])[Greedy + helper $h$; only $hat(Q)$ is learned],
    mini("2", [Objective as return])[Reward $=$ change in cost; return $=$ objective],
    mini("3", [Data efficiency])[n-step targets + replay; update every step],
  )
  #v(6pt)
  #callout(title: [Open question: sign of the reward for minimization], kind: "warn")[
    Eq. (5) with MVC cost $c = |S|$ gives $r = +1$, yet Table 1 lists $r = -1$. \
    Is $r = -(c(h(S')) - c(h(S)))$ intended for MVC / TSP? Not stated (pp. 3, 5–6).
  ]
  - *Directions for the 40-minute in-depth study*
    - n-step fitted Q-iteration vs. 1-step: what $n$ trades off#footnote[Riedmiller 2005; Mnih et al. 2013 (refs. [33], [28] of Khalil et al., p. 6). Not read yet; planned for the in-depth study.]
    - Ablation idea: S2V + policy gradient vs. S2V + Q-learning
]

#appendix()

#slide(source: src[Table 2 and Sec. 5.2, p. 8; table re-typeset, values unchanged])[Appendix A: Generalization to Larger Graphs][
  #set figure(supplement: "Table")
  #figure(
    kind: table,
    table(
      columns: (auto,) + (1fr,) * 7,
      align: (left + horizon,) + (center + horizon,) * 7,
      [*Test size*], [50–100], [100–200], [200–300], [300–400], [400–500], [500–600], [1000–1200],
      [MVC (BA)], [1.0033], [1.0041], [1.0045], [1.0040], [1.0045], [1.0048], [1.0062],
      [MAXCUT (BA)], [1.0150], [1.0181], [1.0202], [1.0188], [1.0123], [1.0177], [1.0038],
      [TSP (clustered)], [1.0730], [1.0895], [1.0869], [1.0918], [1.0944], [1.0975], [1.1065],
    ),
    caption: [Average approximation ratio over 1000 test graphs; trained on 50–100 nodes only (Table 2)],
  )
  - Same $Theta$ for every size: embedding and $hat(Q)$ do not depend on $|V|$
  - MVC / MAXCUT stay within 2.1% up to 1200 nodes; TSP grows to 1.1065
  - "OPT" is 1-hour CPLEX, weaker on large graphs \
    #note[the paper attributes lower ratios on larger graphs (e.g. MAXCUT 1000–1200) to this]
]

#slide(source: src[Figure 3 (cropped) and Sec. 5.3, pp. 8–9])[Appendix B: Running Time vs. Solution Quality][
  #figure(
    image("assets/fig-3.png", width: 62%),
    caption: [Each dot: one solution on one of 100 BA graphs with 200–300 nodes; CPLEX-$k$: its $k$-th improving solution (Figure 3)],
  )
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 16pt,
    [
      - Complexity $O(k |E|)$, $k <=$ number of greedy steps
      - MVC, 1200 nodes: 11 s on one GPU, ratio 1.0062
    ],
    [
      - Slower than approximation algorithms, much better ratio
      - Ratio below 1 at times: beats 1-hour CPLEX
      - GPU vs. CPU: not a fair speed comparison #note[(p. 9)]
    ],
  )
]

#slide(source: src[Table 3 and Sec. 5.4, p. 9; table re-typeset, values unchanged])[Appendix C: Real-world Data][
  #set figure(supplement: "Table")
  #figure(
    kind: table,
    table(
      columns: (auto, auto, 1fr, 1.6fr, 1.6fr),
      align: (left + horizon, left + horizon, center + horizon, center + horizon, center + horizon),
      [*Problem*], [*Dataset*], [*S2V-DQN*], [*Best competitor*], [*2nd best competitor*],
      [MVC], [MemeTracker], [*1.0021*], [1.2220 (MVCApprox-Greedy)], [1.4080 (MVCApprox)],
      [MAXCUT], [Physics], [*1.0223*], [1.2825 (MaxcutApprox)], [1.8996 (SDP)],
      [TSP], [TSPLIB], [*1.0475*], [1.0800 (Farthest)], [1.0947 (2-opt)],
    ),
    caption: [Average approximation ratio on public benchmark / real-world instances (Table 3)],
  )
  - Best on all three problems, including TSP
  - Contrast: on synthetic TSP, Farthest and 2-opt were on par (Figure 2)
  - Dataset details: in the paper's Appendix C, not in the proceedings version read
]
