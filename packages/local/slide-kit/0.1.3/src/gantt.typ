/// 甘特圖。rows 的每一項可以是 (label:, start:, end:, color:) 或 (label, start, end, color) 陣列；
/// color 可省略（預設 primary），也可為 palette key
#import "style.typ": default-palette, default-sizes, as-content, resolve-color, as-record

#let gantt(rows, total: 16, mid: 8, palette: (:), sizes: default-sizes) = {
  let p = default-palette + palette
  let rows = rows.map(r => as-record(r, ("label", "start", "end", "color"), defaults: (color: auto)))
  let cells = ([],)
  for w in range(1, total + 1) {
    cells.push(align(center, text(
      sizes.small, fill: if w == mid { p.highlight } else { p.positive },
      weight: if w == mid { "bold" } else { "regular" }, str(w),
    )))
  }
  for r in rows {
    cells.push(align(right + horizon, pad(right: 8pt, text(sizes.small, weight: "bold", as-content(r.label)))))
    let c = resolve-color(r.color, p, p.primary)
    for w in range(1, total + 1) {
      let on = w >= r.start and w <= r.end
      cells.push(grid.cell(
        fill: if on { c } else { luma(246) },
        stroke: { none },
        [],
      ))
    }
  }
  grid(
    columns: (auto,) + (1fr,) * total,
    rows: (auto,) + (16pt,) * rows.len(),
    row-gutter: 3pt,
    ..cells,
  )
}
