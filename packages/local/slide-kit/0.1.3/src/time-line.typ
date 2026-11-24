#import "style.typ": default-palette, default-sizes, as-content, as-record

/// 時間軸。items 的每一項可以是：
///   (year: [2008], title: [..], desc: [..])   dictionary，year / desc 可省略
///   ([2008], [Title], [desc])                 陣列，後面的項目可省略
///   [Title]                                    只有標題
/// 年份可直接寫數字，例如 (year: 2008, title: [..])
#let timeline(
  items: (),
  palette: (:),
  sizes: default-sizes
) = {
  let p = default-palette + palette
  let color-line = p.muted.lighten(50%)
  let color-surface = p.surface
  let color-title = p.text
  let color-desc = p.muted
  // A bare title (not an array or dictionary) becomes the title, not the year.
  let items = items.map(it => if type(it) in (dictionary, array) {
    as-record(it, ("year", "title", "desc"))
  } else {
    (year: none, title: it, desc: none)
  })
  block(
    width: 100%,
    stroke: (left: 2pt + color-line),
    inset: (left: 20pt, top: 15pt, bottom: 15pt),
    {
      for (i, item) in items.enumerate() {
        let is-last = (i == items.len() - 1)
        block(
          width: 100%,
          inset: (bottom: if is-last { 0pt } else { 5pt }),
          {
            place(left, dx: -24pt, dy: 0.1em)[
              #circle(radius: 4pt, fill: color-surface, stroke: none)
            ]
            grid(
              columns: (auto, 1fr),
              column-gutter: if item.year == none { 0pt } else { 20pt },
              text(fill: color-surface, weight: "bold", size: sizes.body, as-content(item.year)),
              {
                text(fill: color-title, weight: "bold", size: sizes.body, as-content(item.title))
                if item.desc != none {
                  v(4pt, weak: true)
                  set par(leading: 0.6em)
                  text(fill: color-desc, size: sizes.body, as-content(item.desc))
                }
              }
            )
          }
        )
      }
    }
  )
}
