#import "@local/theme-academic:0.1.0": *

#let title-text = "組件展示範例"

#show: deck.with(footer: title-text)

#let palette = default-palette + (:)

// ───────── 封面 ─────────
#title-slide(
  title: title-text,
  authors: [Author A, Author B],
  venue: [Demo Venue],
  year: [2026],
  presenters: ([Presenter]),
  date: [2026/10/03],
)

// ───────── Outline ─────────
#outline-slide()

#section-slide[Overview]

#slide[Overview][
  #grid(
    columns: (1fr,) * 3, column-gutter: 8pt,
    stat("98%", "主要指標", note: "示範用的百分比數字"),
    stat($O(n log n)$, "時間複雜度", note: "示範用的數學式"),
    stat("12", "週", note: "Week 1–12"),
  )
  #figure(
    flow(
      (
        ("原始資料", "範例：10,000 筆紀錄", palette.primary),
        ("前處理", "清理、標準化、切分", palette.primary),
        ("特徵擷取", "向量化並快取", palette.primary),
        ("模型訓練", "調參與驗證", palette.accent),
        ("評估報告", "指標與視覺化", palette.accent),
      ),
      split: 3,
      zone-a: "前段：資料準備",
      zone-b: "後段：模型與評估",
    ),
    kind: image,
    caption: [流程圖範例：前段負責資料準備，後段負責模型與評估。],
  )
]

#section-slide[Positioning]

#slide[Positioning][
  #callout(title: "重點提示", kind: "info")[
    這是一個 callout 範例，用來強調一句重要的話。
  ]
  #v(2pt)
  #versus(
    card("方法 A", sub: "Baseline Approach")[
      傳統做法，*實作簡單*、容易重現，但在大規模資料上表現有限。
    ],
    card("方法 B", sub: "Advanced Approach")[
      較新的做法，*效果較好*，代價是需要更多運算資源與調參時間。
    ],
    card("本範例", sub: "Proposed Approach")[
      結合兩者優點：保留 A 的簡潔，吸收 B 的關鍵設計。
    ],
  )
]

#slide[Components][
  #grid(
    columns: (1fr, 1fr), gutter: 8pt,
    mini("A", "Alpha")[第一個要點的簡短說明，用來測試 mini 元件的排版],
    mini("B", "Beta")[第二個要點，內容稍長一些，用來觀察文字換行後的對齊情況與留白],
    mini("C", "Gamma")[第三個要點，包含行內數學 $x^2 + y^2 = r^2$ 的顯示],
    mini("D", "Delta")[第四個要點，結尾並說明下一步的行動],
  )
]

#slide[Schedule][
  #figure(
    gantt((
      (label: "Phase 1 規劃", start: 1, end: 3, color: main-palette.dark-40),
      (label: "Phase 2 原型", start: 4, end: 6, color: main-palette.dark-20),
      (label: "Phase 3 實作", start: 5, end: 9, color: main-palette.base),
      (label: "Phase 4 測試", start: 9, end: 11, color: main-palette.light-20),
      (label: "Phase 5 發表", start: 12, end: 12, color: main-palette.light-20),
    )),
    kind: image,
    caption: [甘特圖範例（以週為單位）。],
  )
]

#slide[Lists & Layout][
  #two-col(ratio: (1fr, 1fr))[
    - Source: Example Dataset @mnist
      - #link("https://example.com/file-a")[file-a.csv]
      - #link("https://example.com/file-b")[file-b.csv]
      - #link("https://example.com/file-c")[file-c.csv]
    - Size
      - Train: 8000
      - Test: 2000
  ][
    #align(center)[
      #rect(
        width: 100%, height: 110pt,
        fill: palette.surface, stroke: 1pt + palette.primary, radius: 4pt,
        align(center + horizon, text(fill: palette.primary)[圖片／圖表佔位]),
      )
    ]
  ]
]

// ───────── 參考資料（由 refs.bib 自動產生，只列出有被引用的）─────────
#slide()[References][
  #bibliography("refs.bib")
]
