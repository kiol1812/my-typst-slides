#import "@local/theme-academic:0.2.1": *
#import "@preview/cetz:0.5.2"
#import "assets/mvc-instance.typ": mvc-instance
#import "assets/greedy-loop.typ": greedy-loop
#import "assets/n-step-target.typ": n-step-target

#let title-text = "Learning Combinatorial Optimization Algorithms over Graphs"

#show: deck.with(footer: [S2V-DQN (Khalil et al., NIPS 2017)], text-size: 21pt)

#let palette = default-palette + (:)

#set figure(supplement: "Figure", numbering: none)
#show figure: set block(below: 1em)
#show table: set text(size: 16pt)
#show footnote.entry: set text(size: 13pt, fill: palette.muted)
#set footnote.entry(clearance: 8pt, gap: 4pt)
#set block(spacing: 1em)
#show list: set block(above: 0.8em, below: 0.8em)
#show math.equation.where(block: true): set block(above: 0.7em, below: 0.7em)

#let note(body) = text(size: 15pt, fill: palette.muted, body)
#let dim(body) = text(fill: palette.primary, body)
#let src(body) = [Source: Khalil et al. (NIPS 2017), #body]
#let eq(n, e) = math.equation(block: true, numbering: (..) => [(#n)], e.body)
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
  authors: [Hanjun Dai#super[†\*], Elias B. Khalil#super[†\*], Yuyu Zhang#super[†], Bistra Dilkina#super[†], Le Song#super[†§]],
  affiliations: [#super[†]Georgia Institute of Technology #h(1em) #super[§]Ant Financial #h(1em) #super[\*]Equal contribution],
  venue: [NIPS 2017 (Advances in Neural Information Processing Systems 30)],
  year: [],
  presenters: ([11557028 楊育哲]),
  date: [2026/11/18],
)

#section[Problem]

#slide(source: src[Sec. 1, p. 2; Sec. 2, p. 3 (MVC; $h$, $c$, $t$); Sec. 5.1, p. 7 ($R(S, G)$); MVC example self-drawn])[Research Problem & Optimization Problem][
  #equal-row(
    columns: (auto, 1fr),
    h => block(height: h, align(horizon, mvc-instance())),
    h => card([Approximation ratio], height: h)[
      $ R(S, G) = max(("OPT"(G)) / (c(h(S))), (c(h(S))) / ("OPT"(G))) $
      MVC: $R = |S| \/ "OPT"(G)$ \
      #note[$R >= 1$, lower is better; OPT: solver's best within 1 h]
    ],
  )
  - The paper solves *MVC*, MAXCUT and TSP; this talk focuses on *Minimum Vertex Cover (MVC)*
  #equal-row(
    columns: (1fr, 1fr),
    h => card([MVC on a graph $G(V, E, w) tilde DD$], height: h)[
      *Adjustable*: node subset $S subset.eq V$ \
      #note[built as an ordered list $S = (v_1, v_2, ...)$] \
      *Objective*: $min |S|$ \
      *Constraint*: every edge is covered \
      #note[$forall (u, v) in E: u in S "or" v in S$]
    ],
    h => card([Given by the problem (not learned)], height: h)[
      *Helper function* $h(S)$: $S$ #sym.arrow.r feasible structure \
      #note[MVC: does nothing, $h(S) = S$] \
      *Cost function* $c(h(S), G)$: quality of $S$ \
      #note[MVC: $c(h(S), G) = |S|$] \
      *Termination criterion* $t(h(S))$: stop adding? \
      #note[MVC: true once all edges are covered]
    ],
  )
]

#section[Background]

#slide(source: src[Sec. 1, pp. 1–2 (problem statement)])[Existing Approaches & Difficulties][
  #{
    show table: set text(size: 17pt)
    table(
      columns: (auto, auto, auto, 1fr),
      align: left + horizon,
      inset: (x: 8pt, y: 6pt),
      fill: (_, y) => if y == 0 { palette.primary },
      [*Approach*], [*How it works*], [*Strength*], [*Difficulty*],
      [Exact], [Branch-and-bound, integer programming], [Optimal solution], text(fill: palette.accent)[Too slow for large instances],
      [Approximation], [Polynomial-time algorithms], [Provable ratio], text(fill: palette.accent)[Weak or no guarantees],
      [Heuristics], [Hand-designed rules], [Fast in practice], text(fill: palette.accent)[Problem-specific trial-and-error],
      [Deep learning], [Pointer Networks#footnote[Vinyals et al., 2015; Bello et al., 2016]: seq2seq over nodes], [Learned from data], text(fill: palette.accent)[Graph-agnostic; many samples; one update per solution; padding for size],
    )
  }
  #v(4pt)
  - *Common gap*: none exploit that instances recur from the same $DD$
  - *Policy gradient*: needs on-policy samples after every update#footnote[Gu et al., 2016]
  #callout(title: [Problem Statement], kind: "info")[Given a graph optimization problem G and a distribution D of problem  instances, can we learn better heuristics that generalize to unseen instances from D?]
]

