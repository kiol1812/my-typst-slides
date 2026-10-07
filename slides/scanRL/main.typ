#import "@local/theme-academic:0.1.0": *
#import "@preview/cetz:0.5.2"

#let title-text = "Next-Best View Policy for 3D Reconstruction"

#show: deck.with(footer: title-text)

#let palette = default-palette + (:)

#set figure(supplement: "Figure")
#show table: set text(size: 16pt)
#show footnote.entry: set text(size: 16pt)
#show list: set block(above: 0.65em, below: 0.65em)

// ───────── 封面 ─────────
#title-slide(
  title: title-text,
  authors: [Peralta, Daryl and Casimiro, Joel and Nilles, Aldrin Michael and Aguilar, Justine Aletta and Atienza, Rowel and Cajote, Rhandley],
  venue: [ECCV],
  year: [2020],
  presenters: ([11557028 楊育哲]),
  date: [2026/10/07],
)

// ───────── Outline ─────────
#outline-slide()

#section-slide[Introduction]

#slide(subtitle: [Planning views for data acquisition])[Problem Definition][
  #two-col(ratio: (1fr, 1fr))[
    - Reducing the views required to cover an object from a set of candidate views
  ][
    - Select the Next-Best View (NBV) in terms of information gain
  ]
  #v(1em)
  #figure(
    two-col(ratio: (1fr, 1fr))[
      #align(center)[
        #cetz.canvas({
          import cetz.draw: *
          
          // 繪製中心目標物件
          circle((0,0), radius: 0.6, fill: luma(230), stroke: black)
          content((0,0), [])
          
          // 繪製 8 個候選視角
          for i in range(8) {
            let angle = i * 45deg
            let r = 2.2
            let x = r * calc.cos(angle)
            let y = r * calc.sin(angle)
            
            // 假設挑選其中 3 個作為保留的視角
            let selected = (i == 0 or i == 3 or i == 5)
            let c = if selected { palette.primary } else { luma(200) }
            let s = if selected { "solid" } else { "dashed" }
            
            // 畫連線 (視線)
            line((x, y), (x*0.3,y*0.3), stroke: (paint: c, dash: s, thickness: if selected { 1.5pt } else { 1pt }), mark: (end: ">", fill: c))
            
            // 畫相機節點
            circle((x,y), radius: 0.2, fill: c, stroke: none)
          }
          
          // 圖例說明
          content((0, -3), text(size: 20pt, fill: palette.primary)[Selected Views])
          content((0, -3.5), text(size: 20pt, fill: luma(150))[Discarded Views])
        })
      ]
    ][
      #align(center)[
        #cetz.canvas({
          import cetz.draw: *
          
          // 繪製中心目標物件 (帶有一點已知/未知的概念)
          circle((0,0), radius: 0.6, fill: luma(230), stroke: black)
          arc((0,0.6), start: 90deg, stop: 270deg, radius: 0.6, mode: "PIE", fill: palette.surface.lighten(20%), stroke: none)
          content((0,0), [])
          
          // 當前視角 (Current View)
          let curr-pos = (-2.2, 0)
          circle(curr-pos, radius: 0.2, fill: palette.surface, stroke: none)
          line(curr-pos, (-0.6, 0), stroke: (paint: palette.surface, thickness: 1.5pt), mark: (end: ">", fill: palette.surface))
          content((-2.2, -0.5), text(size: 20pt, weight: "bold", fill: palette.surface)[Current])
          
          // 下一個候選視角
          let candidates = (
            (pos: (0, 2.2), ig: "Low", color: luma(200)),
            (pos: (2.2, 0), ig: "Max Info", color: palette.primary), // NBV
            (pos: (1.5, -1.8), ig: "Mid:", color: luma(200))
          )
          
          for cand in candidates {
            let p = cand.pos
            let (x, y) = p
            let c = cand.color
            let is-nbv = cand.ig == "Max Info"
            
            // 畫連線
            line(p, (x*0.3,y*0.3), stroke: (paint: c, dash: if is-nbv { "solid" } else { "dashed" }, thickness: if is-nbv { 1.5pt } else { 1pt }), mark: (end: ">", fill: c))
            
            // 畫相機節點
            circle(p, radius: 0.2, fill: c, stroke: none)
            
            // 標示 Information Gain
            content((x+2.5, p.at(1)), text(size: 20pt, fill: c)[IG: #cand.ig])
            
            if is-nbv {
               content((p.at(0) + 3, p.at(1) - 0.6), text(size: 20pt, weight: "bold", fill: c)[NBV])
            }
          }
        })
      ]
    ],
    caption: [*Left*: View selection from a pre-defined set; *Right*: Iterative Next-Best View (NBV) based on information gain.]
  )
]

