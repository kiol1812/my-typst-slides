// template: theme-academic 0.1.2+
// template: just new 會把 <version> 換成選定的版本，並自動刪除這兩行
#import "@local/theme-academic:<version>": *
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
