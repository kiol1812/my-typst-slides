#let callout(title: none, color: blue, body) = block(
  width: 100%, inset: 12pt, radius: 4pt,
  fill: color.lighten(85%), stroke: (left: 3pt + color),
)[
  #if title != none [#strong(title) \ ]
  #body
]
