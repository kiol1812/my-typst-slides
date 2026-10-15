build slide:
   mkdir -p out
   typst compile --root . --package-path packages --font-path fonts \
     slides/{{slide}}/main.typ out/{{slide}}.pdf

watch slide:
    mkdir -p out
    typst watch --root . --package-path packages --font-path fonts \
      --diagnostic-format short \
      slides/{{slide}}/main.typ out/{{slide}}.pdf 2>&1 | grep -v -i "font"
