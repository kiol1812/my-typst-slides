#import "@local/theme-academic:0.2.2": slide, appendix, two-col, equal-row, stat, palette

#appendix()

#slide[Ablation Study][
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
      caption: [One metric per dataset; mean ± std of 5 runs \ (Source: Table 3 of Wang et al. 2025)]
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
      caption: [GPU seconds incl. LLM preprocessing (Source: Table 6 of Wang et al. 2025)]
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
      caption: [Sequence module in dynamic attention; one metric per dataset (Source: Table 4 of Wang et al. 2025)]
    )
  ]
  #grid(
    columns: (1fr, 1.3fr),
    column-gutter: 20pt,
    align: horizon,
    equal-row(
      columns: (1fr, 1fr),
      gutter: 12pt,
      h => stat([2.7×], [OGBN-MAG vs. CasMLN], height: h),
      h => stat([≈10×], [COVID-19 vs. CasMLN], height: h),
    ),
    [
      - Spatial cost $O("TRned")$; no $O("TRnd"^2)$ term as in HTGNN / CasMLN
      - Converges within 50 epochs
      - GRU ≈ LSTM in accuracy but cheaper; Mamba trains unstably
    ],
  )
]
