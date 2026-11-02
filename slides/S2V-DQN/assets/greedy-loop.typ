#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "@local/theme-academic:0.2.0": default-palette, academic-sizes

// Classical greedy meta-algorithm (Eq. 1); the evaluation function is the hand-crafted part.
#let greedy-loop(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  let hot = (stroke: 1.2pt + p.accent, fill: p.accent.lighten(88%))
  let note(body) = text(size: sizes.small, fill: p.muted, body)
  set text(size: sizes.label)
  diagram(
    spacing: (12mm, 7mm),
    node-stroke: 1.2pt + p.primary,
    node-fill: p.primary.lighten(88%),
    node-corner-radius: 4pt,
    node-inset: 8pt,
    edge-stroke: 1.2pt + p.text,

    node((0, 0), [Partial solution \ $S$, tags $x_v$], name: <s>),
    node((1, 0), [Score every $v in overline(S)$ \ $Q(h(S), v)$], name: <q>, ..hot),
    node((2, 0), [Select \ $v^* = op("argmax") Q$], name: <sel>),
    node((3, 0), [Extend \ $S := (S, v^*)$], name: <ext>),
    node((4, 0), [$t(h(S))$?], name: <t>, shape: fletcher.shapes.diamond),
    node((5, 0), [Done], name: <done>, shape: fletcher.shapes.pill),

    edge(<s>, <q>, "-|>"),
    edge(<q>, <sel>, "-|>"),
    edge(<sel>, <ext>, "-|>"),
    edge(<ext>, <t>, "-|>"),
    edge(<t>, <done>, "-|>", note[yes], label-side: left),
    edge(<t>, <s>, "-|>", bend: 22deg, note[no], label-side: left),

    node((1, -0.85), text(size: sizes.small, fill: p.accent)[hand-crafted per problem], stroke: none, fill: none),
  )
}
