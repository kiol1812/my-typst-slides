build slide:
   mkdir -p out
   typst compile --root . --package-path packages --font-path fonts \
     slides/{{slide}}/main.typ out/{{slide}}.pdf

watch slide:
    mkdir -p out
    typst watch --root . --package-path packages --font-path fonts \
      --diagnostic-format short \
      slides/{{slide}}/main.typ out/{{slide}}.pdf 2>&1 | grep -v -i "font"

new name:
    #!/usr/bin/env bash
    set -euo pipefail
    dir="slides/{{name}}"
    if [ -e "$dir" ]; then
        echo "✗ $dir 已存在，未做任何變更" >&2
        exit 1
    fi
    mkdir -p "$dir"
    cp templates/slide/main.typ "$dir/main.typ"
    sed "s/^date .*/date     = $(date +%F)/" templates/slide/meta.toml > "$dir/meta.toml"
    : > "$dir/refs.bib"
    echo "✓ 已建立 $dir（main.typ / meta.toml / refs.bib）"

fill name key="":
    python3 scripts/fill_slide_meta.py "slides/{{name}}" "{{key}}"

fig slide name:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p out
    theme=$(grep -m1 -o '@local/theme-[a-z-]*:[0-9.]*' "slides/{{slide}}/main.typ")
    printf '#import "%s": *\n#import "/slides/{{slide}}/assets/{{name}}.typ": %s\n#show: deck.with(footer: "{{slide}} / {{name}}")\n#slide[{{name}}][#align(center, %s())]\n' \
      "$theme" "{{name}}" "{{name}}" \
      | typst compile --root . --package-path packages --font-path fonts \
          --diagnostic-format short - "out/{{slide}}--{{name}}.pdf"
