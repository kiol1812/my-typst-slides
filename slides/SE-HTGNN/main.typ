#import "@local/theme-academic:0.2.2": *
#import "@preview/cetz:0.5.2"
#import "assets/forecast-model.typ": forecast-model
#import "assets/htg-paradigms.typ": htg-paradigms

#let title-text = "Simple and Efficient Heterogeneous Temporal Graph Neural Network"

#show: deck.with(footer: [SE-HTGNN (Wang et al., NeurIPS 2025)], table-size: academic-sizes.label)

#show math.equation.where(block: true): set block(above: 0.7em, below: 0.7em)
#let eq(n, e) = math.equation(block: true, numbering: (..) => [(#n)], e.body)

// ───────── 封面 ─────────
#title-slide(
  title: title-text,
  authors: [Yili Wang#super[1,2], Tairan Huang#super[1], Changlong He#super[1], Qiutong Li#super[1], Jianliang Gao#super[1\*]],
  affiliations: [#super[1]Central South University #h(1em) #super[2]The Hong Kong University of Science and Technology (Guangzhou) #h(1em) #super[\*]Corresponding author],
  venue: [NeurIPS 2025 (39th Conference on Neural Information Processing Systems)],
  year: [],
  presenters: ([11557028 楊育哲]),
  date: [2026/11/25],
)

#section[Introduction]

#slide[Problem Definition][
  #figure(
    image("assets/HDGNN.png", width: 76%),
    caption: [(a) Heterogeneous Temporal Graph (HTG): diverse node type and relation; \ (b) general HDGNN framework: representation learning on HTGs (Source: Wang et al. 2025)]
  )
]

#slide[Related Works][
  #{
    table(
      columns: (auto, 1fr, 1fr),
      align: (x, y) => if y==0 { center } else { left },
      [], [Compress-based methods], [Snapshot-based methods],
      [Methods], [HGT+, DHGAS], [DyHATR, HTGNN, CasMLN],
      [Methodology], [compress all snapshot into a single graph], [two stages \ (I) spatial learning on each snapshot; \ (II) temporal modeling (RNN / Transformer)],
      [Limitation], [structural information loss; high GPU memory cost], [temporal module only sees "compressed" spatial outputs; slow training],
      [Both], table.cell(colspan: 2)[attention discontinuity (no historical attention)]
    )
  }
  #align(center, htg-paradigms())
]

#section[Methodology]

#slide[Problem Formulation][
  - Heterogeneous graph $G = (V, E, X, cal(T)_n, cal(T)_r), quad |cal(T)_n|+|cal(T)_r|>=2$ \ #h(1em) #text(fill: palette.muted)[$X$: feature set; $cal(T)_n, cal(T)_r$: node / relation type sets]
  - Heterogeneous temporal graph $cal(G) = ({G^t}^T_(t=1))$ \ #h(1em) #text(fill: palette.muted)[$T$: number of timestamps; $G^t$: snapshot graph at time $t$; ] \ #h(1em) $cal(V) = union^T_(t=1) V^t, cal(E) = union^T_(t=1) E^t, cal(X) = union^T_(t=1) X^t$
  - HTG downstream task $F(G^(t-(gamma-1)), dots, G^t ; theta) -> (hat(Y)^(t+1), dots, hat(Y)^(t+beta))$ \ #h(1em) #text(fill: palette.muted)[$gamma$: time window size; $beta$: prediction steps; $theta$: learnable parameters]
  #v(0.5em)
  #align(center, forecast-model())
]

#slide[SE-HTGNN Overview][
  #figure(
    image("assets/SE-HTGNN.png", width: 95%),
    caption: [SE-HTGNN architecture overview (Source: Wang et al. 2025)]
  )
]

#slide(subtitle: [Problem: uninformed initial attention])[LLM-enhanced Prompt][
  - *Embedding* (eq 9, 10): $H^"LLM" = union^(cal(T)_n)_v H^"LLM"_v$
  - *Initial attention coefficient* (eq 11, 12)
  #two-col(ratio: (1fr, 1.1fr))[
    #eq(9, $ "Prompt"(v) = \ "{Introduction to type " v "; instruction.}" $)
    #eq(10, $ H_v^"LLM" = "LLM"("Prompt"(v)), forall v in cal(T)_n $)
    #eq(11, $ Q_u = W_Q H_u^"LLM", K_v = H_v^"LLM", \ beta_r = Q_u K_v^top $)
    #eq(12, $ e^0_(v,r) = exp(beta_r)/(sum_(r' in cal(R)(v))exp(beta_(r'))) $)
  ][
    #figure(
      image("assets/SE-HTGNN-b.png", width: 100%),
      caption: [LLM-enhanced prompt (Source: Wang et al. 2025)]
    )
  ]
]

