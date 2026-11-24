#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.2.2": default-palette, academic-sizes

// Two families of HTG models: (a) merge all snapshots into one graph before a
// heterogeneous GNN; (b) spatial GNN per snapshot, then a temporal module.
#let htg-paradigms(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.label)
  cetz.canvas(length: 1.3cm, {
    import cetz.draw: *
    set-style(stroke: 1.2pt + p.text)
    let arrow = (mark: (end: "stealth", fill: p.text))

    // node layout of the toy heterogeneous graph; two node types
    let pos = ((-0.6, 0.18), (-0.2, -0.22), (0.2, 0.22), (0.6, -0.18))
    let kinds = (p.primary, p.surface, p.primary, p.surface)
    let _graph(c, edges, sx: 1) = {
      let (cx, cy) = c
      let at(i) = (cx + pos.at(i).at(0) * sx, cy + pos.at(i).at(1))
      for (a, b) in edges {
        line(at(a), at(b), stroke: 0.8pt + p.text)
      }
      for i in range(pos.len()) {
        circle(at(i), radius: 0.1, fill: kinds.at(i), stroke: none)
      }
    }

    let _box(c, w, h, body, name, color: p.primary) = {
      let (x, y) = c
      rect((x - w / 2, y - h / 2), (x + w / 2, y + h / 2), radius: 0.12,
        fill: color.lighten(88%), stroke: 1.2pt + color, name: name)
      if body != none { content(name, align(center, body)) }
    }

    let snap-edges = (((0, 1), (1, 2)), ((1, 2), (2, 3)), ((0, 1), (1, 3)))
    let all-edges = ((0, 1), (1, 2), (2, 3), (1, 3))
    let xs = (0, 2.3, 5.2)
    let labels = ($G^1$, $G^2$, $G^T$)

    // bottom row of snapshots shared by both panels
    let _snapshots(ox, prefix) = {
      for (i, x) in xs.enumerate() {
        _box((ox + x, 3.0), 1.9, 1.0, none, prefix + str(i), color: p.muted)
        _graph((ox + x, 3.0), snap-edges.at(i))
        content((ox + x, 3.58), anchor: "south", text(fill: p.muted, labels.at(i)))
      }
      content((ox + 3.75, 3.0), [$dots.c$])
    }

    // (a) compress-based
    _snapshots(0, "a")
    _box((2.6, 1.65), 3.4, 1.0, none, "merged")
    _graph((2.6, 1.65), all-edges, sx: 2.2)
    for (i, dx) in ((0, -1.0), (1, 0), (2, 1.0)) {
      line("a" + str(i) + ".south", (2.6 + dx, 2.15), ..arrow, stroke: 1.2pt + p.muted)
    }
    content((4.6, 1.65), anchor: "west", text(size: sizes.small)[merge snapshots])
    _box((2.6, 0.4), 3.4, 0.8, [HGNN], "hgnn")
    line("merged.south", "hgnn.north", ..arrow)
    content((2.6, 4.1), anchor: "south", text(size: sizes.body)[*(a)* Compress-based])

    // (b) snapshot-based
    let ox = 12
    _snapshots(ox, "b")
    for (i, x) in xs.enumerate() {
      _box((ox + x, 1.65), 1.9, 0.8, [Spatial], "s" + str(i))
      line("b" + str(i) + ".south", "s" + str(i) + ".north", ..arrow)
    }
    content((ox + 3.75, 1.65), [$dots.c$])
    content((ox - 1.15, 1.65), anchor: "east", text(fill: p.muted)[(I)])
    _box((ox + 2.6, 0.4), 7.1, 0.8, [Temporal: RNN / Transformer], "temp")
    content((ox - 1.15, 0.4), anchor: "east", text(fill: p.muted)[(II)])
    for i in range(3) {
      line("s" + str(i) + ".south", ("s" + str(i) + ".south", "|-", "temp.north"), ..arrow)
    }
    content((ox + 2.6, 4.1), anchor: "south", text(size: sizes.body)[*(b)* Snapshot-based])
  })
}
