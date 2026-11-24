#import "@local/theme-academic:0.2.2": *
#import "assets/skeletal-graph-fig.typ": skeletal-graph-fig
#import "assets/pipeline-topdown.typ": pipeline-rows, pipeline-mark
#import "assets/pair-graph-fig.typ": pair-graph-fig

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
  - *Structure from Motion (SfM)*: unordered photos → camera poses + sparse 3D points \
    #note[Famous sites have thousands of Internet photos; unstructured SfM does not scale to them]
  - Many redundant popular views, plus rare views that are important for reconstruction

  #equal-row(
    columns: (1fr, 1fr),
    h => card([Incremental SfM], height: h)[
      - Bundle adjustment (BA) jointly optimizes all cameras and points
      - Trafalgar (8000 images): still running after 50 days
    ],
    h => card([Video Speedups], height: h)[
      - Sub-sampling, hierarchical decomposition
      - Assume ordered sequences; Internet photos are unordered
    ],
  )
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
      - Node = image, edge = two-frame reconstruction \
        #note[Two directed edges per overlapping pair]
      - Weight $w_(I J) = tr(C_(I J))$: positional uncertainty \
        #note[$C_(I J)$: 3×3 covariance of $J$'s position with $I$ fixed]
      - Shortest path = upper bound on uncertainty \
        #note[Fewer edges → longer paths → larger bound]
    ],
    h => card([Skeletal Graph $G_S$: max-leaf $t$-spanner], height: h)[
      - $d(P, Q; G_S) <= t dot d(P, Q; G_I)$ for all $P, Q$ \
        #note[$t$ trades speed for uncertainty]
      - Interior nodes = skeletal set $S$; leaves added later \
        #note[More leaves → fewer images to reconstruct]
      - NP-complete → greedy: max-leaf spanning tree + extra edges
    ],
  )
]

#slide[Feasibility: Pair Graph $G_P$][
  #align(center, pair-graph-fig())
  #v(12pt)
  #equal-row(
    h => card([Problem], height: h)[
      - $A$–$B$, $B$–$C$ reconstruct, no shared points → scale unknown → path infeasible \
        #note[So any path $A$ → $B$ → $C$ in $G_I$ is infeasible]
    ],
    h => card([Pair Graph $G_P$], height: h)[
      - Node = pairwise reconstruction
      - Edge if ≥ 16 shared inliers
      - $d_f$ = shortest feasible path, computed in $G_P$
    ],
  )
  #note[Used later: importance pruning ($d_f$) · tree growth (feasible steps only) · stretch check ($d_f$)]
]

#slide[Pipeline: Building the Graphs][
  #pipeline-rows(
    k: 1.3,
    ((1,), h => card([Pairwise Reconstruction], height: h)[
      - SIFT matching between image pairs \
        #note[Scale-Invariant Feature Transform: local features matched across images]
      - Each pair: 5-point + RANSAC + BA \
        #note[Random Sample Consensus; drop if reprojection error > 0.6 px]
      - $C_(I J)$: invert reduced camera Hessian ($I$ fixed) \
        #note[With $I$ fixed, $J$'s position uncertainty becomes the edge weight]
    ]),
    ((2,), h => card([Near-Duplicates #pipeline-mark("duplicate")], height: h)[
      - Camera centers almost coincide + overlap subset \
        #note[Nearly the same view as another image → adds no new geometry]
      - Removed (≈ 1/3 of Internet images), added back at the end \
        #note[Pairs with most matches go first, so early removals skip many pairs]
    ]),
  )
]

#slide[Pipeline: Skeletal Set][
  #pipeline-rows(
    k: 1.3,
    ((3,), h => card([Max-Leaf Spanning Tree], height: h)[
      - Prune low-importance edges #pipeline-mark("pair") \
        #note[Drop an edge if a detour through other images is much more certain]
      - Greedy: grow from node with most neighbors; feasible steps in #pipeline-mark("pair") only \
        #note[Expand the node covering the most new images → many leaves]
    ]),
    ((4,), h => card([Enforce Stretch $t$ #pipeline-mark("added")], height: h)[
      - Check only neighboring pairs $(I, J)$ \
        #note[If every edge stretches by ≤ $t$, every path does too]
      - Add edge if $d_f (I, J; G_S) > t dot d_f (I, J; G_I)$ #pipeline-mark("pair") \
        #note[Prefer edges between already-selected images, so $S$ stays small]
    ]),
  )
]

