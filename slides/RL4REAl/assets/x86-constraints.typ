#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.2.1": default-palette, academic-sizes

#let _reg(body) = raw(body)

#let type-fig(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.small)
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let ok = (stroke: 1.2pt + p.primary, fill: p.primary.lighten(88%))
    let no = (stroke: 0.8pt + p.muted, fill: none)
    rect((0, 0.375), (2.1, 1.075), ..ok, radius: 0.1, name: "v")
    content("v", _reg("%x:gr32"))
    let classes = (
      ([GR32], "$eax …", ok),
      ([GR64], "$rax …", no),
    )
    for (i, (name, regs, style)) in classes.enumerate() {
      let y = 0.9 - i * 0.95
      rect((3.1, y), (7.2, y + 0.6), ..style, radius: 0.1, name: "c" + str(i))
      content((3.25, y + 0.3), anchor: "west", text(weight: "bold", name))
      content((7.05, y + 0.3), anchor: "east", _reg(regs))
      if i == 0 {
        line("v.east", "c0.west", stroke: 1.2pt + p.primary, mark: (end: "stealth", fill: p.primary))
      } else {
        line("v.east", "c" + str(i) + ".west", stroke: (paint: p.muted, thickness: 0.8pt, dash: "dashed"), name: "bad")
        content("bad.mid", text(fill: p.accent, weight: "bold")[×])
      }
    }
  })
}

#let congruence-fig(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.small)
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let w = 6.2
    let h = 0.52
    let box(x0, x1, row, label, style) = {
      let y = (3 - row) * h
      rect((x0, y), (x1, y + h), ..style, name: "b")
      content("b", _reg(label))
    }
    let base = (stroke: 1.2pt + p.primary, fill: p.primary.lighten(88%))
    let held = (stroke: 1.2pt + p.accent, fill: p.accent.lighten(80%))
    box(0, w, 0, "$rax", base)
    box(w / 2, w, 1, "$eax", base)
    box(w * 0.6, w, 2, "$ax", base)
    box(w * 0.6, w * 0.8, 3, "$ah", base)
    box(w * 0.8, w, 3, "$al", held)
    for (row, bits) in ([64 bit], [32 bit], [16 bit], [8 bit]).enumerate() {
      content((-0.15, (3 - row) * h + h / 2), anchor: "east", text(fill: p.muted, bits))
    }
  })
}

#let interference-fig(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.small)
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let s = 0.4
    let bar(name, a, b, y) = {
      line((a * s, y), (b * s, y), stroke: 2pt + p.text, mark: (start: "|", end: "|"))
      content((a * s - 0.15, y), anchor: "east", name)
    }
    rect((3 * s, -0.1), (5 * s, 1.1), fill: p.accent.lighten(80%), stroke: none)
    bar($x$, 2, 5, 0.8)
    bar($y$, 3, 9, 0.2)
    content((4 * s, 1.1), anchor: "south", text(fill: p.accent)[overlap])
    line((4.1, 0.5), (4.8, 0.5), stroke: 1.2pt + p.text, mark: (end: "stealth", fill: p.text))
    let node-style = (stroke: 1.2pt + p.primary, fill: p.primary.lighten(88%))
    circle((5.4, 0.5), radius: 0.4, ..node-style, name: "x")
    circle((7.0, 0.5), radius: 0.4, ..node-style, name: "y")
    content("x", $x$)
    content("y", $y$)
    line("x.east", "y.west", stroke: 1.2pt + p.text)
    content("x.south", anchor: "north", padding: 0.08, _reg("$eax"))
    content("y.south", anchor: "north", padding: 0.08, _reg("$ebx"))
  })
}

#let x86-constraints(palette: (:), sizes: academic-sizes) = grid(
  columns: 1,
  row-gutter: 1em,
  align: horizon,
  type-fig(palette: palette, sizes: sizes),
  congruence-fig(palette: palette, sizes: sizes),
  interference-fig(palette: palette, sizes: sizes),
)
