/// Row of blocks that share the tallest natural height.
/// Each item is a function of a height (`auto` while measuring), e.g.
///   #equal-row(columns: (1fr, 1fr), h => card([A], height: h)[...], h => card([B], height: h)[...])
/// `columns` accepts `auto` (natural width) and fractions.
#let equal-row(columns: (), gutter: 14pt, ..items) = layout(size => {
  let items = items.pos()
  let autos = columns.zip(items).map(((c, it)) => if c == auto { measure(it(auto)).width } else { 0pt })
  let fr-total = columns.filter(c => type(c) == fraction).map(c => c / 1fr).sum(default: 0)
  let free = size.width - gutter * (items.len() - 1) - autos.sum()
  let widths = columns.zip(autos).map(((c, a)) => if c == auto { a } else { free * (c / 1fr) / fr-total })
  let h = calc.max(..items.zip(widths).map(((it, w)) => measure(it(auto), width: w).height))
  grid(columns: widths, column-gutter: gutter, ..items.map(it => it(h)))
})
