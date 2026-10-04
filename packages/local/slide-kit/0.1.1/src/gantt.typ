/// 甘特圖。rows: (label:, start:, end:, color:)
#import "style.typ": default-palette, default-sizes

#let gantt(rows, total: 16, mid: 8, palette: (:), sizes: default-sizes) = {
  let p = default-palette + palette
  let cells = ([],)
  for w in range(1, total + 1) {
    cells.push(align(center, text(
      sizes.small, fill: if w == mid { p.highlight } else { p.positive },
      weight: if w == mid { "bold" } else { "regular" }, str(w),
    )))
  }
  for r in rows {
    cells.push(align(right + horizon, pad(right: 8pt, text(sizes.small, weight: "bold", r.label))))
    for w in range(1, total + 1) {
      let on = w >= r.start and w <= r.end
      cells.push(grid.cell(
        fill: if on { r.color } else { luma(246) },
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
