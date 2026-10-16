#import "@local/theme-academic:0.1.0": *
#import "@preview/cetz:0.5.2"

#let title-text = ""

#show: deck.with(footer: title-text)

#let palette = default-palette + (:)

#set figure(supplement: "Figure")
#show table: set text(size: 16pt)
#show footnote.entry: set text(size: 16pt)
#show list: set block(above: 0.65em, below: 0.65em)

// ───────── 封面 ─────────
#title-slide(
  title: title-text,
  authors: [],
  venue: [],
  year: [],
  presenters: ([11557028 楊育哲]),
  date: [],
)

// ───────── Outline ─────────
#outline-slide()

#slide()[References][
  #set text(lang: "en")
  #bibliography("refs.bib")
]
