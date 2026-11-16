/// 行內文字樣式：補充說明與結果表的最佳 / 次佳標示
#import "style.typ": default-palette, default-sizes

/// 灰色補充說明；size 預設沿用周圍字級
#let note(body, size: auto, palette: (:), sizes: default-sizes) = {
  let p = default-palette + palette
  if size == auto { text(fill: p.muted, body) } else { text(size: size, fill: p.muted, body) }
}

/// 結果表中的最佳值（強調色粗體）
#let best(body, palette: (:), sizes: default-sizes) = {
  let p = default-palette + palette
  text(fill: p.accent, weight: "bold", body)
}

/// 結果表中的次佳值（主色底線）
#let second(body, palette: (:), sizes: default-sizes) = {
  let p = default-palette + palette
  text(fill: p.primary, underline(body))
}
