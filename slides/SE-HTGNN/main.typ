#import "@local/theme-academic:0.1.0": *
#import "@preview/cetz:0.5.2"
#import "assets/forecast-model.typ": forecast-model

#let title-text = "Simple and Efficient Heterogeneous Temporal Graph Neural Network"

#show: deck.with(footer: title-text)

#let palette = default-palette + (:)

#set figure(supplement: "Figure")
#show table: set text(size: 16pt)
#show footnote.entry: set text(size: 16pt)
#show list: set block(above: 0.65em, below: 0.65em)

// ───────── 封面 ─────────
#title-slide(
  title: title-text,
  authors: [Yili Wang, Tairan Huang, Changlong He, Qiutong Li, Jianliang Gao],
  venue: [NeurIPS],
  year: [2025],
  presenters: ([11557028 楊育哲]),
  date: [2026/10/21],
)

// ───────── Outline ─────────
#outline-slide()

#section-slide[Introduction]

#slide[Problem Definition][
  - Heterogeneous Temporal Graph (HTG)
  - Heterogeneous Dynamic GNN (HDGNN): representation learning on HTGs
  #figure(
    image("assets/HDGNN.png", width: 65%),
    caption: [(a) HTG; (b) general HDGNN framework (Source: Wang et al. 2025 @wang2025a)]
  )
]

#slide[Related Works][
  - *Compress-based methods*
    - *Methods*: HGT+, DHGAS
    - *Methodology*: compress all snapshots into a single graph
    - *Limitation*: structural information loss; high GPU memory cost
  - *Snapshot-based methods*
    - *Methods*: DyHATR, HTGNN, CasMLN
    - *Methodology*: two stages \ #h(1em) (I) spatial learning on each snapshot, \ #h(1em) (II) temporal modeling (RNN / Transformer)
    - *Limitation*: temporal module only sees "compressed" spatial outputs; slow training
  - *Both*: attention discontinuity (no historical attention)
]

#section-slide[Methodology]

#slide[Problem Formulation][
  - Heterogeneous graph $G = (V, E, X, cal(T)_n, cal(T)_r), quad |cal(T)_n|+|cal(T)_r|>=2$ \ #h(1em) #text(fill: palette.muted)[$X$: feature set; $cal(T)_n, cal(T)_r$: node / relation type sets]
  - Heterogeneous temporal graph $cal(G) = ({G^t}^T_(t=1), cal(V), cal(E), cal(X))$ \ #h(1em) #text(fill: palette.muted)[$T$: number of timestamps; $G^t$: snapshot graph at time $t$; \ #h(1em) $cal(V) = union^T_(t=1) V^t, cal(E) = union^T_(t=1) E^t, cal(X) = union^T_(t=1) X^t$]
  - HTG downstream task $F(G^(t-(gamma-1)), dots, G^t ; theta) -> (hat(Y)^(t+1), dots, hat(Y)^(t+beta))$ \ #h(1em) #text(fill: palette.muted)[$gamma$: time window size; $beta$: prediction steps; $theta$: learnable parameters]
  #v(0.5em)
  #align(center, forecast-model())
]

#slide[SE-HTGNN Overview][
  #figure(
    image("assets/SE-HTGNN.png", width: 97%),
    caption: [SE-HTGNN architecture overview (Source: Wang et al. 2025 @wang2025a)]
  )
]

#slide(subtitle: [Problem: uninformed initial attention])[LLM-enhanced Prompt][
  - Node type embedding $H_v^"LLM" = "LLM"("Prompt"(v)), quad forall v in cal(T)_n$ \ #h(1em) #text(fill: palette.muted)[type description + instruction; frozen LLaMA3-8B]
  #two-col(ratio: (1fr, 1.25fr))[
    - Initial attention $e^0$
    $ e^0_(v,r) = "softmax"_(r in R(v)) (Q_u K_v^top) $
    #text(fill: palette.muted)[
      $Q_u = W_Q H_u^"LLM", K_v = W_K H_v^"LLM"$ \
      $u, v$: source / target types of $r$ \
      $e^0$: initial GRU hidden state
    ]
  ][
    #figure(
      image("assets/SE-HTGNN-b.png", width: 100%),
      caption: [LLM-enhanced prompt (Source: Wang et al. 2025 @wang2025a)]
    )
  ]
]

