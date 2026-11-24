/// Row of blocks that share the tallest natural height.
/// Each item is a function of a height (`auto` while measuring), e.g.
///   #equal-row(columns: (1fr, 1fr), h => card([A], height: h)[...], h => card([B], height: h)[...])
/// A plain content item is placed at its natural height.
/// `columns` accepts `auto` (natural width, for items with a fixed width; a card fills its column
/// so it belongs in a fraction column) and fractions; omitted, all items share the width equally.
#let equal-row(columns: auto, gutter: 14pt, ..items) = layout(size => {
  let items = items.pos().map(it => if type(it) == function { it } else { _ => it })
  if items.len() == 0 { return none }
  let columns = if columns == auto { (1fr,) * items.len() } else { columns }
  assert(columns.len() == items.len(), message: "equal-row: columns and items must have the same length")
  let autos = columns.zip(items).map(((c, it)) => if c == auto { measure(it(auto)).width } else { 0pt })
  let fr-total = columns.filter(c => type(c) == fraction).map(c => c / 1fr).sum(default: 0)
  let free = size.width - gutter * (items.len() - 1) - autos.sum()
  let widths = columns.zip(autos).map(((c, a)) => if c == auto { a } else { free * (c / 1fr) / fr-total })
  let h = calc.max(..items.zip(widths).map(((it, w)) => measure(it(auto), width: w).height))
  grid(columns: widths, column-gutter: gutter, ..items.map(it => it(h)))
})
