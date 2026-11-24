/// 行內文字樣式：補充說明、強調色文字與結果表的最佳 / 次佳標示（皆接受數字、字串或內容）
#import "style.typ": default-palette, default-sizes, as-content, resolve-color

/// 灰色補充說明；size 預設沿用周圍字級
#let note(body, size: auto, palette: (:), sizes: default-sizes) = {
  let p = default-palette + palette
  if size == auto { text(fill: p.muted, as-content(body)) } else { text(size: size, fill: p.muted, as-content(body)) }
}

/// 強調色文字，預設為 palette 的 accent 原色（不加深，放在淡色底上也不會發暗）；color 可為 palette key 或 color
#let hl(body, color: auto, palette: (:), sizes: default-sizes) = {
  let p = default-palette + palette
  text(fill: resolve-color(color, p, p.accent), as-content(body))
}

/// 結果表中的最佳值（強調色粗體）
#let best(body, palette: (:), sizes: default-sizes) = {
  let p = default-palette + palette
  text(fill: p.accent, weight: "bold", as-content(body))
}

/// 結果表中的次佳值（主色底線）
#let second(body, palette: (:), sizes: default-sizes) = {
  let p = default-palette + palette
  text(fill: p.primary, underline(as-content(body)))
}