#slide(subtitle: [Problem: attention discontinuity, heavy attention])[Dynamic-Attention-based Graph Learning][
  - *Feature projection*: type-specific map to a common space
  - *Aggregation*: parameter-free GCN, no extra linear layers
  - *Fusion*: relation-wise GRU, $e^t_(v,r) = "GRU"_r (H^t_(v,r), e^(t-1)_(v,r))$
  #figure(
    image("assets/SE-HTGNN-c.png", width: 64%),
    caption: [Dynamic-attention-based graph learning (Source: Wang et al. 2025 @wang2025a)]
  )
]

#slide(subtitle: [Problem: extra temporal module])[Linear Project][
  #align(center, forecast-model(detail: true))
  #v(4pt)
  #set text(size: 18pt)
  #set par(leading: 0.5em)
  #grid(
    columns: (1.55fr, 1fr, 0.8fr),
    column-gutter: 16pt,
    [
      *Link prediction* \
      $cal(L) = -sum_(Omega^+) log sigma(h_i^top h_j) - sum_(Omega^-) log sigma(-h_(i')^top h_(j'))$ \
      #text(fill: palette.muted)[$h$: MLP output; $Omega^+, Omega^-$: positive / negative pairs]
    ],
    [
      *Node classification* \
      $cal(L) = -sum_(i in V) sum_c y_i [c] log hat(y)_i [c]$ \
      #text(fill: palette.muted)[cross-entropy; $hat(y)_i = "softmax"(h_i)$]
    ],
    [
      *Node regression* \
      $cal(L) = 1 / (|V_L|) sum_(i in V_L) |y_i - hat(y)_i|$ \
      #text(fill: palette.muted)[MAE; $hat(y)_i = h_i$]
    ],
  )
]

#section-slide[Experiments]

#slide[Setup][
  #set figure(supplement: "Table")
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
    caption: [Dataset statistics; relations by node-type initials; split in snapshots (Source: Table 9 of Wang et al. 2025 @wang2025a)]
  )
  #figure(
    kind: table,
    table(
      columns: (1fr, 1fr, 1.4fr),
      align: center + horizon,
      [*Homogeneous GNNs*], [*Heterogeneous GNNs*], [*Heterogeneous Dynamic GNNs*],
      [GCN, GAT, TGAT], [RGCN, RGAT, HGT, DiffMG], [DyHATR, HGT+, HTGNN, DHGAS, CasMLN],
    ),
    caption: [Baselines (Source: Section 5.1 of Wang et al. 2025 @wang2025a)]
  )
]

#slide[Main Results][
  #set figure(supplement: "Table")
  #let best(x) = text(fill: palette.accent)[*#x*]
  #let second(x) = text(fill: palette.primary)[#underline[#x]]
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
    caption: [HDGNN baselines only; mean ± std of 5 runs; #text(fill: palette.accent)[*best*], #text(fill: palette.primary)[#underline[second-best]] among all 12 baselines \ (Source: Table 1 of Wang et al. 2025 @wang2025a)]
  )
  - Best on all 8 metrics; HGT+ / DHGAS run out of memory on OGBN-MAG
  - 60 / 90-day COVID-19 MAE: 825 / 1001 vs. 901 / 1084 (best baseline)
]