#slide[Pipeline: Reconstruction][
  #pipeline-rows(
    k: 1.3,
    ((5,), h => card([Reconstruct $S$], height: h)[
      - $S$ = non-leaf nodes of $G_S$: incremental SfM + BA \
        #note[Same incremental SfM as before, on far fewer images]
    ]),
    ((6,), h => card([Pose Estimation + BA], height: h)[
      - Leaves and duplicates: pose estimation #pipeline-mark("registered")\; optional final BA \
        #note[The skeletal reconstruction is a good initialization; final BA restores lost accuracy]
    ]),
  )
]

// ───────── Discussion ─────────
#section[Discussion]

#slide[Pros][
  - Large speedup on big collections \
    #note[2× (St. Peter's) to ≈ 40× (Trafalgar); the gain grows with collection size]
  - Bounded estimated uncertainty \
    #note[Estimated uncertainty between any two cameras grows by at most $t$×]
  - Preserves graph topology \
    #note[Cutting a large loop or thin link (e.g., Pantheon inside–outside) would break the $t$ bound]
  - Registers nearly all images, not only $S$ \
    #note[Leaves and duplicates are added by pose estimation; $S$ only speeds up computation]
  - Plugs into existing incremental SfM \
    #note[Reconstruct $S$ with incremental BA, add the rest by pose estimation, optional final BA]
]

#slide[Cons][
  #grid(
    columns: (1fr, 1.2fr),
    gutter: 24pt,
    [
      - Simplified uncertainty model \
        #note[Camera position only, one shortest path as the bound; $t$ bounds this estimate, not the true 3D error]
      - $t$ must be hand-tuned \
        #note[St. Peter's: 6–8 cm median error after BA for $t <= 30$ (≈ 10% of images in $S$); larger $t$ is too poor an initialization for BA]
      - A few weakly connected images are lost \
        #note[Mistakenly pruned as infeasible while building $G_S$]
    ],
    [
      - Requires calibrated cameras \
        #note[Needs EXIF focal length for the 5-point algorithm; images without it are skipped]
      - Costly preprocessing \
        #note[Two-view reconstruction for every matching pair, up to $O(n^2)$; on dense sets (Pantheon) it exceeds reconstruction time]
      - Works only on the largest connected component of $G_I$ \
        #note[Other components are not reconstructed (Trafalgar: 3892 of 8000 images)]
      - Relies on reliable pairwise reconstructions \
        #note[Wrong focal length or mismatches give bad edges; pairs with reprojection error > 0.6 px are dropped]
    ],
  )
]

#slide(source: [Our reimplementation: IMC 2021 PhotoTourism validation scenes (74–100 images) and a synthetic scene (105 images)])[Author's View & Our View][
  #equal-row(
    columns: (1fr, 1fr),
    h => card([Author], height: h)[
      *Conclusion*
      - Cost should depend on scene complexity, not on the number of images \
        #note[A small skeletal set carries most of the information]
      - Skeletal graph for unordered, redundant Internet photo collections
      - Up to an order of magnitude faster or more \
        #note[Trafalgar: > 50 days → ≈ 30 hours]
      - Little or no loss in accuracy \
        #note[St. Peter's: 6–8 cm median error after BA]
    ],
    h => card([Ours], height: h)[
      *Strengths*
      - Recasts SfM efficiency as a graph problem with an accuracy constraint \
        #note[Accuracy → uncertainty, cost → interior nodes]
      - Selection bounded by the $t$-spanner, not heuristic sampling
      - No learning needed
      - Keeps thin links between view clusters

      *Concerns*
      - $|S|$ depends only on $t$, but not monotonically
      - Two-view reconstruction for every pair
    ],
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
    - Uncertainty as a signal: pair covariance $tr(C_(I J))$ could be an edge feature or reward term
  ]
]

#references-slide(bibliography("refs.bib"))
