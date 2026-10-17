#import "@local/theme-academic:0.1.0": *
#import "@preview/cetz:0.5.2"

#import "assets/static-correlation.typ": static-correlation
#import "assets/anomaly-reconstruction.typ": anomaly-reconstruction
#import "assets/pseudo-boundary.typ": pseudo-boundary
#import "assets/self-perturbation.typ": self-perturbation
#import "assets/aagc.typ": aagc
#import "assets/st-detector.typ": st-detector
#import "assets/main-results.typ": main-results
#import "assets/ablation.typ": ablation

#let title-text = "Self-Perturbed Anomaly-Aware Graph Dynamics for Multivariate Time-Series Anomaly Detection"

#show: deck.with(footer: title-text)

#let palette = default-palette + (:)

#set figure(supplement: "Figure")
#show table: set text(size: 16pt)
#show footnote.entry: set text(size: 16pt)
#show list: set block(above: 0.65em, below: 0.65em)

// ───────── 封面 ─────────
#title-slide(
  title: title-text,
  authors: [Jinyu Cai, Yuan Xie, Glynnis Lim, Yifang Yin, Roger Zimmermann, See-Kiong Ng],
  venue: [NeurIPS],
  year: [2025],
  presenters: ([11557028 楊育哲]),
  date: [2026/10/21],
)

// ───────── Outline ─────────
#outline-slide()

#section-slide[Introduction]

#slide[Problem Definition][
  #show table.cell: set text(size: 20pt)
  - Time-series anomaly detection (TSAD)
    #table(
      columns: 2,
      [*Problem*], [*Solution*],
      [The severe data imbalance], [self-perturbation module],
      [Static spatio-temporal correlation modeling], [anomaly-aware graph construction module],
      [The "anomaly reconstruction" problem \ (overlooking anomalies with low reconstruction error, because the overfit towards normal patterns)], [spatio-temporal anomaly detection module]
    )
  #v(8pt)
  #grid(
    columns: (1fr, 1fr),
    align: center,
    static-correlation(),
    anomaly-reconstruction(),
  )
]

#slide[Related Works][
  #two-col(ratio: (1.7fr, 1fr))[
    - Sequence-centric models
      - good at capturing long-term dependencies
      - overlooking inter-variable correlations
    - Graph-based models
      - Fixed structures fail when relationships change over time
    - Both of above method
      - Rely on strict assumptions
      - Struggle with large or high-dimensional data
    - Reconstruction-based methods
      - Flag samples with large reconstruction errors
      - Overfit $->$ anomalies reconstructed well, missed
  ][
    #timeline(
      items: (
        (
          year: "2021", 
          title: "GDN", 
          desc: "pre-constructs a similarity graph to help predict anomalies"
        ),
        (
          year: "2022", 
          title: "GRELEN", 
          desc: "integrates graph relational learning to improve feature extraction"
        ),
        (
          year: "2022", 
          title: "Anomaly Transformer \n and TranAD", 
          desc: "utilize a Transformer architecture to capture long-term dependencies"
        ),
        (
          year: "2023", 
          title: "TimesNet", 
          desc: "enhances detection accuracy through multi-scale temporal decomposition"
        ),
      )
    )
  ]
]

#section-slide[Methodology]

#slide[Problem Formulation][
  - *Input Data:* Time series $bold(X)$ with $T$ steps and $d$ features
    $
      bold(X) = [bold(x)_1, bold(x)_2, dots, bold(x)_T], quad bold(x)_t in RR^d
    $
  - *Dataset $cal(D)$:* $N$ samples created using a sliding window of length $T$
    $
      cal(D) = {bold(X)_1, bold(X)_2, dots, bold(X)_N}
    $
  - *Objective:* Train a model to predict anomalies for test sequences
    $
      F_Theta: RR^(d times T) -> hat(y), quad hat(y) in {0, 1} quad forall hat(bold(X))_i in cal(D)_("test")
    $
  - *Proposed Framework:* #underline[#strong[S]]elf-#underline[#strong[P]]erturbed #underline[#strong[A]]nomaly-aware #underline[#strong[G]]raph #underline[#strong[D]]ynamics
    - *self-perturbed time-series generation* to alleviate data imbalance
    - *graph construction* to model dynamical inter-variable correlations
    - a *spatio-temporal anomaly detection module* to mitigate \ the anomaly reconstruction problems
]

#slide[Key Idea][
  #grid(
    columns: (auto, 1fr),
    column-gutter: 20pt,
    align: horizon,
    pseudo-boundary(),
    stack(
      dir: ttb,
      spacing: 12pt,
      card([Why it works])[
        #set text(size: 18pt)
        Separating $bold(X)$ from $tilde(bold(X))$ $->$ boundary hugs normal data \
        No pre-training: pseudo-anomalies go *easy $->$ hard*
      ],
      card([Why not random noise?], color: palette.surface)[
        #set text(size: 18pt)
        AE errors are *structured*: inter-sensor relations, subtle temporal changes
      ],
    ),
  )
  #v(10pt)
  #callout(title: [Open questions], kind: "warn")[
    #set text(size: 18pt)
    *Shortcut?* The classifier may learn reconstruction artifacts (e.g., smoothness) \
    *Alignment?* Errors reflect model capacity, not real anomaly types
  ]
]