#slide[Ablation Study][
  #set figure(supplement: "Table")
  #two-col(ratio: (1.7fr, 1fr))[
    #figure(
      kind: table,
      table(
        columns: (auto, 1fr, 1fr, 1fr, 1fr),
        align: (left + horizon,) + (center + horizon,) * 4,
        [*Variant*], [*MAG* \ AUC ↑], [*Aminer* \ AUC ↑], [*YELP* \ F1 ↑], [*COVID* \ MAE ↓],
        [LLM → Random], [90.87 ± 1.24], [87.91 ± 1.54], [41.05 ± 0.93], [542 ± 28],
        [LLM → Average], [91.18 ± 0.81], [89.76 ± 0.34], [43.39 ± 0.62], [521 ± 22],
        [LLM → Zero], [91.78 ± 0.68], [89.98 ± 0.62], [43.31 ± 0.79], [524 ± 9],
        [Att → Projected], [86.83 ± 1.21], [85.42 ± 0.98], [38.19 ± 1.56], [574 ± 52],
        [Att → Self], [91.65 ± 1.22], [88.73 ± 0.82], [42.41 ± 1.32], [545 ± 33],
        [Att → Gated], [87.94 ± 2.42], [87.42 ± 1.24], [38.96 ± 3.27], [574 ± 45],
        [Agg → None], [83.91 ± 1.20], [62.47 ± 1.23], [35.27 ± 2.79], [672 ± 78],
        [Agg → GCN], [90.57 ± 0.86], [88.40 ± 2.64], [43.69 ± 0.79], [508 ± 10],
        [Agg → GAT], [91.93 ± 0.46], [88.37 ± 0.28], [42.11 ± 1.32], [605 ± 88],
        [*SE-HTGNN*], [*93.13 ± 0.56*], [*91.08 ± 0.59*], [*44.24 ± 0.88*], [*497 ± 5*],
      ),
      caption: [One metric per dataset; mean ± std of 5 runs \ (Source: Table 3 of Wang et al. 2025 @wang2025a)]
    )
  ][
    #v(20pt)
    - All below full model
    - No agg.: worst \ #text(fill: palette.muted)[Aminer AUC $-28.6$]
    - Proj. / gated att. \ #text(fill: palette.muted)[MAG AUC $-5.2$, $-6.3$]
    - Random: worst init
  ]
]

#slide[Efficiency][
  #set figure(supplement: "Table")
  #show table.cell: set text(size: 14pt)
  #two-col(ratio: (1fr, 1.4fr))[
    #figure(
      kind: table,
      table(
        columns: (auto, 1fr, 1fr, 1fr, 1fr),
        align: (left + horizon,) + (center + horizon,) * 4,
        [*Method*], [*MAG*], [*Aminer*], [*YELP*], [*COVID*],
        [HTGNN], [1132], [472], [165], [1403],
        [DHGAS], [OOM], [351], [164], [11,120],
        [CasMLN], [272], [135], [88], [637],
        [*SE-HTGNN*], [*102*], [*84*], [*47*], [*64*],
      ),
      caption: [GPU seconds incl. LLM preprocessing (Source: Table 6 of Wang et al. 2025 @wang2025a)]
    )
  ][
    #figure(
      kind: table,
      table(
        columns: (auto, 1fr, 1fr, 1fr, 1fr),
        align: (left + horizon,) + (center + horizon,) * 4,
        [*Module*], [*MAG* \ AUC ↑], [*Aminer* \ AUC ↑], [*YELP* \ F1 ↑], [*COVID* \ MAE ↓],
        [LSTM], [92.77 ± 0.48], [90.52 ± 0.48], [*44.31 ± 0.97*], [506 ± 7],
        [Mamba], [91.79 ± 1.32], [87.81 ± 1.65], [41.45 ± 2.41], [601 ± 67],
        [Transformer], [90.75 ± 0.32], [90.93 ± 0.45], [43.59 ± 1.21], [529 ± 12],
        [*GRU (ours)*], [*93.13 ± 0.56*], [*91.08 ± 0.59*], [44.24 ± 0.88], [*497 ± 5*],
      ),
      caption: [Sequence module in dynamic attention; one metric per dataset (Source: Table 4 of Wang et al. 2025 @wang2025a)]
    )
  ]
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 20pt,
    stat([2.7×], [OGBN-MAG vs. CasMLN]),
    stat([≈10×], [COVID-19 vs. CasMLN]),
  )
  - Spatial cost $O("TRned")$; no $O("TRnd"^2)$ term as in HTGNN / CasMLN
  - Converges within 50 epochs
  - GRU ≈ LSTM in accuracy but cheaper; Mamba trains unstably
]

#section-slide[Conclusion]

#slide[Paper Summary][
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 12pt,
    mini("1", [Dynamic Attention])[GRU carries attention across snapshots],
    mini("2", [LLM Prompt])[Node type priors initialize attention],
    mini("3", [Lightweight Design])[Parameter-free aggregation, \ linear project],
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
]

#slide[Why This Paper & Overlap with My Research][
  - Interest in *graph neural networks* and *representation learning*
  - Curious about *heterogeneous graphs* since a lab meeting
]

#slide()[References][
  #set text(lang: "en")
  #bibliography("refs.bib")
]
