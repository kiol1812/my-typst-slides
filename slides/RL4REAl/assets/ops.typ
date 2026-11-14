#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.2.1": default-palette, academic-sizes

#let ops(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.small)
  let r = 0.42
  let node-style = (stroke: 1.2pt + p.primary, fill: p.primary.lighten(88%))
  let edge-stroke = 1.2pt + p.text
  let gone-stroke = (paint: p.muted, thickness: 0.8pt, dash: "dashed")
  // which LLVM allocators support each operation (Sec. 2.3)
  let support = (
    all: (p.muted, [All four]),
    coalesce: (p.surface, [Greedy, PBQP]),
    greedy: (p.text, [Greedy only]),
  )

  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let vertex(pos, label, style: node-style) = {
      circle(pos, radius: r, ..style, name: "v")
      content("v", label)
    }
    let link(a, b, s: edge-stroke) = line(a, b, stroke: s)
    let move(a, b, ctrl, label: none, anchor: "south", color: p.text) = {
      bezier(a, b, ctrl, stroke: 1.2pt + color, mark: (end: "stealth", fill: color), name: "m")
      content("m.mid", anchor: anchor, padding: 0.1, text(fill: color, label))
    }
    // interference triangle y-x-z centered at cx
    let triangle(cx, x-style: node-style, x-stroke: edge-stroke) = {
      link((cx, 1.2), (cx - 0.75, 0), s: x-stroke)
      link((cx - 0.75, 0), (cx + 0.75, 0), s: x-stroke)
      link((cx, 1.2), (cx + 0.75, 0))
      vertex((cx, 1.2), [$y$])
      vertex((cx - 0.75, 0), [$x$], style: x-style)
      vertex((cx + 0.75, 0), [$z$])
    }

    // after coloring x
    triangle(1.0, x-style: (stroke: 1.2pt + p.accent, fill: p.accent.lighten(85%)))

    // original interference graph
    triangle(5.6)

    // after splitting y into y', y''
    link((9.9, 1.2), (9.9, 0))
    link((11.5, 1.2), (11.5, 0))
    link((9.9, 0), (11.5, 0))
    link((9.9, 1.2), (11.5, 1.2), s: gone-stroke)
    vertex((9.9, 1.2), [$y'$])
    vertex((11.5, 1.2), [$y''$])
    vertex((9.9, 0), [$x$])
    vertex((11.5, 0), [$z$])

    // after spilling x to memory
    rect((12.45, -1.0), (14.45, 0.55), stroke: 1.2pt + p.muted, fill: p.muted.lighten(88%), name: "mem")
    content("mem.south", anchor: "south", padding: 0.06, text(fill: p.muted)[memory])
    triangle(14.2, x-style: (stroke: 1.2pt + p.muted, fill: p.muted.lighten(80%)), x-stroke: gone-stroke)

    // operations
    move((4.25, 1.0), (2.35, 1.0), (3.3, 1.45), label: [coloring], color: support.all.at(0))
    move((2.35, 0.2), (4.25, 0.2), (3.3, -0.25), label: [eviction], anchor: "north", color: support.greedy.at(0))
    move((6.95, 1.0), (9.45, 1.0), (8.2, 1.45), label: [splitting], color: support.greedy.at(0))
    move((9.45, 0.2), (6.95, 0.2), (8.2, -0.25), label: [coalescing], anchor: "north", color: support.coalesce.at(0))
    move((5.9, 1.9), (13.9, 1.9), (9.9, 3.9), label: [spilling], color: support.all.at(0))

    // legend
    for (i, (color, label)) in support.values().enumerate() {
      let y0 = 3.3 - i * 0.55
      line((-0.2, y0), (0.4, y0), stroke: 1.2pt + color)
      content((0.55, y0), anchor: "west", text(fill: color, label))
    }
  })
}