#slide(subtitle: [Problem: attention discontinuity, heavy attention])[Dynamic-Attention-based Graph Learning][
  - *Feature projection* (eq 4): type-specific map to a common space
  - *Aggregation* (eq 5): parameter-free GCN, no extra linear layers
  - *Dynamic-attention-based fusion* (eq 6 \~ 8): relation-wise GRU
  #grid(
    columns: (0.6fr, 1fr),
    column-gutter: 16pt,
    [
      #eq(4, $ H_v^t = W_v dot X_v^t + b_v $)
      #eq(5, $ H_(v,r)^t = sigma (A_r^t H^t_(cal(N)^t_r (v))) $)
      #eq(6, $ e^t_(v,r) = "GRU"_r (H^t_(v,r), e^(t-1)_(v,r)) $)
      #eq(7, $ a_v^t = exp(e^(-t)_(v,r))/(sum_(r' in cal(R)(v))exp(e^(-t)_(v,r'))) $)
      #eq(8, $ H_v^t = sum_(r in cal(R)(v)) a^t_r dot H^t_(v,r) $)
    ],
    [
      #figure(
        image("assets/SE-HTGNN-c.png", width: 100%),
        caption: [Dynamic-attention-based graph learning (Source: Wang et al. 2025)]
      )
    ]
  )
]

#slide(subtitle: [Problem: extra temporal module])[Linear Project][
  #align(center, forecast-model(detail: true))
  #set par(leading: 0.5em)
  #show math.equation.where(block: true): set block(above: 0pt, below: 0pt)
  #show math.equation.where(block: true): set align(left)
  #let muted(body) = text(fill: palette.muted, body)
  #grid(
    columns: (auto, 1fr),
    column-gutter: 24pt,
    align: horizon,
    [
      *Link prediction* \
      #muted[$h in union_(k=t+1)^(t+beta) hat(Y)^k$; $Omega^+, Omega^-$: positive / negative pairs]
    ],
    eq(15, $ cal(L) = - #h(-0.45em) limits(sum)_((i,j) in Omega^+) #h(-0.45em) log sigma(h_i^top h_j) - #h(-0.85em) limits(sum)_((u',v') in Omega^-) #h(-0.85em) log sigma(-h_(i')^top h_(j')) $),
  )
  #grid(
    columns: (auto, 1.3fr, auto, 1fr),
    column-gutter: 16pt,
    align: horizon,
    [
      *Node classification* \
      #muted[cross-entropy; \ $hat(y)_i = "softmax"(h_i)$]
    ],
    eq(16, $ cal(L) = -sum_(i in cal(V)) sum_(c=1)^(|cal(T)_n|) y_i [c] log (hat(y)_i [c]) $),
    [
      *Node regression* \
      #muted[MAE; $hat(y)_i = h_i$]
    ],
    eq(17, $ cal(L) = 1 / (|cal(V)_L|) sum_(i in cal(V)_L) |y_i - hat(y)_i| $),
  )
]

#section[Experiments]

