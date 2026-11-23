#let default-palette = (
  primary: rgb("#334E86"),
  accent: rgb("#F9604D"),
  surface: rgb("#467886"),
  text: rgb("#0E3445"),
  muted: luma(127),
  positive: rgb("#334E86").lighten(40%),
  caution: rgb("#334E86").darken(20%),
  highlight: rgb("#334E86").lighten(20%),
)

// Size scale shared by all components:
//   body 20pt: running text (deck text, card / mini / callout / timeline / stat text)
//   title, subtitle, badge 20pt: bold headings inside components
//   label 16pt: secondary text (captions, flow descriptions, stat notes, figure nodes)
//   small 14pt: figure-internal text (ticks, edge labels, gantt)
#let default-sizes = (
  body: 20pt,
  title: 20pt,
  subtitle: 20pt,
  label: 16pt,
  small: 14pt,
  badge: 20pt,
  icon: 8pt,
  stat-value: 32pt,
  flow-number: 20pt,
)

// ---------- Input normalization shared by all components ----------

// Any displayable value (content, string, number, ...) as content; none stays none.
#let as-content(x) = if x == none or type(x) == content { x } else [#x]

// A color given as a color value, a palette key such as "accent", or auto / none for the fallback.
#let resolve-color(x, p, fallback) = {
  if x == auto or x == none { return fallback }
  if type(x) == str {
    assert(x in p, message: "unknown palette key \"" + x + "\"; use one of: " + p.keys().join(", "))
    return p.at(x)
  }
  x
}

// A record given as a dictionary, an array in `keys` order (trailing entries optional),
// or a single value used as the first key. Missing keys get `defaults`.
#let as-record(x, keys, defaults: (:)) = {
  let base = keys.map(k => (k, defaults.at(k, default: none))).to-dict()
  if type(x) == dictionary { return base + x }
  if type(x) == array {
    assert(x.len() <= keys.len(), message: "expected at most " + str(keys.len()) + " entries (" + keys.join(", ") + ")")
    return base + keys.zip(x).to-dict()
  }
  base + ((keys.first()): x)
}
