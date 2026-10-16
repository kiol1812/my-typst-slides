#import "@local/theme-academic:0.1.0": *
#import "@preview/cetz:0.5.2"

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

#slide[Problem Defination][
  #import "@preview/cetz-plot:0.1.4": plot
  #show table.cell: set text(size: 20pt)
  - Time-series anomaly detection (TSAD)
    #table(
      columns: 2,
      [*Problem*], [*Solution*],
      [The severe data imbalance], [self-perturbation module],
      [Static spatio-temporal correlation modeling], [anomaly-aware graph construction module],
      [The "anomaly reconstruction" problem \ (overlooking anomalies with low reconstruction error, because the overfit towards normal patterns)], [spatio-temporal anomaly detection module]
    )
  #align(center)[
    #cetz.canvas({
      plot.plot(
        size: (20, 5),
        x-tick-step: 2,
        y-tick-step: 2,
        x-label: none,
        y-label: none,
        {
          plot.add(
            domain: (0, 20),
            samples: 500,
            style: (stroke: blue + 1.5pt),
            x => 0.5 * calc.sin(2 * x * 1rad) + 
                 0.3 * calc.cos(5.5 * x * 1rad) + 
                 8 * calc.exp(-4 * calc.pow(x - 12, 2))
          )
          plot.add(
            domain: (0, 20),
            samples: 500,
            style: (stroke: red + 1.5pt),
            x => 0.5 * calc.sin(1.95 * x * 1rad) + 
                 0.3 * calc.cos(5.5 * x * 1rad) + 
                 7 * calc.exp(-6 * calc.pow(x - 12, 2))
          )
        }
      )
    })
  ]
]

#slide[Related Works][
  #two-col(ratio: (1.5fr, 1fr))[
    - Sequence-centric models
      - good at capture long-term dependencies
      - overlooking inter-variable correlations
    - Graph-based models
      - Fixed structures fail when relationships change over time
    - Both of above method
      - Rely on strict assumptions
      - Struggle with large or high-dimensional data
    - Reconstruction-based methods
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
    - *self-perturbed time-series generation* to alleviates data imbalance
    - *graph construction* to models dynamical inter-variable correlations
    - a *spatio-temporal anomaly detection module* to mitigates \ the anomaly reconstruction problems
]

#slide[Self-Perturbed Anomaly-Aware Graph Dynamics][
  #figure(
    image("assets/fig-1.png", width: 80%),
    caption: [An illustration of the proposed SPAGD framework (Source: Jinyu Cai et al. 2025 @cai2025)]
  )
]

#slide[Time-Series Generation via Self-Perturbed][
  Self-perturbation mechanism harnesses the intrinsic imperfections of reconstruction models to generate pseudo-anomalous samples


  The reconstruction model is trained on $cal(D) = {bold(X)_i}^N_(i=1)$ by minimizing:
  $
    cal(L)_"sp" = sum^N_(i=1) || bold(X)_i - "Tran"_d ("Tran"_e (bold(X_i); Theta_e); Theta_d) ||^2_F
  $

  Where Frobenius Norm $||A||^2_F = sum^m_i sum^n_j |a_(i j)|^2 = "Tr"(A^T A)$
]

#slide[Anomaly-Aware Graph Construction, AAGC][
  - dynamically adjust the graph structure based on the reconstruction residuals of the self-perturbed time series
  - ensuring that the influence of potential anomalies on the spatial relationships can be emphasized
]

#slide[Spatio-Temporal Modeling for TSAD][
]

#section-slide[Conclusion]

#slide[Paper Summary][
  - authors introduced SPAGD, a new TSAD framework to address serval inherent challenges of Multivariate time-series anomaly detection
  - self-perturbation module: mitigating the class imbalance as well as providing rich auxiliary protential anomalous signals for training
  - anomaly-aware graph construction: dynamically adjust inter-variable correlations for evolving self-perturbed time series
  - anomaly detector: distinguish the normal time series from the self-perturbed ones by modeling noth spatial and temporal dependencies
  - SPAGD presumes a relatively homogeneous sensing landscape, which may not be applicable under highly heterogeneous sreams with asynchoronous sensors or weak inter-variable dependencies
]

#slide()[References][
  #set text(lang: "en")
  #bibliography("refs.bib")
]
