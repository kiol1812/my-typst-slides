#import "@local/theme-academic:0.2.2": *
#import "@preview/cetz:0.5.2"

#import "assets/static-correlation.typ": static-correlation
#import "assets/anomaly-reconstruction.typ": anomaly-reconstruction
#import "assets/pseudo-boundary.typ": pseudo-boundary
#import "assets/self-perturbation.typ": self-perturbation
#import "assets/aagc.typ": aagc
#import "assets/st-detector.typ": st-detector
#import "assets/main-results.typ": main-results

#let title-text = "Self-Perturbed Anomaly-Aware Graph Dynamics for Multivariate Time-Series Anomaly Detection"

#show: deck.with(footer: [SPAGD (Cai et al., NeurIPS 2025)])

#let eq(n, e) = math.equation(block: true, numbering: (..) => [(#n)], e.body)

// ───────── 封面 ─────────
#title-slide(
  title: title-text,
  authors: [Jinyu Cai#super[1], Yuan Xie#super[2\*], Glynnis Lim#super[1], Yifang Yin#super[3], Roger Zimmermann#super[2], See-Kiong Ng#super[1]],
  affiliations: [#super[1]Institute of Data Science, NUS #h(1em) #super[2]School of Computing, NUS #h(1em) #super[3]Institute for Infocomm Research, A\*STAR, Singapore #h(1em) #super[\*]Corresponding author],
  venue: [NeurIPS 2025 (39th Conference on Neural Information Processing Systems)],
  year: [],
  presenters: ([11557028 楊育哲]),
  date: [2026/11/25],
)

#section[Introduction]

#slide[Problem Definition][
  - Time-series anomaly detection (TSAD)
    #table(
      columns: 2,
      [*Problem*], [*Solution*],
      [Severe data imbalance], [self-perturbation module],
      [Static spatio-temporal correlation modeling], [anomaly-aware graph construction module],
      [The "anomaly reconstruction" problem \ (anomalies with low reconstruction error are overlooked due to overfitting to normal patterns)], [spatio-temporal anomaly detection module]
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
  #two-col(ratio: (1fr, 1fr))[
    - Sequence-centric models
      - Good at capturing long-term dependencies
      - Overlook inter-variable correlations
    - Graph-based models
      - Fixed structures fail when relationships change over time
    - Traditional methods
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

#section[Methodology]

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
    - *graph construction* to model dynamic inter-variable correlations
    - a *spatio-temporal anomaly detection module* to mitigate \ the anomaly reconstruction problem
]

#slide[Key Idea][
  #grid(
    columns: (1.4fr, 1fr),
    column-gutter: 20pt,
    align: horizon,
    stack(
      dir: ttb,
      spacing: 12pt,
      pseudo-boundary(),
      callout(title: [Open questions], kind: "warn")[
        *Shortcut?* The classifier may learn reconstruction artifacts (e.g., smoothness) \
        *Alignment?* Errors reflect model capacity, not real anomaly types
      ],
    ),
    stack(
      dir: ttb,
      spacing: 12pt,
      card([Why it works])[
        Separating $bold(X)$ from $tilde(bold(X))$ $->$ boundary hugs normal data \
        No pre-training: pseudo-anomalies go *easy $->$ hard*
      ],
      card([Why not random noise?], color: palette.surface)[
        AE errors are *structured*: inter-sensor relations, subtle temporal changes
      ],
    ),
  )
]

#slide[Self-Perturbed Anomaly-Aware Graph Dynamics][
  #figure(
    image("assets/fig-1.png", width: 80%),
    caption: [An illustration of the proposed SPAGD framework (Source: Jinyu Cai et al. 2025)]
  )
]

#slide(subtitle: [Problem 1: data imbalance])[Self-Perturbation][
  - *Reconstruction* (eq 1): Transformer AE on normal data; output $tilde(bold(X))$ labeled as anomaly
  - *Objective* (eq 2): deviations shrink during training: *obvious $->$ subtle*
  #grid(
    columns: (1fr, auto),
    column-gutter: 24pt,
    align: horizon,
    [
      #eq(1, $ tilde(bold(X)) = "Tran"_d ("Tran"_e (bold(X); Theta_e); Theta_d) $)
      #eq(2, $ cal(L)_"sp" = sum^N_(i=1) || bold(X)_i - "Tran"_d ("Tran"_e (bold(X)_i; Theta_e); Theta_d) ||^2_F $)
    ],
    note(size: academic-sizes.label)[Frobenius norm: \ $||A||^2_F = sum_i sum_j |a_(i j)|^2 = "Tr"(A^T A)$],
  )
  #align(center, self-perturbation())
]

