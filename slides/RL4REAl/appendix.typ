#import "@local/theme-academic:0.2.1": *

#let palette = default-palette + (:)

#let note(body) = text(size: 15pt, fill: palette.muted, body)
#let src(body) = [Source: VenkataKeerthy et al. (CC 2023), #body]

#appendix()

#slide(source: src[Figure 1, p. 3 (re-typeset); Sec. 2.1, pp. 2–3; notation unchanged])[Appendix A: Correctness Constraints in Detail][
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 16pt,
    figure(
      rect(
        inset: 0pt,
        width: 100%,
        stroke: 0.8pt + palette.text,
        grid(
          columns: (1fr, 1.9fr),
          stroke: (x, y) => if x == 1 { (left: 0.8pt + palette.text) } else { none },
          pad(0.3em)[
            #set text(size: 12pt)
            ```text
            // Source
            i = 0
            x = 10
            y = 20
            print x
            z = y / x
            i++
            z = z + 10
            i++
            print y
            print z
            print i
            ```
          ],
          pad(0.3em)[
            #set text(size: 12pt)
            ```text
            MOV32ri 0, %i:gr32
            MOV32ri 10, %x:gr32
            MOV32ri 20, %y:gr32
            <call print on %x>
            $eax = COPY %y:gr32
            <clear $edx>
            IDIV32r %x:gr32,
              implicit-def $eax,
              implicit-def $edx
            %z:gr32 = COPY $eax
            %i:gr32 = ADD32ri %i:gr32, 1
            ...
            ```
          ],
        ),
      ),
      caption: [(a) Source and (b) its Machine IR (Figure 1)],
    ),
    [
      #set text(size: 17pt)
      *Type*: register file $cal(R) = union.big_t R_t$
      $ chi^cal(T)(v^t) = {v^t ▶ r : r in R_t} $
      #note[`%x:gr32` may only take a 32-bit general register]

      *Congruence*: $C(r)$ = chunks of one register \
      #note[`$al`, `$ah` $subset.eq.sq$ `$ax` $subset.eq.sq$ `$eax` $subset.eq.sq$ `$rax`]
      $ chi^cal(C)(v^t) = {v_i^t ▶ r : forall v_i, v_j in cal(V), v_i != v_j, v_j ▶ r' in L(v_i)} $ \
      #note[for all $r' in C(r)$]

      *Interference*: no neighbor holds $r$
      $ chi^cal(I)(v^t) = R^t without {r : forall u ((u, v) in E and (u ▶ r))} $
      #note[pre-assigned: `IDIV32r` fixes `$eax`, `$edx`]
    ],
  )
]

#slide(source: src[Sec. 4, pp. 6–7; Sec. 5, p. 6; Sec. 6.1, p. 7])[Appendix B: Representing the Interference Graph][
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 16pt,
    card([MIR2Vec: instruction embedding])[
      Triplets: $"NextInst"$, $"Arg"_i$ #sym.arrow.r TransE, 100-dim seed vocabulary \
      Opcodes grouped by kind (x86: 15.3K opcodes, e.g. $approx 200$ MOVs)
      $ W_o dot [|O|] + W_a dot ([|A_1|] + dots.c + [|A_n|]), quad W_o > W_a $
      $W_o, W_a in (0, 1]$; vertex $[|v|] in RR^(m times n)$, $m$ instructions in $L(v)$
    ],
    card([GGNN: graph state], color: palette.accent)[
      $RR^(m times n) -> RR^d$, $d = n$ \
      Node types: not visited, spill, colored; plus spill weights \
      Message passing, GRU update #sym.arrow.r $[|G|]$ for $omega_upsilon$
    ],
  )
  - *LLVM-gRPC*: bidirectional RPC between Python agents and the C++ `MLRegAlloc` pass
  - Splits are applied by LLVM, which returns new interferences and live ranges
  - Python bindings were rejected: large overhead #note[(p. 6)]
]

#slide(source: src[Table 5 (cropped) and Sec. 6.4, p. 9])[Appendix C: Runtime on AArch64][
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 16pt,
    figure(
      image("assets/tab-5.png", height: 305pt),
      caption: [Runtime gain over Basic on ARM Cortex A72, Basic $-$ x (s); green: highest, yellow: second (Table 5)],
    ),
    [
      - Only RL4ReAl-G is reported
      - Average: Greedy 19.1 s, RL4ReAl 18.4 s, PBQP 5.3 s
      - Highest or second highest on all but four benchmarks
      - Cross-compiled from x86; median of 3 runs (5 if runs differ by $approx$ 20 s)
      - Some benchmarks skipped #note[(cross-compilation issues or baseline failures)]
    ],
  )
]

#slide(source: src[Table 2, p. 8 (cropped); Sec. 6.3, pp. 8–9; Sec. 6.5, pp. 9–10])[Appendix D: Hot Functions & Policy Improvement][
  #figure(
    image("assets/tab-2.png", width: 38%),
    caption: [% runtime difference over Basic on hot functions; bold: best per row (Table 2)],
  )
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 16pt,
    [
      - SPEC 2017: L 7.3% vs. Greedy 6.2% on average
      - SPEC 2006: all three slower than Basic
      - BZ2_compressBlock: Greedy $-51.3%$, RL4ReAl-G $-5.2%$
    ],
    [
      - Fine-tune on hot functions of regressions
      - milc (L) $+12$ s; hmmer, xz (G) $+10$ s, $+6$ s
      - Authors: a case for online / continuous learning
    ],
  )
]
