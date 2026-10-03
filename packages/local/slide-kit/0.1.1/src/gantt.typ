/// 甘特圖。rows: (label:, start:, end:, color:)
#import "palette.typ": default-palette

#let gantt(rows, total: 16, mid: 8) = {
  let cells = ([],)
  for w in range(1, total + 1) {
    cells.push(align(center, text(
      14pt, fill: if w == mid { default-palette.info } else { default-palette.tip },
      weight: if w == mid { "bold" } else { "regular" }, str(w),
    )))
  }
  for r in rows {
    cells.push(align(right + horizon, pad(right: 8pt, text(14pt, weight: "bold", r.label))))
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