#slide(subtitle: [Problem 2: static correlations])[Anomaly-Aware Graph Construction][
  #align(center, aagc())
  - *Initial graph*: Sigmoid(cosine similarity), keep top-$K$ neighbors
  - *Dynamic adjustment* (eq 5, 6): top-$m%$ residual $r_i$ $->$ candidates $cal(M)$; \ boost edges touching $cal(M)$, then keep top-$K$
  #grid(
    columns: (1fr, 2.2fr),
    column-gutter: 24pt,
    align: horizon,
    eq(5, $ r_i = 1/T sum^T_(t=1) |X_(i,t) - tilde(X)_(i,t)| $),
    eq(6, $ tilde(S)_(i j) = S_(i j) + bb(I)(i in cal(M)) phi(r_i) + bb(I)(j in cal(M)) phi(r_j), quad phi := "Sigmoid" $),
  )
]

#slide(subtitle: [Problem 3: anomaly reconstruction])[Spatio-Temporal Anomaly Detector][
  #align(center, st-detector())
  - *Spatial*: Graph Attention Network (GAT) on $bold(A)$ (normal) and $tilde(bold(A))$ (perturbed)
  - *Temporal*: $C$ time chunks $->$ Temporal Convolutional Network (TCN)
  - *Classifier* (eq 11 \~ 13): normal $y = 0$, perturbed $y = 1$
  #eq(11, $ hat(p) = cal(P)(cal(Z)_"stack"; Theta_cal(P)) $)
  #eq(12, $ cal(L)_"ad" = -1/(2N) sum^(2N)_(i=1) [y_i log(hat(p)_i) + (1-y_i)log(1-hat(p)_i)] $)
  #eq(13, $ cal(L) = cal(L)_"sp" + beta cal(L)_"ad" $)
]

#section[Experiments]

#slide[Setup][
  #figure(
    kind: table,
    table(
      columns: (1fr, auto, auto, auto, auto, auto),
      align: (left, center, center, center, center, center),
      [*Dataset*], [*Domain*], [*Channels* \ (Dimensions)], [*Train samples* \ (Normal)], [*Test samples* \ (Mixed)], [*Anomaly ratio* \ (in the test split)],
      [Secure Water Treatment (SWaT)], [Water treatment], [51], [496,800], [449,919], [11.98%],
      [Soil Moisture Active Passive (SMAP)], [Spacecraft telemetry], [25], [135,183], [427,617], [13.13%],
      [Mars Science Laboratory (MSL)], [Spacecraft telemetry], [55], [58,317], [73,729], [10.72%],
    ),
    caption: [Statistics of the three time-series datasets (Source: Jinyu Cai et al. 2025)]
  )
  - 16 baselines; AUC, AUPRC#footnote[Area Under the ROC Curve (AUC), Area Under the Precision-Recall Curve (AUPRC)], F1 *without* point adjustment
]

#slide[Main Results][
  #figure(
    main-results(),
    caption: [AUC, AUPRC, and F1 in % (Source: Table 2 of Jinyu Cai et al. 2025)],
  )
]

#slide[Anomaly Score Visualization][
  #figure(
    image("assets/fig-3.png", width: 100%),
    caption: [Anomaly scores on MSL; red = ground-truth anomaly (Source: Jinyu Cai et al. 2025)],
  )
  #v(8pt)
  - TranAD: low scores *inside* the anomaly $->$ anomaly reconstruction
  - SPAGD: score shift aligns with the ground truth
]

#section[Conclusion]

#slide[Paper Summary][
  #equal-row(
    columns: (1fr, 1fr, 1fr),
    gutter: 12pt,
    ..(
      ("1", [Self-Perturbation], [Pseudo-anomalies from reconstruction errors]),
      ("2", [AAGC], [Residual-guided dynamic graph]),
      ("3", [ST Classifier], [Avoids anomaly reconstruction]),
    ).map(((k, name, body)) => h => { set block(height: h); mini(k, name, body) }),
  )
  #v(12pt)
  - Best AUC on SWaT, SMAP, MSL; each module verified by ablation
  #v(8pt)
  #callout(title: [Limitation], kind: "warn")[
    Assumes homogeneous, synchronous sensors with strong inter-variable dependency.
  ]
]

#slide[My Takeaways & Insight][
  #callout(title: [Takeaway], kind: "info")[Self-generated pseudo-anomalies turn TSAD into self-supervised classification, \ easing the scarcity of real anomalies.]
  - *Methodology*:
    - AAGC as *graph structure learning*
  - *Evaluation*: report non-point-adjusted metrics in TSAD
    - Point adjustment marks a whole segment as detected from one hit $->$ inflated scores
  - *Assumption*: homogeneous sensors
    - Synchronized, same sampling rate, strongly correlated
  - *Missing details*: appendix not found
    - Score visualization: score rises before the anomaly onset $->$ window misaligned?
  - *Why this paper & Overlap with My research*
    - Interest in *graph neural networks* and *representation learning*
    - Curious about *dynamic graphs* since a lab meeting
]

// #include "appendix.typ"
