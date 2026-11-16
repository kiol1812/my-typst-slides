#import "@local/theme-academic:0.2.1": *
#import "@preview/cetz:0.5.2"

#let title-text = ""

#show: deck.with(footer: title-text)

// ───────── 封面 ─────────
#title-slide(
  title: title-text,
  authors: [],
  affiliations: none,
  venue: [],
  year: [],
  presenters: ([11557028 楊育哲]),
  date: [],
)

// ───────── Outline ─────────
#outline-slide()

// ───────── 章節：#section[...] 不產生新頁，標示在下一張 slide 的標題上方與頁尾 ─────────
#section[Introduction]

#slide(source: [Source: ])[Title][
  - Content
]

#references-slide(bibliography("refs.bib"))
