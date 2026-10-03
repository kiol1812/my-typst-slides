build slide:
   mkdir -p out
   typst compile --root . --package-path packages --font-path fonts \
     slides/{{slide}}/main.typ out/{{slide}}.pdf

watch slide:
   mkdir -p out
   typst watch --root . --package-path packages --font-path fonts \
     slides/{{slide}}/main.typ out/{{slide}}.pdf
