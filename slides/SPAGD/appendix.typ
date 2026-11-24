#import "@local/theme-academic:0.2.2": slide, appendix, two-col, palette
#import "assets/ablation.typ": ablation

#appendix()

#slide[Ablation Study][
  #two-col(ratio: (1.2fr, 1fr))[
    #figure(
      ablation(),
      caption: [Avg. of AUC / AUPRC / F1 (Source: Table 3 of Jinyu Cai et al. 2025)],
    )
  ][
    #v(20pt)
    - Every module helps
    - No joint training: $-11.6$
    - Recon. score: $-11.5$
    - Static graph: $-6.3$ to $-6.8$
  ]
]

#slide[Parameter Analysis][
  #figure(
    image("assets/fig-2.png", width: 92%),
    caption: [Sensitivity to window size and $beta$ on SWaT (Source: Jinyu Cai et al. 2025)],
  )
  #v(8pt)
  - *Window size*: best at 80--100; too short or too long both hurt
  - *$beta$*: sharp drop at $10^(-4)$; peak at $10^(-2)$, stable beyond
]