#slide(subtitle: [Structure from Motion (SfM)])[Motivation][
  - Highly sensitive to the quality of selected viewpoints
  - Adding images fixes reconstruction holes, but drastically increases computational overhead and processing time
  #figure(
    image("./assets/fig1.webp", width: 53%),
    caption: [Comparison between traditional circular path (*left*, 87% coverage) and Scan-RL (*right*, 97% coverage). (Source: Peralta, Daryl et al. 2020 @peralta2020)]
  )
]

#section-slide[Methodology]

#slide(subtitle: [Learning a Next-Best View Policy])[Scan-RL][
  #figure(
    image("./assets/fig2.webp", width: 60%),
    caption: [
      Block diagram of Scan-RL: The policy predicts the Next-Best View from RGB inputs, while the reconstructed 3D model provides training rewards. (Source: Peralta et al., 2020 @peralta2020)
    ]
  )
]

#slide(subtitle: [Markov Decision Process, MDP])[Scan-RL][
  - Cast the NBV selection process as a MDP, which is made of $(S, A, T, R, gamma)$
    - *$S$*: *state*, the monocular images captured by the camera ($s_t = H[I_t, I_(t-1), dots, I_(t-k)]$)
    - *$A$*: *action*, the change in pose that parameterized to $(Delta theta, Delta phi, Delta psi)$
      - $theta$ is the azimuth angle
      - $phi$ is the elevation angle
      - $psi$ is the distance from the object
    - *$T$*: *transition probability*
    - *$R$*: *reward*
      - $r_t = cases(
    k_c * Delta C_s - k_x * Delta X - 2 & C_s <= C_(s,"terminal"),
    100 & C_s > C_(s,"terminal")
  )$, where $C_s = N_("obs")/N_("gt")$
      - $N_("obs")$ produced by 3D reconstruction module, which is depth fusion algorithm based on Truncated Signed Distance Function (TSDF) representation
    - *$gamma$*: *discount factor*
]

