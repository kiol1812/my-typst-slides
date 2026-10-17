#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "@local/theme-academic:0.1.0": default-palette, academic-sizes

#let st-detector(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  let hot = (stroke: 1.2pt + p.accent, fill: p.accent.lighten(88%))
  let module = (fill: p.surface.lighten(85%), stroke: 1.2pt + p.surface)
  set text(size: sizes.label)
  diagram(
    spacing: (14mm, 9mm),
    node-stroke: 1.2pt + p.primary,
    node-fill: p.primary.lighten(88%),
    node-corner-radius: 4pt,
    node-inset: 8pt,
    edge-stroke: 1.2pt + p.text,

    node((0, 0), [$bold(X)$, graph $bold(A)$], name: <x>),
    node((0, 1), [$tilde(bold(X))$, graph $tilde(bold(A))$], name: <xt>, ..hot),

    node((1, 0), [GAT], name: <gat>, ..module),
    node((1, 1), [GAT], name: <gatt>, ..module),
    node((2, 0), [Chunk-wise \ TCN], name: <tcn>, ..module),
    node((2, 1), [Chunk-wise \ TCN], name: <tcnt>, ..module),

    node((3, 0.5), [Stack \ $[bold(Z)_T; tilde(bold(Z))_T]$], name: <stack>),
    node((4, 0.5), [Predictor \ $cal(P)$], name: <pred>),
    node((5, 0.5), [$hat(p)$], name: <out>, shape: fletcher.shapes.circle),

    edge(<x>, <gat>, "-|>"),
    edge(<xt>, <gatt>, "-|>"),
    edge(<gat>, <tcn>, "-|>"),
    edge(<gatt>, <tcnt>, "-|>"),
    edge(<tcn>, <stack>, "-|>"),
    edge(<tcnt>, <stack>, "-|>"),
    edge(<stack>, <pred>, "-|>"),
    edge(<pred>, <out>, "-|>"),

    // shared parameters between the two branches
    edge(<gat>, <gatt>, "<|-|>", stroke: (paint: p.muted, dash: "dashed"),
      text(size: sizes.small, fill: p.muted)[shared], label-side: left),
    edge(<tcn>, <tcnt>, "<|-|>", stroke: (paint: p.muted, dash: "dashed"),
      text(size: sizes.small, fill: p.muted)[shared], label-side: left),

    node((1, 1.75), text(size: sizes.small, fill: p.muted)[spatial], stroke: none, fill: none),
    node((2, 1.75), text(size: sizes.small, fill: p.muted)[temporal], stroke: none, fill: none),
    node((5, 1.25), text(size: sizes.small, fill: p.muted)[binary cross-entropy \ $y = 0$ or $1$], stroke: none, fill: none),
  )
}
