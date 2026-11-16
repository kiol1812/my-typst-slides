#import "@local/theme-academic:0.2.1": default-palette, academic-sizes
#import "sorting-network.typ": sorting-network

// (instruction, original comment, AlphaDev comment, mark); AlphaDev comment none = line removed
#let _rows = (
  ("mov Memory[0] P", "P = A", "P = A", none),
  ("mov Memory[1] Q", "Q = B", "Q = B", none),
  ("mov Memory[2] R", "R = C", "R = C", none),
  ("mov R S", "", "", none),
  ("cmp P R", "", "", none),
  ("cmovg P R", "R = max(A, C)", "R = max(A, C)", none),
  ("cmovl P S", "S = min(A, C)", "S = min(A, C)", none),
  ("mov S P", "P = min(A, C)", none, "del"),
  ("cmp S Q", "", "", none),
  ("cmovg Q P", "P = min(A, B, C)", "P = min(A, B)", "chg"),
  ("cmovg S Q", "Q = max(min(A, C), B)", "Q = max(min(A, C), B)", none),
  ("mov P Memory[0]", "= min(A, B, C)", "= min(A, B)", "chg"),
  ("mov Q Memory[1]", "= max(min(A, C), B)", "= max(min(A, C), B)", none),
  ("mov R Memory[2]", "= max(A, C)", "= max(A, C)", none),
)

#let _listing(alphadev, mark-fill, p, sizes) = {
  set text(size: sizes.small)
  grid(
    columns: (auto, auto),
    inset: (x: 4pt, y: 2.2pt),
    fill: (_, y) => {
      let (_, _, new, mark) = _rows.at(y)
      if mark != none and not (alphadev and new == none) { mark-fill }
    },
    .._rows.map(((code, orig, new, mark)) => {
      let comment = if alphadev { new } else { orig }
      if comment == none {
        (raw(" "), [])
      } else {
        (raw(code), if comment == "" [] else { raw("// " + comment) })
      }
    }).flatten(),
  )
}

#let swap-move(palette: (:), sizes: academic-sizes) = {
  let p = default-palette + palette
  let label(body) = text(size: sizes.small, fill: p.muted, body)
  grid(
    columns: (auto, auto, auto),
    column-gutter: 16pt,
    row-gutter: 6pt,
    align: (center + horizon, left + top, left + top),
    label[(a) sorting network, 3 inputs], label[(b) Original], label[(c) AlphaDev],
    sorting-network(
      values: ([A], [B], [C]),
      layers: (((1, 2),), ((0, 2),), ((0, 1),)),
      circled: (1, 2),
      dx: 1.3,
      palette: palette,
      sizes: sizes,
    ),
    _listing(false, p.accent.lighten(75%), p, sizes),
    _listing(true, p.primary.lighten(80%), p, sizes),
  )
}