#slide(source: src[Eq. (1) p. 3; Eq. (2) pp. 4–5; Eq. (6) p. 6; diagram self-drawn from Sec. 2])[Prerequisite Methods: Core Formulas][
  #set text(size: 16pt)
  #equal-row(
    columns: (1fr, auto),
    h => card([A. Greedy meta-algorithm], height: h)[
      #eq(1, $ S := (S, v^*), quad v^* := op("argmax")_(v in overline(S)) Q(h(S), v) $)
      *Role*: always feasible, one node per step \
      *Difficulty*: $Q$ is hand-crafted
    ],
    h => block(height: h, align(horizon, greedy-loop())),
  )
  #equal-row(
    columns: (1fr, 1fr),
    h => card([B. structure2vec#footnote[Dai et al., 2016]: node embedding], height: h)[
      #eq(2, $ mu_v^((t+1)) <- F(x_v, {mu_u^((t))}_(u in N(v)), {w(v, u)}_(u in N(v)); Theta) $)
      *Role*: size-independent features of the $T$-hop neighborhood \
      *Difficulty*: trained with labels (softmax + cross-entropy)
    ],
    h => card([C. 1-step Q-learning], height: h)[
      #eq(6, $ (y - hat(Q)(h(S_t), v_t; Theta))^2 $)
      $ y = max_(v') hat(Q)(h(S_(t+1)), v'; Theta) + r(S_t, v_t) $
      *Role*: learns values from rewards, no labels \
      *Difficulty*: objective revealed late $->$ myopic
    ],
  )
  *S2V-DQN keeps* A and the loss of C; *replaces* $Q$ with B; *trains* B by RL; *adds* n-step targets + replay
]

#section[Method]

#slide(source: src[Figure 1, p. 2 (cropped); Eq. (3) p. 4; Eq. (4) p. 5])[Main Method (1): $hat(Q)$ from Graph Embedding][
  #figure(
    image("assets/fig-1.png", width: 54%),
    caption: [Two greedy iterations on MVC: embed graph + partial solution (yellow), score nodes (green), add the best (Figure 1)],
  )
  #set text(size: 17pt)
  *Embedding*, $T = 4$ rounds #h(1fr) #note[$x_v = 1$ marks the partial solution; re-embedded after every step]
  #eq(3, $ underbrace(mu_v^((t+1)), #dim($p times 1$)) <- "relu"\(underbrace(theta_1, #dim($p times 1$)) underbrace(x_v, #dim($1$)) + underbrace(theta_2, #dim($p times p$)) underbrace(scripts(sum)_(u in N(v)) mu_u^((t)), #dim($p times 1$)) + underbrace(theta_3, #dim($p times p$)) underbrace(scripts(sum)_(u in N(v)) "relu"\(underbrace(theta_4, #dim($p times 1$)) underbrace(w(v, u), #dim($1$))\), #dim($p times 1$))\) $)
  *Score* (replaces hand-crafted $Q$) #h(1fr) #note[pooled embedding: state $h(S)$; $mu_v^((T))$: action $v$]
  #eq(4, $ underbrace(hat(Q)(h(S), v; Theta), #dim($1 times 1$)) = underbrace(theta_5^top, #dim($1 times 2p$)) "relu"\(\[underbrace(theta_6, #dim($p times p$)) underbrace(scripts(sum)_(u in V) mu_u^((T)), #dim($p times 1$)), underbrace(theta_7, #dim($p times p$)) underbrace(mu_v^((T)), #dim($p times 1$))\]\) $)
]

