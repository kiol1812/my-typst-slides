build slide:
   mkdir -p out
   typst compile --root . --package-path packages --font-path fonts \
     slides/{{slide}}/main.typ out/{{slide}}.pdf

watch slide:
    mkdir -p out
    typst watch --root . --package-path packages --font-path fonts \
      --diagnostic-format short \
      slides/{{slide}}/main.typ out/{{slide}}.pdf 2>&1 | grep -v -i "font"

# new slide from templates/<template>; no version: ask in a terminal, else the newest supported
new name template="slide" version="":
    #!/usr/bin/env bash
    set -euo pipefail
    dir="slides/{{name}}"
    tpl="templates/{{template}}"
    if [ ! -d "$tpl" ]; then
        echo "✗ 找不到模板 $tpl（可用：$(ls templates | tr '\n' ' ')）" >&2
        exit 1
    fi
    if [ -e "$dir" ]; then
        echo "✗ $dir 已存在，未做任何變更" >&2
        exit 1
    fi
    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT
    theme=$(python3 scripts/template_versions.py render "{{template}}" "$tmp" {{ if version == "" { "" } else { quote(version) } }})
    mkdir -p "$dir"
    mv "$tmp" "$dir/main.typ"
    sed "s/^date .*/date     = $(date +%F)/" "$tpl/meta.toml" > "$dir/meta.toml"
    : > "$dir/refs.bib"
    echo "✓ 已建立 $dir（main.typ / meta.toml / refs.bib，$theme）"
    if grep -q '// 提醒：' "$dir/main.typ"; then
        echo "  寫完內容後刪除 main.typ 中以「// 提醒：」開頭的註解" >&2
    fi

fill name key="":
    python3 scripts/fill_slide_meta.py "slides/{{name}}" "{{key}}"

# render every page to PNG for layout review -> out/<slide>-png/<page>.png
png slide ppi="60":
    rm -rf out/{{slide}}-png
    mkdir -p out/{{slide}}-png
    typst compile --root . --package-path packages --font-path fonts \
      --diagnostic-format short --ppi {{ppi}} \
      slides/{{slide}}/main.typ "out/{{slide}}-png/{0p}.png" 2>&1 | grep -v -i "unknown font family" || true
    @echo "✓ out/{{slide}}-png/"

# list pages pushed out by overflowing content (needs theme-academic 0.1.2 / 0.2.1+)
check slide:
    #!/usr/bin/env bash
    set -euo pipefail
    pages=$(typst query --root . --package-path packages --font-path fonts \
      slides/{{slide}}/main.typ "<dlcv-overflow>" --field value --one 2>/dev/null) || {
        echo "✗ 無法檢查：編譯失敗，或主題版本早於 theme-academic 0.1.2 / 0.2.1" >&2
        exit 1
    }
    pages=$(echo "$pages" | tr -d '[:space:]')
    if [ "$pages" = "[]" ]; then
        echo "✓ {{slide}}：沒有內容溢出的頁面"
    else
        echo "✗ {{slide}}：以下實體頁是上一張投影片溢出的內容：$pages" >&2
        exit 1
    fi

fig slide name:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p out
    theme=$(grep -m1 -o '@local/theme-[a-z-]*:[0-9.]*' "slides/{{slide}}/main.typ")
    printf '#import "%s": *\n#import "/slides/{{slide}}/assets/{{name}}.typ": %s\n#show: deck.with(footer: "{{slide}} / {{name}}")\n#slide[{{name}}][#align(center, %s())]\n' \
      "$theme" "{{name}}" "{{name}}" \
      | typst compile --root . --package-path packages --font-path fonts \
          --diagnostic-format short - "out/{{slide}}--{{name}}.pdf"

# versions each template accepts and the default `just new` picks (newest folder in the series)
versions:
    @python3 scripts/template_versions.py list

# minimal standalone project (source, assets, used local packages, README) -> out/<slide>.zip
export slide:
    python3 scripts/export-slide.py {{slide}}