#slide(subtitle: [Conception])[Scan-RL][
  #align(center)[
    #figure(
      grid(
        columns: (1fr, 1fr),
        gutter: 0.1em,
        cetz.canvas({
          import cetz.draw: *

          // 繪製 3D 座標軸 (偽 3D 投影)
          line((0,0), (5,0), name: "x", mark: (end: ">", scale: 0.8), stroke: gray)
          line((0,0), (-2.5,-2), name: "y", mark: (end: ">", scale: 0.8), stroke: gray)
          line((0,0), (0,4.5), name: "z", mark: (end: ">", scale: 0.8), stroke: gray)

          // 目標原點 (房屋)
          content((0,0), box(fill: white, stroke: black, inset: 4pt, radius: 2pt)[])

          // 相機座標與地面投影點
          let cam_x = 3
          let cam_y = 3
          let proj_x = 3
          let proj_y = -1.5

          // 連接線 (距離與投影)
          line((0,0), (proj_x, proj_y), stroke: (dash: "dashed", paint: gray))
          line((proj_x, proj_y), (cam_x, cam_y), stroke: (dash: "dashed", paint: gray))
          line((0,0), (cam_x, cam_y), name: "psi_line", mark: (end: ">"), stroke: (thickness: 1.5pt, paint: palette.primary))

          // 方位角 (Azimuth) 的弧線與標籤
          arc((3,0), start: 0deg, stop: -37.5deg, radius: 2.2, name: "arc_theta", mark: (end: ">"), stroke: palette.accent)
          content((6, -0.6), text(fill: palette.accent)[$theta$ (Azimuth)])

          // 仰角 (Elevation) 的弧線與標籤
          arc((2.5,-1.4), start: -25deg, stop: 35deg, radius: 3.5, name: "arc_phi", mark: (end: ">"), stroke: palette.surface)
          content((6, 1), text(fill: palette.surface)[$phi$ (Elevation)])

          // 距離 (Distance) 標籤
          content((6, 2.7), text(fill: palette.primary)[$psi$ (Distance)])

          // 相機圖示
          content((cam_x, cam_y), box(fill: white, stroke: black, inset: 4pt, radius: 2pt)[], anchor: "south-west")
        }),
        
        cetz.canvas(length: 0.55cm, {
          import cetz.draw: *

          // 繪製中心目標物件 (House)
          circle((0,0), radius: 0.6, fill: luma(230), stroke: black)
          
          let c = palette.surface
          let s = "dashed"
          let r = 5.2
          
          // 定義軌跡節點的視角 (模擬繞行掃描的過程)
          let angles = (135deg, 90deg, 45deg, 0deg, -45deg)
          
          // 畫節點間的連線與動作/獎勵敘述
          for i in range(4) {
            let a1 = angles.at(i)
            let a2 = angles.at(i+1)
            let p1 = (r * calc.cos(a1), r * calc.sin(a1))
            let p2 = (r * calc.cos(a2), r * calc.sin(a2))
            
            // 畫連線軌跡
            line(p1, p2, stroke: (paint: c, dash: s, thickness: 1pt), mark: (end: ">", fill: c))
          }
          
          // 畫相機節點與表面覆蓋率 (Cs) 的狀態更新
          for i in range(5) {
            let angle = angles.at(i)
            let p = (r * calc.cos(angle), r * calc.sin(angle))
            
            // 將相機視線指向中心房屋
            line(p, (0.8 * calc.cos(angle), 0.8 * calc.sin(angle)), stroke: (paint: gray, thickness: 0.5pt), mark: (end: ">"))
            circle(p, radius: 0.2, fill: c, stroke: none)
            
            let margin_node = 1.9
            let nx = p.at(0) + margin_node * calc.cos(angle)
            let ny = p.at(1) + margin_node * calc.sin(angle)

            if angle == 0deg { nx = nx + 2.6 }
            
            let node_label = if i == 0 {
              align(center)[Start Episode #linebreak() Initial $C_s$]
            } else if i == 4 {
              align(center)[Terminal $C_s > C_(s,"terminal")$ #linebreak() Episode Ends ($r_T = 100$)]
            } else {
              align(center)[Update coverage $C_s$]
            }
            
            content((nx, ny), text(size: 16pt, node_label))
          }
        })
      ),
      caption: [*Left*: Viewpoint and action space; *Right*: Trajectory of a single training episode]
    )
  ]
]

#slide(subtitle: [Training])[Scan-RL][
  - *Deep Q-Network* (*DQN*) was implemented in the *discrete action space*
    $
      Q^* = limits(max)_pi EE (r_t + gamma r_(t+1) + gamma^2 r_(t+2) + dots | s_t = s, a_t = a, pi)
    $
  - *Deep Deterministic Policy Gradient* (*DDPG*, an actor-critic algorithm) was implemented in the *continuous action space*
    $
      nabla_(theta mu) J approx 1/N sum_j nabla_a Q(s, a|theta_w^Q)|s=s_j , a=mu (s_j) nabla_(theta_w^mu) mu (s|theta_w^mu)|s_j
    $
  #figure(
    flow(
      (
        ($"state "84 times 84 times 6$, "", palette.primary),
        ($"3D reconstruction"$, "", palette.primary),
        ($"compute reward " r_t$, "", palette.primary),
        ($"adjust policy " pi$, "", palette.primary),
      ),
      split: 2,
      zone-a: "preprocess",
      zone-b: "update",
      color-a: main-palette.light-20,
      color-b: main-palette.dark-20,
      height: 60pt
    ),
    kind: image,
    caption: [Simple flow diagram of one training epoch.],
  )
]

#section-slide[Experiments]

#slide(subtitle: [Overview])[Experiments][
  - Three experiments were performed to evaluate Scan-RL
    1. *single house policy experiment*
      - test if an agent can learn an NBV policy to scan a house efficietly using Scan-RL
    2. *multiple houses single policy transfer experiment*
      - test if a single policy can learn to scan multiple houses an be transferred to houses not seen during training
    3. *test on Sranford Bunny* #footnote[Avalable from Stanford University COmputer Graphics Lab]
      - test if Scan-RL can be used for non-house objects and to compare with Isler et al. @7487527
]

