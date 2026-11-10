#import "@local/theme-academic:0.2.1": slide, appendix, default-palette

#let palette = default-palette + (:)
#let note(body) = text(size: 15pt, fill: palette.muted, body)
#let src(body) = [Source: Khalil et al. (NIPS 2017), #body]

#appendix()

#slide(source: src[Table 2 and Sec. 5.2, p. 8; table re-typeset, values unchanged])[Appendix A: Generalization to Larger Graphs][
  #set figure(supplement: "Table")
  #figure(
    kind: table,
    table(
      columns: (auto,) + (1fr,) * 7,
      align: (left + horizon,) + (center + horizon,) * 7,
      [*Test size*], [50–100], [100–200], [200–300], [300–400], [400–500], [500–600], [1000–1200],
      [MVC (BA)], [1.0033], [1.0041], [1.0045], [1.0040], [1.0045], [1.0048], [1.0062],
      [MAXCUT (BA)], [1.0150], [1.0181], [1.0202], [1.0188], [1.0123], [1.0177], [1.0038],
      [TSP (clustered)], [1.0730], [1.0895], [1.0869], [1.0918], [1.0944], [1.0975], [1.1065],
    ),
    caption: [Average approximation ratio over 1000 test graphs; trained on 50–100 nodes only (Table 2)],
  )
  - Same $Theta$ for every size: embedding and $hat(Q)$ do not depend on $|V|$
  - MVC / MAXCUT stay within 2.1% up to 1200 nodes; TSP grows to 1.1065
  - "OPT" is 1-hour CPLEX, weaker on large graphs \
    #note[the paper attributes lower ratios on larger graphs (e.g. MAXCUT 1000–1200) to this]
]

#slide(source: src[Figure 3 (cropped) and Sec. 5.3, pp. 8–9])[Appendix B: Running Time vs. Solution Quality][
  #figure(
    image("assets/fig-3.png", width: 62%),
    caption: [Each dot: one solution on one of 100 BA graphs with 200–300 nodes; CPLEX-$k$: its $k$-th improving solution (Figure 3)],
  )
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 16pt,
    [
      - Complexity $O(k |E|)$, $k <=$ number of greedy steps
      - MVC, 1200 nodes: 11 s on one GPU, ratio 1.0062
    ],
    [
      - Slower than approximation algorithms, much better ratio
      - Ratio below 1 at times: beats 1-hour CPLEX
      - GPU vs. CPU: not a fair speed comparison #note[(p. 9)]
    ],
  )
]

#slide(source: src[Table 3 and Sec. 5.4, p. 9; table re-typeset, values unchanged])[Appendix C: Real-world Data][
  #set figure(supplement: "Table")
  #figure(
    kind: table,
    table(
      columns: (auto, auto, 1fr, 1.6fr, 1.6fr),
      align: (left + horizon, left + horizon, center + horizon, center + horizon, center + horizon),
      [*Problem*], [*Dataset*], [*S2V-DQN*], [*Best competitor*], [*2nd best competitor*],
      [MVC], [MemeTracker], [*1.0021*], [1.2220 (MVCApprox-Greedy)], [1.4080 (MVCApprox)],
      [MAXCUT], [Physics], [*1.0223*], [1.2825 (MaxcutApprox)], [1.8996 (SDP)],
      [TSP], [TSPLIB], [*1.0475*], [1.0800 (Farthest)], [1.0947 (2-opt)],
    ),
    caption: [Average approximation ratio on public benchmark / real-world instances (Table 3)],
  )
  - Best on all three problems, including TSP
  - Contrast: on synthetic TSP, Farthest and 2-opt were on par (Figure 2)
  - Dataset details: in the paper's Appendix C, not in the proceedings version read
]
