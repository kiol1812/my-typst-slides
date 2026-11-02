#import "@local/theme-academic:0.1.2": *
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

#references-slide(bibliography("refs.bib"))
