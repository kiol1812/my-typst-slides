// 模板依賴共用元件：版本寫死，確保可重現
#import "@local/slide-kit:0.1.0": callout, code-block

#let deck(
  title: "",
  author: "",
  date: none,
  font: ("New Computer Modern", "TW-MOE-Std-Kai"),
  body,
) = {
  set document(title: title, author: author)
  set page(paper: "presentation-16-9", margin: 1.5cm)
  set text(font: font, size: 20pt, lang: "zh")

  align(center + horizon)[
    #text(size: 36pt, weight: "bold")[#title] \ \
    #author #if date != none [ · #date]
  ]
  body
}

#let slide(title: none, body) = {
  pagebreak(weak: true)
  if title != none { text(size: 28pt, weight: "bold")[#title]; v(0.6em) }
  body
}
