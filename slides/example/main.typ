#import "@local/theme-academic:0.1.0": *

#show: deck.with(footer: [有去的論文研究])

#let palette = default-palette + (:)

// ───────── 封面 ─────────
#title-slide(
  title: [有趣的論文研究],
  authors: [yang et al.],
  venue: [pre-print],
  year: [2025],
  presenters: ([kiol1812]),
  date: [2026/10/03],
)

// ───────── Outline ─────────
#outline-slide()

#slide(outlined: true)[Overview][
  #grid(
    columns: (1fr,) * 3, column-gutter: 8pt,
    stat("1000→50", "圖庫張數 → 精選張數", note: "如從千張挑選 50 張"),
    stat($O(N^2)$, "欲解決的計算瓶頸", note: "大規模多視角 3D 重建"),
    stat("16", "週（期中 Week 8）", note: "Week 1–16"),
  )
  #figure(
  flow(
    (
      ("無序圖庫", "N ≈ 1000 張照片", palette.surface),
      ("CLIP 特徵", "語意向量快取 .npy/.pt", palette.surface),
      ("View Graph", "FAISS 近鄰建圖", palette.surface),
      ("RL Agent + GNN", "序列選出 50 張", palette.surface),
      ("nerfstudio", "3D 重建 → PSNR/SSIM", palette.surface),
    ),
    split: 4,
    zone-a: "前端：2D 輕量過濾（訓練期間僅用 Proxy Reward）",
    zone-b: "後端：3D 黑盒驗證",
  ),
  kind: image,
  caption: [漏斗式架構：2D 前端負責挑選照片，3D 後端僅作為黑盒驗證。],
)
]

#slide(outlined: true)[Positioning][
  #callout(title: "核心學術突破", kind: "info")[
    「用第二組的方法，解第一組的問題」。
  ]
  #v(2pt)
  #versus(
    card("第一組", sub: "Candidate View Selection")[
      離線處理的*集合覆蓋問題 (Set Cover)*。已有一堆冗餘照片，目標是挑出最少數量的照片來包覆整個 3D 物體。
    ],
    card("第二組", sub: "Next-Best-View via Information Gain")[
      引入 *Scan-RL 的馬可夫決策過程 (MDP)*，取代死板的貪婪演算法，讓 Agent 做「尋找最大資訊增益」的連續跳躍決策。
    ],
    card("本專題", sub: "RL on View Graph")[
      靜態圖庫變成虛擬環境 (View Graph)，Agent 在其中逐步跳躍選圖。
    ],
  )
]

#slide(outlined: true)[MDP][
  #grid(
    columns: (1fr, 1fr), gutter: 8pt,
    mini("S", "State")[已選節點建構為 Sub-graph，經 GNN 與 Global Pooling 壓成固定維度向量],
    mini("A", "Action")[從未選圖片中挑下一張（以 Boolean Mask 排除已選，Logits 設為 $-infinity$）],
    mini("R", "Reward")[2D Proxy Reward：特徵空間擴展程度 + IQA 分數，並含多樣性懲罰],
    mini("T", "Termination")[選滿 50 張即結束回合；再交由 nerfstudio 黑盒驗證 PSNR],
  )
]

#slide(outlined: true)[Schedule][
  #figure(
    gantt((
      (label: "Phase 1 環境基建", start: 1, end: 4, color: main-palette.dark-40),
      (label: "Phase 2 期中與環境", start: 7, end: 8, color: main-palette.dark-20),
      (label: "Phase 3 Reward 升級", start: 9, end: 11, color: main-palette.base),
      (label: "Phase 4 GNN 與 RL", start: 12, end: 15, color: main-palette.light-20),
      (label: "Phase 5 展示 Demo", start: 16, end: 16, color: main-palette.light-20),
    )),
    kind: image,
    caption: [16 週開發時程（以週為單位）。],
  )
]

#slide(outlined: true)[Problem Statement & Dataset Specification][
  #two-col(ratio: (1fr, 1fr))[
    - Source: Kaggle MNIST Dataset @mnist
      - #link("https://example.com/t10k-images")[t10k-images-idx3-ubyte]
      - #link("https://example.com/t10k-labels")[t10k-labels-idx1-ubyte]
      - #link("https://example.com/train-images")[train-images-idx3-ubyte]
      - #link("https://example.com/train-labels")[train-labels-idx1-ubyte]
    - Size
      - Train: 60000
      - Test: 10000
  ][
    #align(center)[
    ]
  ]
]

// ───────── 參考資料（由 refs.bib 自動產生，只列出有被引用的）─────────
#slide()[References][
  #bibliography("refs.bib")
]