#slide[Setup][
  #let m(x) = text(fill: palette.muted)[#x]
  #figure(
    kind: table,
    table(
      columns: (auto, auto, auto, 1fr, 1fr, auto),
      align: (left + horizon, center + horizon, center + horizon, left + horizon, left + horizon, center + horizon),
      [*Dataset*], [*Task* \ (metrics)], [*Snapshots*], [*Nodes*], [*Relations*], [*Split* \ (train / val / test)],
      [OGBN-MAG], [Link prediction \ #m[(AUC, AP)]], [10 (year)], [paper 282,039; field 34,601; \ author 17,764; institution 2,276], [P–P 2,377,564; A–P 2,061,677; \ P–F 289,376; A–I 40,307], [8 / 1 / 1],
      [Aminer], [Link prediction \ #m[(AUC, AP)]], [16 (year)], [author 23,035; paper 18,464; \ venue 22], [A–P 52,545; P–V 18,464], [14 / 1 / 1],
      [YELP], [Node classification \ #m[(Macro-F1, Recall)]], [12 (month)], [user 55,702; business 12,524], [U–B review 87,846; \ U–B tip 35,508], [10 / 1 / 1],
      [COVID-19], [Node regression \ #m[(MAE, RMSE)]], [304 (day)], [county 3,223; state 54], [C–C 22,176; S–C 3,141; \ S–S 269], [244 / 30 / 30–90],
    ),
    caption: [Dataset statistics; relations by node-type initials; split in snapshots (Source: Table 9 of Wang et al. 2025)]
  )
  #figure(
    kind: table,
    table(
      columns: (1fr, 1fr, 1.4fr),
      align: center + horizon,
      [*Homogeneous GNNs*], [*Heterogeneous GNNs*], [*Heterogeneous Dynamic GNNs*],
      [GCN, GAT, TGAT], [RGCN, RGAT, HGT, DiffMG], [DyHATR, HGT+, HTGNN, DHGAS, CasMLN],
    ),
    caption: [Baselines (Source: Section 5.1 of Wang et al. 2025)]
  )
]

#slide[Main Results][
  #figure(
    kind: table,
    table(
      columns: (auto,) + (1fr,) * 8,
      align: (left + horizon,) + (center + horizon,) * 8,
      table.header(
        table.cell(rowspan: 2, align: horizon)[*Method*],
        table.cell(colspan: 2)[*OGBN-MAG*], table.cell(colspan: 2)[*Aminer*],
        table.cell(colspan: 2)[*YELP*], table.cell(colspan: 2)[*COVID-19 (30-day)*],
        [AUC ↑], [AP ↑], [AUC ↑], [AP ↑], [Macro-F1 ↑], [Recall ↑], [MAE ↓], [RMSE ↓],
      ),
      [DyHATR], [89.49 ± 0.65], [86.24 ± 0.91], [86.46 ± 1.28], [86.22 ± 1.14], [38.89 ± 0.64], [40.98 ± 0.98], [668 ± 56], [1322 ± 74],
      [HGT+], [OOM], [OOM], [85.88 ± 0.38], [84.24 ± 0.48], [38.33 ± 0.60], [40.29 ± 0.56], [OOM], [OOM],
      [HTGNN], second[91.21 ± 0.77], [89.18 ± 1.24], [85.92 ± 0.93], [83.74 ± 0.85], [36.65 ± 1.13], [38.76 ± 1.22], [555 ± 34], [1136 ± 65],
      [DHGAS], [OOM], [OOM], [88.13 ± 0.90], [86.92 ± 0.78], [41.99 ± 1.80], [42.29 ± 1.25], second[536 ± 43], second[1112 ± 43],
      [CasMLN], [90.85 ± 0.64], second[89.47 ± 0.57], second[88.53 ± 0.27], second[87.25 ± 0.63], second[42.21 ± 0.51], second[42.57 ± 0.69], [544 ± 18], [1119 ± 12],
      [*SE-HTGNN*], best[93.13 ± 0.56], best[92.71 ± 0.52], best[91.08 ± 0.59], best[90.03 ± 0.48], best[44.24 ± 0.88], best[44.68 ± 0.43], best[497 ± 5], best[1069 ± 11],
      [Improve.], [+2.11%], [+3.62%], [+2.89%], [+3.19%], [+4.81%], [+4.96%], [+7.27%], [+4.56%],
    ),
    caption: [HDGNN baselines only; mean ± std of 5 runs; #text(fill: palette.accent)[*best*], #text(fill: palette.primary)[#underline[second-best]] among all 12 baselines \ (Source: Table 1 of Wang et al. 2025)]
  )
  - Best on all 8 metrics; HGT+ / DHGAS run out of memory on OGBN-MAG
  - 60 / 90-day COVID-19 MAE: 825 / 1001 vs. 901 / 1084 (best baseline)
]

#section[Conclusion]

#slide[Paper Summary][
  #equal-row(
    columns: (1fr, 1fr, 1fr),
    gutter: 12pt,
    ..(
      ("1", [Dynamic Attention], [GRU carries attention across snapshots]),
      ("2", [LLM Prompt], [Node type priors initialize attention]),
      ("3", [Lightweight Design], [Parameter-free aggregation, \ linear project]),
    ).map(((k, name, body)) => h => { set block(height: h); mini(k, name, body) }),
  )
  #v(12pt)
  - Best on 4 datasets; up to ≈10× faster training
  - SE-HTGNN is the first to propose the concept of a dynamic attention mechanism to unify spatial and temporal modeling
  #v(8pt)
  #callout(title: [Limitation], kind: "warn")[
    High, fixed LLM embedding dimension $->$ large projection matrices; \ Future: low-rank / PCA compression.
  ]
]

#slide[My Takeaways & Insights][
  #callout(title: [Takeaway], kind: "info")[Let attention remember its history: simpler, faster, and more accurate.]
  - *Methodology*
    - Intra-type aggregation can be parameter-free; inter-type fusion matters
    - Relation-wise GRU: history guides attention per relation \ #text(fill: palette.muted)[history $->$ no discontinuity; relation-wise $->$ per-relation trends]
  - *Assumption*
    - Same dimension for all node types; some may need more
  - *Why this paper & Overlap with My research*
    - Interest in *graph neural networks* and *representation learning*
    - Curious about *heterogeneous graphs* since a lab meeting
]

// #include "appendix.typ"