#slide(source: src[Eq. (5) p. 5; Eq. (6), n-step target and Algorithm 1, p. 6; diagram self-drawn])[Main Method (2): n-step Fitted Q-learning][
  #set text(size: 16pt)
  #equal-row(
    columns: (1fr, 1fr),
    _ => [
      #layout(size => {
        let fig = n-step-target()
        scale(size.width / measure(fig).width * 100%, reflow: true, fig)
      })
      #note[sum $n$ observed rewards, then bootstrap once with the current $hat(Q)$]
      #v(4pt)
      *Reward* #note[cumulative reward $=$ objective]
      #eq(5, $ r(S, v) = c(h(S'), G) - c(h(S), G), quad S' = (S, v) $)
      *n-step target* (C with $n$ steps)
      $ y = sum_(i=0)^(n-1) r(S_(t+i), v_(t+i)) + max_(v') hat(Q)(h(S_(t+n)), v'; Theta) $
      *Loss* #note[SGD on replay batches, not one sample]
      #eq(6, $ (y - hat(Q)(h(S_t), v_t; Theta))^2 $)
    ],
    h => block(
      height: h,
      width: 100%,
      fill: palette.highlight.lighten(85%),
      inset: 10pt,
      radius: 4pt,
      {
        set text(size: 15pt)
        [*Algorithm 1* Q-learning for the Greedy Algorithm]
        v(-2pt)
        line(length: 100%, stroke: 0.8pt + palette.text)
        let lines = (
          (0, [Initialize experience replay memory $M$ to capacity $N$]),
          (0, [*for* episode $e = 1$ *to* $L$ *do*]),
          (1, [Draw graph $G$ from distribution $DD$]),
          (1, [Initialize the state to empty $S_1 = ()$]),
          (1, [*for* step $t = 1$ *to* $T$ *do*]),
          (2, [$v_t = display(cases(
            "random node" v in overline(S)_t\, & "w.p." epsilon,
            op("argmax")_(v in overline(S)_t) hat(Q)(h(S_t), v; Theta)\, & "otherwise",
          ))$]),
          (2, [Add $v_t$ to partial solution: $S_(t+1) := (S_t, v_t)$]),
          (2, [*if* $t >= n$ *then*]),
          (3, [Add tuple $(S_(t-n), v_(t-n), R_(t-n,t), S_t)$ to $M$]),
          (3, [Sample random batch $B tilde M$ (iid.)]),
          (3, [Update $Theta$ by SGD over (6) for $B$]),
          (2, [*end if*]),
          (1, [*end for*]),
          (0, [*end for*]),
          (0, [*return* $Theta$]),
        )
        grid(
          columns: (auto, 1fr),
          column-gutter: 8pt,
          row-gutter: 0.62em,
          align: (right + horizon, left + horizon),
          ..lines.enumerate().map(((i, (d, body))) => (
            text(fill: palette.muted)[#(i + 1):], pad(left: d * 1.2em, body),
          )).flatten(),
        )
      },
    ),
  )
]

#section[Evidence]

#slide(source: src[Figure 2(a), p. 8 (cropped); Sec. 5 Instance generation, PN-AC, Baselines, Validation and Testing, pp. 6–7; Sec. 5.1, p. 8; Table 2 (MVC row, values unchanged) and Sec. 5.2, p. 8])[Evidence: Approximation Ratio on MVC][
  #set text(size: 15pt)
  #equal-row(
    columns: (0.62fr, 1fr),
    _ => figure(
      image("assets/fig-2a.png", width: 100%),
      caption: [Same train / test distribution (Figure 2(a))],
    ),
    h => card([Setup. Claim: beats MVC baselines and PN-AC], height: h)[
      *Data*: BA graphs; train / test sizes in the same range \
      *Compared*: PN-AC (rank-8 SVD of adjacency as input); \
      MVCApprox, MVCApprox-Greedy (2-approximations) \
      *Same*: 1000 test graphs; OPT $=$ CPLEX best within 1 h \
      *Not stated*: meaning of error bars \
      *Reading* ($R = |S| \/ "OPT"$, lower is better): \
      S2V-DQN $approx 1$ at every size; others $approx 1.2$–$1.5$ \
      *Supports*: near-optimal MVC
    ],
  )
  #card([Generalization to larger instances: train on 50–100 nodes only, test up to 1200 (Table 2)])[
    #table(
      columns: (auto,) + (1fr,) * 7,
      align: (left + horizon,) + (center + horizon,) * 7,
      inset: (x: 6pt, y: 4pt),
      fill: (_, y) => if y == 0 { palette.primary },
      [*Test size*], [50–100], [100–200], [200–300], [300–400], [400–500], [500–600], [1000–1200],
      [MVC (BA)], [1.0033], [1.0041], [1.0045], [1.0040], [1.0045], [1.0048], [1.0062],
    )
    *Caveat*: 1-hour CPLEX "OPT" gets worse on larger graphs (p. 8), so ratios at larger sizes look optimistic
  ]
]

#section[Summary]

#slide(source: [Assignment note: generative AI (Claude) was used to organize slides, draw diagrams and typeset formulas; all statements were checked against the paper.])[Summary, Open Question & Next Steps][
  #equal-row(
    columns: (1fr, 1fr, 1fr),
    gutter: 12pt,
    ..(
      ("1", [Feasibility], [Add nodes until $t$: all edges covered; only $hat(Q)$ is learned]),
      ("2", [Data efficiency], [n-step targets + replay; update every step]),
      ("3", [Evidence], [$R approx 1$ on BA graphs up to 500 nodes (Figure 2(a))]),
    ).map(((k, name, body)) => h => { set block(height: h); mini(k, name, body) }),
  )
  #v(6pt)
  #callout(title: [Open question: the max in the approximation ratio], kind: "warn")[
    $R(S, G) = max("OPT"\/c, c\/"OPT")$, but OPT is only the best 1-hour CPLEX solution (p. 7). \
    If S2V-DQN finds a smaller cover ($|S| < "OPT"$), then $R = "OPT"\/|S| > 1$: a better solution scores worse. \
    Yet p. 8 says such cases give ratios below 1.
  ]
  - *Directions for the 40-minute in-depth study (MVC, MAXCUT, TSP)*
    - MAXCUT / TSP: how $h$, $c$, $t$ change (cut set, insertion helper); why TSP gains less
]

// #include "appendix.typ"
