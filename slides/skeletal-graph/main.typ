#import "@local/theme-academic:0.2.2": *
#import "assets/skeletal-graph-fig.typ": skeletal-graph-fig
#import "assets/pipeline-topdown.typ": pipeline-topdown

#let title-text = "Skeletal Graphs for Efficient Structure from Motion"

#show: deck.with(footer: [Skeletal Graphs (Snavely et al., CVPR 2008)])

// ───────── 封面 ─────────
#title-slide(
  title: title-text,
  authors: [Noah Snavely#super[1], Steven M. Seitz#super[1], Richard Szeliski#super[2]],
  affiliations: [#super[1]University of Washington #h(1em) #super[2]Microsoft Research],
  venue: [CVPR 2008 (IEEE Conference on Computer Vision and Pattern Recognition)],
  year: [],
  presenters: ([11557028 楊育哲]),
  date: [2026/11/25],
)

// ───────── Problem ─────────
#section[Problem]

#slide[SfM on Internet Photo Collections][
  - *Structure from Motion (SfM)*: thousands of unordered photos → camera poses + sparse 3D points
  - Highly redundant at popular views, sparse elsewhere

  #equal-row(
    columns: (1fr, 1fr),
    h => card([Incremental SfM], height: h)[
      - Bundle adjustment (BA) over all images
      - Trafalgar (8000 images): > 50 days
    ],
    h => card([Video Speedups], height: h)[
      - Sub-sampling, hierarchical decomposition
      - Assume ordered sequences
    ],
  )
  #v(4pt)
  #callout(title: [Goal: Skeletal Set $S$])[
    Small subset that keeps the scene *complete* with *bounded accuracy loss*; cost follows scene complexity, not image count
  ]
]

// ───────── Method ─────────
#section[Method]

#slide[Key Idea: Image Graph + $t$-Spanner][
  #source-figure(
    skeletal-graph-fig(),
    caption: [Ellipses = accumulated uncertainty along a path],
    source: [Redrawn from Figure 1 of Snavely et al. 2008 @snavely2008],
  )
  #v(4pt)
  #equal-row(
    columns: (1fr, 1fr),
    h => card([Image Graph $G_I$], height: h)[
      - Node = image, edge = two-frame reconstruction
      - Weight $w_(I J) = tr(C_(I J))$: positional uncertainty
      - Path length ≈ uncertainty; fewer edges → longer paths
    ],
    h => card([Skeletal Graph $G_S$: max-leaf $t$-spanner], height: h)[
      - $d(P, Q; G_S) <= t dot d(P, Q; G_I)$ for all $P, Q$
      - Interior nodes = skeletal set $S$; leaves added later
      - NP-complete → greedy approximation
    ],
  )
]

#slide[Pipeline: Building the Graphs][
  #grid(
    columns: (auto, 1fr), column-gutter: 48pt, align: horizon,
    pipeline-topdown(steps: (1, 2), cols: 1, k: 1.0),
    stack(
      spacing: 8pt,
      card[Pairwise Reconstruction#super[1]][
        - SIFT (Scale-Invariant Feature Transform) matching between image pairs
        - Each pair: 5-point + RANSAC (Random Sample Consensus) + BA; drop if reprojection error > 0.6 px
        - $C_(I J)$: invert reduced camera Hessian ($I$ fixed); weight $tr(C_(I J))$
      ],
      card(hl[Near-Duplicates#super[2]])[
        - Camera centers almost coincide ($d_c < 0.025 d_p$) + overlap subset
        - Removed (≈ 1/3 of Internet images), added back at the end
      ],
      card[Pair Graph $G_P$][
        - Node = pair; edge if two pairs share ≥ 16 inlier points
        - $A$–$B$, $B$–$C$ overlap but no common points → scale unknown
      ],
    ),
  )
]

