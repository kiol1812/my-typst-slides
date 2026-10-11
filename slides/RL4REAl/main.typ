#import "@local/theme-academic:0.1.0": *
#import "@preview/cetz:0.5.2"

#let title-text = "RL4ReAl: Reinforcement Learning for Register Allocation"

#show: deck.with(footer: title-text)

#let palette = default-palette + (:)

#set figure(supplement: "Figure")
#show table: set text(size: 16pt)
#show footnote.entry: set text(size: 16pt)
#show list: set block(above: 0.65em, below: 0.65em)

// ───────── 封面 ─────────
#title-slide(
  title: title-text,
  authors: [VenkataKeerthy, S. and Jain, Siddharth and Kundu, Anilava and Aggarwal, Rohit and Cohen, Albert and Upadrasta, Ramakrishna],
  venue: [Compiler Construction],
  year: [2023],
  presenters: ([11557028 楊育哲]),
  date: [2026/10/07],
)

// ───────── Outline ─────────
#outline-slide()

#section-slide[Introduction]

#section-slide[Methodology]

#section-slide[Experiments]

#section-slide[]