#slide(subtitle: [1. Single House Policy Experiment])[Experiments][
  #set figure(supplement: "Table")
  #align(center)[
    #figure(
      table(
        columns: 10,
        align: center + horizon,
        table.cell(rowspan: 2)[Distance \ Levels],
        table.cell(rowspan: 2)[Azimuth \ Resolution],
        table.cell(colspan: 4)[Steps],
        table.cell(colspan: 4)[Distance covered (units)],
        [Circ 1], [Circ 2], [Circ 3], [Scan-RL],
        [Circ 1], [Circ 2], [Circ 3], [Scan-RL],
        [2], [45.0°], [23], [12], [8], [*7*], [1087.30], [662.87], [510.62], [*410.13*],
        [2], [22.5°], [44], [23], [13], [*12*], [1162.93], [702.12], [492.60], [*416.81*],
        [3], [45.0°], [24], [13], [9], [*8*], [1097.54], [687.87], [520.85], [*435.13*],
        [3], [22.5°], [43], [24], [18], [*15*], [1082.13], [727.12], [641.38], [*533.34*]
      ),
      caption: [Single House Policy Experiment in discreate action space. (Source: Peralta, Daryl et al. 2020 @peralta2020)]
    )
    #figure(
      table(
        columns: 9,
        align: center + horizon,
        table.cell(rowspan: 2)[Max Allowed \ Distance (units)],
        table.cell(colspan: 4)[Steps],
        table.cell(colspan: 4)[Distance covered (units)],
        [Circ 1], [Circ 2], [Circ 3], [Scan-RL],
        [Circ 1], [Circ 2], [Circ 3], [Scan-RL],
        [125], [23], [12], [8], [*7*], [1087.30], [662.87], [*510.62*], [520.08],
        [150], [24], [13], [9], [*7*], [1097.54], [687.87], [*520.85*], [550.80]
      ),
      caption: [Single House Policy Experiment in continuous action space. (Source: Peralta, Daryl et al. 2020 @peralta2020)]
    )
  ]
]

#slide(subtitle: [1. Single House Policy Experiment])[Experiments][
  #figure(
    image("./assets/fig8.webp", width: 49%),
    caption: [Scan-RL performance during training for the different action space setups \ (Source: Peralta, Daryl et al. 2020 @peralta2020)]
  )
]

#slide(subtitle: [2. Multiple Houses Single Policy Experiment])[Experiments][
  #set figure(supplement: "Table")
  #show table: set text(size: 14pt)
  #align(center)[
    #figure(
      grid(
        columns: 2,
        gutter: 0.2em,
        table(
          columns: 9,
          align: center + horizon,
          table.cell(rowspan: 3)[Batch],
          table.cell(colspan: 4)[Random Split],
          table.cell(colspan: 4)[Geometry Split],
          table.cell(colspan: 2)[Train Set],
          table.cell(colspan: 2)[Test Set],
          table.cell(colspan: 2)[Train Set],
          table.cell(colspan: 2)[Test Set],
          [Scan-RL], [Circ], [Scan-RL], [Circ], [Scan-RL], [Circ], [Scan-RL], [Circ],
          [1], [217/225], [225/225], [23/25], [24/25], [218/225], [224/225], [25/25], [25/25],
          [2], [224/225], [225/225], [25/25], [25/25], [224/225], [225/225], [24/25], [25/25],
          [3], [182/225], [186/225], [18/25], [22/25], [203/225], [190/225], [16/25], [20/25],
          [4], [204/225], [206/225], [24/25], [24/25], [193/225], [210/225], [17/25], [20/25],
          [5], [222/225], [225/225], [25/25], [25/25], [214/225], [225/225], [25/25], [25/25],
          [6], [213/225], [215/225], [25/25], [25/25], [204/225], [220/225], [20/25], [20/25]
        ),
        table(
          columns: 9,
          align: center + horizon,
          table.cell(rowspan: 3)[Batch],
          table.cell(colspan: 4)[Random Split],
          table.cell(colspan: 4)[Geometry Split],
          table.cell(colspan: 2)[Train Set],
          table.cell(colspan: 2)[Test Set],
          table.cell(colspan: 2)[Train Set],
          table.cell(colspan: 2)[Test Set],
          [Scan-RL], [Circ], [Scan-RL], [Circ], [Scan-RL], [Circ], [Scan-RL], [Circ],
          [7], [76/210], [137/210], [10/20], [13/20], [197/210], [190/210], [17/20], [20/20],
          [8], [183/225], [189/225], [18/25], [21/25], [131/225], [185/225], [16/25], [25/25],
          [9], [155/225], [191/225], [13/25], [19/25], [145/225], [190/225], [11/25], [20/25],
          [10], [194/225], [214/225], [14/25], [20/25], [214/225], [211/225], [20/25], [25/25],
          [11], [191/225], [225/225], [18/25], [25/25], [220/225], [225/225], [25/25], [25/25],
          [12], [195/225], [189/225], [18/25], [18/25], [184/225], [190/225], [19/25], [25/25]
        )
      ),
      caption: [Ratio of solved houses using Scan-RL over the total number of houses used for each Houses3K batch. \ (Adapted from: Peralta, Daryl et al. 2020 @peralta2020)]
    )
  ]
]

