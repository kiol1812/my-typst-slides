#import "@preview/cetz:0.5.2"
#import "@local/theme-academic:0.2.1": default-palette, academic-sizes

#let live-split(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  set text(size: sizes.small)
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let (def, k, k1, end) = (0, 3.8, 5.2, 7.6)
    let bar(a, b, y, color, label) = {
      line((a, y), (b, y), stroke: 2pt + color, mark: (start: "|", end: "|"))
      content((a - 0.2, y), anchor: "east", label)
    }
    let tick(x, label) = content((x, 1.75), anchor: "south", label)
    bar(def, end, 1.4, p.text, $L(v)$)
    tick(def, $P_v^italic("def")$)
    tick(k, $P_v^k$)
    tick(k1, $P_v^(k+1)$)
    tick(end, $P_v^italic("end")$)
    for x in (k, k1) { circle((x, 1.4), radius: 0.07, fill: p.text, stroke: none) }
    let mid = (k + k1) / 2
    line((mid, 1.65), (mid, 0.05), stroke: (paint: p.accent, thickness: 1.2pt, dash: "dashed"))
    content((mid, 0.7), anchor: "west", padding: 0.1, text(fill: p.accent, $phi(v, k)$))
    bar(def, k, 0.3, p.primary, $L(v')$)
    line((k1, 0.3), (end, 0.3), stroke: 2pt + p.surface, mark: (start: "|", end: "|"))
    content((end + 0.2, 0.3), anchor: "west", $L(v'')$)
  })
}
