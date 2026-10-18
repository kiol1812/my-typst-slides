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
  #show table.cell: set text(size: 20pt)
  #set figure(supplement: "Table")
  #figure(
    kind: table,
    table(
      columns: (auto, auto, auto, 1fr, auto),
      align: (left, center, center, left, center),
      [*Dataset*], [*Task*], [*Snapshots*], [*Node types*], [*Metrics*],
      [OGBN-MAG], [Link prediction], [10 (year)], [paper, author, institution, field], [AUC, AP],
      [Aminer], [Link prediction], [16 (year)], [paper, author, venue], [AUC, AP],
      [YELP], [Node classification], [12 (month)], [user, business], [Macro-F1, Recall],
      [COVID-19], [Node regression], [304 (day)], [state, county], [MAE, RMSE],
    ),
    caption: [Dataset statistics (Source: Table 9 of Wang et al. 2025 @wang2025a)]
  )
  - 12 baselines: homogeneous GNNs, heterogeneous GNNs, HDGNNs
  - Mean ± std over 5 runs; time-ordered train / val / test split
]

#slide[Main Results][
  #set figure(supplement: "Table")
  #let best(x) = text(fill: palette.accent)[*#x*]
  #figure(
    kind: table,
    table(
      columns: (auto,) + (1fr,) * 8,
      align: (left,) + (center,) * 8,
      table.header(
        table.cell(rowspan: 2, align: horizon)[*Method*],
        table.cell(colspan: 2)[*OGBN-MAG*], table.cell(colspan: 2)[*Aminer*],
        table.cell(colspan: 2)[*YELP*], table.cell(colspan: 2)[*COVID-19 (30-day)*],
        [AUC ↑], [AP ↑], [AUC ↑], [AP ↑], [Macro-F1 ↑], [Recall ↑], [MAE ↓], [RMSE ↓],
      ),
      [DyHATR], [89.49], [86.24], [86.46], [86.22], [38.89], [40.98], [668], [1322],
      [HGT+], [OOM], [OOM], [85.88], [84.24], [38.33], [40.29], [OOM], [OOM],
      [HTGNN], [91.21], [89.18], [85.92], [83.74], [36.65], [38.76], [555], [1136],
      [DHGAS], [OOM], [OOM], [88.13], [86.92], [41.99], [42.29], [536], [1112],
      [CasMLN], [90.85], [89.47], [88.53], [87.25], [42.21], [42.57], [544], [1119],
      [*SE-HTGNN*], best[93.13], best[92.71], best[91.08], best[90.03], best[44.24], best[44.68], best[497], best[1069],
      [Improve.], [+2.11%], [+3.62%], [+2.89%], [+3.19%], [+4.81%], [+4.96%], [+7.27%], [+4.56%],
    ),
    caption: [HDGNN baselines only; mean of 5 runs (Source: Table 1 of Wang et al. 2025 @wang2025a)]
  )
  - Best on all 8 metrics; HGT+ / DHGAS run out of memory on OGBN-MAG
  - 60 / 90-day COVID-19 MAE: 825 / 1001 vs. 901 / 1084 (best baseline)
]

#slide[Ablation Study][
  #set figure(supplement: "Table")
  #two-col(ratio: (1.35fr, 1fr))[
    #figure(
      kind: table,
      table(
        columns: (auto, 1fr, 1fr, 1fr, 1fr),
        align: (left, center, center, center, center),
        [*Variant*], [*MAG* \ AUC ↑], [*Aminer* \ AUC ↑], [*YELP* \ F1 ↑], [*COVID* \ MAE ↓],
        [LLM → Random], [90.87], [87.91], [41.05], [542],
        [LLM → Average], [91.18], [89.76], [43.39], [521],
        [LLM → Zero], [91.78], [89.98], [43.31], [524],
        [Att → Projected], [86.83], [85.42], [38.19], [574],
        [Att → Self], [91.65], [88.73], [42.41], [545],
        [Att → Gated], [87.94], [87.42], [38.96], [574],
        [Agg → None], [83.91], [62.47], [35.27], [672],
        [Agg → GCN], [90.57], [88.40], [43.69], [508],
        [Agg → GAT], [91.93], [88.37], [42.11], [605],
        [*SE-HTGNN*], [*93.13*], [*91.08*], [*44.24*], [*497*],
      ),
      caption: [One metric per dataset (Source: Table 3 of Wang et al. 2025 @wang2025a)]
    )
  ][
    #v(20pt)
    - All variants below full model
    - No aggregation: worst \ #h(1em) #text(fill: palette.muted)[Aminer AUC $-28.6$]
    - Proj. / gated attention \ #h(1em) #text(fill: palette.muted)[MAG AUC $-5.2$ to $-6.3$]
    - Random: worst LLM init
  ]
]

#slide[Efficiency][
  #set figure(supplement: "Table")
  #two-col(ratio: (1.4fr, 1fr))[
    #figure(
      kind: table,
      table(
        columns: (auto, 1fr, 1fr, 1fr, 1fr),
        align: (left, center, center, center, center),
        [*Method*], [*MAG*], [*Aminer*], [*YELP*], [*COVID*],
        [HTGNN], [1132], [472], [165], [1403],
        [DHGAS], [OOM], [351], [164], [11,120],
        [CasMLN], [272], [135], [88], [637],
        [*SE-HTGNN*], [*102*], [*84*], [*47*], [*64*],
      ),
      caption: [Training time in GPU seconds, incl. LLM preprocessing (Source: Table 6 of Wang et al. 2025 @wang2025a)]
    )
  ][
    #stat([2.7×], [OGBN-MAG], note: [vs. CasMLN])
    #v(8pt)
    #stat([≈10×], [COVID-19], note: [vs. CasMLN])
  ]
  - Spatial cost $O(T R n e d)$; no $O(T R n d^2)$ term as in HTGNN / CasMLN
  - Converges within 50 epochs
]

#section-slide[Conclusion]

#slide[Paper Summary][
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 12pt,
    mini("1", [Dynamic Attention])[GRU carries attention across snapshots],
    mini("2", [LLM Prompt])[Node type priors initialize attention],
    mini("3", [Lightweight Design])[Parameter-free aggregation, linear project],
  )
  #v(12pt)
  - Best on 4 datasets; up to ≈10× faster training
  #v(8pt)
  #callout(title: [Limitation], kind: "warn")[
    High, fixed LLM embedding dimension $->$ large projection matrices; future: low-rank / PCA compression.
  ]
]

#slide[Why This Paper][
  #callout(title: [TODO], kind: "warn")[To be written by the presenter.]
]

#slide[My Takeaways][
  #callout(title: [TODO], kind: "warn")[To be written by the presenter.]
]

#slide[Overlap with My Research][
  #callout(title: [TODO], kind: "warn")[To be written by the presenter.]
]

#slide()[References][
  #set text(lang: "en")
  #bibliography("refs.bib")
]