#slide[Self-Perturbed Anomaly-Aware Graph Dynamics][
  #figure(
    image("assets/fig-1.png", width: 80%),
    caption: [An illustration of the proposed SPAGD framework (Source: Jinyu Cai et al. 2025 @cai2025)]
  )
]

#slide(subtitle: [Problem 1: data imbalance])[Self-Perturbation][
  - Transformer AE on normal data; output $tilde(bold(X))$ labeled as anomaly
  - Deviations shrink during training: *obvious $->$ subtle*
  #align(center, grid(
    columns: 2,
    column-gutter: 24pt,
    align: horizon,
    $display(cal(L)_"sp" = sum^N_(i=1) || bold(X)_i - "Tran"_d ("Tran"_e (bold(X)_i; Theta_e); Theta_d) ||^2_F)$,
    text(size: 16pt, fill: gray-text)[Frobenius norm: \ $||A||^2_F = sum_i sum_j |a_(i j)|^2 = "Tr"(A^T A)$],
  ))
  #align(center, self-perturbation())
]

#slide(subtitle: [Problem 2: static correlations])[Anomaly-Aware Graph Construction][
  #align(center, aagc())
  #set text(size: 22pt)
  - Residual per variable: $r_i = 1/T sum_t |X_(i,t) - tilde(X)_(i,t)|$
  - top-$m%$ $->$ candidates $cal(M)$
  - Boost edges touching $cal(M)$, then keep top-$K$:
  $
    tilde(S)_(i j) = S_(i j) + bb(I)(i in cal(M)) phi(r_i) + bb(I)(j in cal(M)) phi(r_j)
  $
]

#slide(subtitle: [Problem 3: anomaly reconstruction])[Spatio-Temporal Anomaly Detector][
  #align(center, st-detector())
  #v(8pt)
  - *Spatial*: Graph Attention Network (GAT) on $bold(A)$ (normal) and $tilde(bold(A))$ (perturbed)
  - *Temporal*: split $T$ into $C$ chunks $->$ Temporal Convolution Network (TCN)
  - *Classifier*: $hat(p) = cal(P)(cal(Z)_"stack"; Theta_cal(P)), quad hat(p) in [0, 1]^(2N)$
    $
      quad quad cal(L)_"ad" = -1/(2N) sum^(2N)_(i=1) [y_i log(hat(p)_i) + (1-y_i)log(1-hat(p)_i)]
    $
]

#section-slide[Experiments]

#slide[Setup][
  #show table.cell: set text(size: 20pt)
  #align(center, table(
    columns: 4,
    align: (left, left, center, center),
    [*Dataset*], [*Domain*], [*Channels*], [*Anomaly ratio*],
    [SWaT], [Water treatment], [51], [11.98%],
    [SMAP], [Spacecraft telemetry], [25], [13.13%],
    [MSL], [Spacecraft telemetry], [55], [10.72%],
  ))
  - Train on normal data only; 16 baselines
  - AUC, AUPRC, F1 *without* point adjustment
  - Stable for window size 80--100 and $beta approx 10^(-2)$
]

#slide[Main Results][
  #figure(
    main-results(),
    caption: [AUC (Source: Table 2 of @cai2025)],
  )
  - Best AUC on all three datasets
  - Avg. of 9 metrics: *52.11* vs. 46.79 (runner-up, Deep IF)
  - F1 not best on SMAP / MSL
]

#slide[Ablation Study][
  #two-col(ratio: (1.2fr, 1fr))[
    #figure(
      ablation(),
      caption: [Avg. of AUC / AUPRC / F1 (Source: Table 3 of @cai2025)],
    )
  ][
    #v(20pt)
    - Every module helps
    - No joint training: $-11.6$
    - Recon. score: $-11.5$
    - Static graph: $-6.3$ to $-6.8$
  ]
]

#slide[Anomaly Score Visualization][
  #figure(
    image("assets/fig-3.png", width: 100%),
    caption: [Anomaly scores on MSL; red = ground-truth anomaly (Source: @cai2025)],
  )
  #v(8pt)
  - TranAD: low scores *inside* the anomaly $->$ anomaly reconstruction
  - SPAGD: score shift aligns with the ground truth
]

#section-slide[Conclusion]

#slide[Paper Summary][
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 12pt,
    mini("1", [Self-Perturbation])[Pseudo-anomalies from reconstruction errors],
    mini("2", [AAGC])[Residual-guided dynamic graph],
    mini("3", [ST Classifier])[Avoids anomaly reconstruction],
  )
  #v(12pt)
  - Best AUC on SWaT, SMAP, MSL; each module verified by ablation
  #v(8pt)
  #callout(title: [Limitation], kind: "warn")[
    Assumes homogeneous, synchronous sensors with strong inter-variable dependency.
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