#slide[Pipeline: Skeletal Set & Reconstruction][
  #grid(
    columns: (auto, 1fr), column-gutter: 16pt, align: horizon,
    pipeline-topdown(steps: (3, 4, 5, 6), cols: 2, k: 0.95),
    stack(
      spacing: 8pt,
      card[Step 1: Max-Leaf Spanning Tree#super[3]][
        - Prune edges with $"imp"(I, J) = d_f (I, J; G_I) \/ w_(I J) < 4 \/ t$
        - Greedy: grow from node with most neighbors; feasible paths in $G_P$ only
      ],
      card([Step 2: #hl[Enforce Stretch $t$#super[4]]])[
        - Check only neighboring pairs $(I, J)$
        - Add edge if $d_f (I, J; G_S) > t dot d_f (I, J; G_I)$; interior edges first
      ],
      card[Reconstruction#super[5,6]][
        - $S$ = non-leaf nodes of $G_S$: incremental SfM + BA
        - Leaves and duplicates: #hl[pose estimation#super[6]]\; optional final BA
      ],
    ),
  )
]

// ───────── Discussion ─────────
#section[Discussion]

#slide[Pros & Cons][
  #equal-row(
    columns: (1fr, 1fr),
    h => card([Pros], height: h)[
      - 2× to ≈ 40× faster; gain grows with data size
      - Bounded uncertainty via $t$-spanner
      - Keeps topology (loops, thin links)
      - All images registered, not only $S$
    ],
    h => card([Cons], height: h)[
      - Simplified uncertainty: position only, one path
      - Needs focal length from EXIF (Exchangeable Image File Format); pairwise cost up to $O(n^2)$
      - Loses some weakly connected images
      - $t$ hand-tuned; $t > 30$ degrades after BA
    ],
  )
  #v(8pt)
  #note[St. Peter's: median camera error 6–8 cm after BA for $t <= 30$ (≈ 10% of images in $S$).]
]

#slide[Author's View][
  #equal-row(
    columns: (1fr, 1fr),
    h => card([Conclusion], height: h)[
      - Skeletal graph for Internet photo collections
      - Up to an order of magnitude faster or more
      - Little or no loss in accuracy
    ],
    h => card([Future Work], height: h)[
      - Richer uncertainty: orientation, structure, multiple paths
      - Image triples instead of pairs
      - Finer granularity: remove points too
      - City-scale collections
    ],
  )
]

#slide(source: [Our reimplementation: IMC 2021 PhotoTourism validation scenes (74–100 images) and a synthetic scene (105 images)])[My View][
  #equal-row(
    h => card([Strengths], height: h)[
      - Bounded uncertainty, not ad hoc rules
      - No learning needed
      - Keeps thin links between view clusters
    ],
    h => card([Concerns], height: h)[
      - Size set only via $t$, not monotone
      - Two-view reconstruction for every pair
      - Trace weights span up to $10^12$
    ],
  )
  #v(6pt)
  #equal-row(
    h => stat([9%], [selected · synthetic], height: h),
    h => stat([48–67%], [selected · IMC, $t = 16$], height: h),
    h => stat([39–50%], [added edges · no feasible path], height: h),
  )
]

#slide[Relevance to Project][
  #equal-row(
    h => card([Skeletal Graphs], height: h)[
      - Graph: images + two-view covariance
      - Objective: max leaves, stretch $<= t$
      - Size: implicit via $t$
      - Greedy, no learning
    ],
    h => card([Our Project: GNN + RL], height: h)[
      - View Graph with image and pair features
      - Reward: coverage − redundancy − disconnection
      - Size: explicit budget $k$
      - GNN gain + greedy, then S2V-DQN
    ],
  )
  #v(6pt)
  #card([Takeaways for the Project])[
    - Main classical baseline in our comparison; already implemented with a web demo
    - Connectivity matters: diverse-only subsets break apart → disconnection penalty
    - Next: fix edge weights, require $t > 4$, compare $t = 16$ vs. $64$ by COLMAP mAA
  ]
]

#references-slide(bibliography("refs.bib"))