#slide(subtitle: [3. Non-House Target Model Experiment])[Experiments][
  #figure(
    image("./assets/fig9.webp", width: 48%),
    caption: [Reconstruction of Stanford Bunny. Surface coverage per step: Scan-RL vs. Isler et al. @7487527 \ (Source: Peralta, Daryl et al. 2020 @peralta2020)]
  )
]

#section-slide[Discussion]

#slide[Pros & Cons][
  - Pros
    - Scanning with an optimal path significantly reduces the number of images required for 3D reconstruction
    - Using only monocular images to optimize scanning paths
  - Cons
    - Training the Reinforcement Learning (RL) agent is highly time-consuming and computationally expensive
    - High rendering overhead when using game engines
    - Relying on grass as an auxiliary signal is a drawback
]

#slide(subtitle: [Paper Summary])[Conclusion][
  - Introduced a learning-based algorithm that trains a Next-Best View (NBV) policy using only monocular images to optimize scanning paths
  - Achieved 96% terminal surface coverage in fewer steps and with a shorter travel distance compared to traditional circular paths
  - Demonstrated that a trained NBV policy successfully generalizes to novel, unseen house models outside the training data
]

#slide(subtitle: [Team Insights])[Conclusion][
  - *Limited Evaluation Scope*: Over-relies on a custom synthetic dataset (Houses3K) without real-world validation.
  - *Weak Baselines*: Compares against only a single method (Isler-Combined) for non-house targets.
  - *Bounded Generalization*: Generalizes only within the "house" domain. Requires complete retraining for novel geometries (lacks zero-shot deployment).
]

#slide(subtitle: [Connection to Final Project])[Conclusion][
  - Our project aims to minimize the number of views required to fully cover an object from a set of candidate views
  - We plan to leverage this paper's *experimental environment* and *codebase*, applying randomized algorithms to reframe candidate view selection as an iterative NBV problem
]

// ───────── 參考資料（由 refs.bib 自動產生，只列出有被引用的）─────────
#slide()[References][
  #set text(lang: "en")
  #bibliography("refs.bib")
]

/*
* TODO:
*   1. Palette
*   2. Appendix
*
Appendix A: Continuous vs. Discrete Action Space (連續與離散之爭)

內容： 簡單說明作者其實有測試 DDPG、PPO 等連續控制算法，但最終選擇 DQN 的原因（例如：在此環境中 DQN 收斂更快、穩定性更高）。

用途： 如果教授提問：「現在主流 RL 很多都在做連續控制，為什麼這篇只用離散角度？」，這頁就能直接秒殺這個問題。

Appendix B: Reward Function Design (獎勵函數細節)

內容： 放上論文中 Reward 的數學定義。包含：增加表面覆蓋率的獎勵 (Gain)、每走一步的懲罰 (Step penalty)，以及達到 90% 覆蓋率的終止額外獎勵 (Terminal bonus)。

用途： 報告時你只需口頭帶過「Reward 是基於表面覆蓋率」，但如果台下詢問「Agent 會不會為了賺分數一直在原地繞圈？」，你可以切換到這頁，向他們解釋 Step penalty 是如何逼迫 Agent 尋找最佳路徑的。

Appendix C: Houses3K Dataset (資料集簡介)

內容： 你的第 20 頁提到缺點是「過度依賴自定義的合成資料集 (Houses3K)」。可以放一頁展示該資料集的幾種房屋樣貌（屋頂形狀、窗戶等）。

用途： 若有人好奇這個資料集到底長什麼樣子，或者為何難以泛化到真實世界，這頁就是最好的輔助。
*/
