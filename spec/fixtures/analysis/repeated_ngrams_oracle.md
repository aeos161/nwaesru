# Literal repeated n-gram controls

These values were counted by hand from the visible sequences. They do not use
the analyzer, its serializer, or a transformation to calculate expectations.
Indices are zero-based starts; spans end exclusively. Gaps subtract consecutive
starts in the selected representation.

| Sequence | n | Candidate starts | Distinct candidates | Retained patterns |
| --- | ---: | --- | ---: | --- |
| `AAAA` | 2 | 0, 1, 2 | 1 | `AA`: starts 0, 1, 2; count 3; gaps 1, 1 |
| `AAAA` | 3 | 0, 1 | 1 | `AAA`: starts 0, 1; count 2; gap 1 |
| `ABABA` | 2 | 0, 1, 2, 3 | 2 | `AB`: 0, 2; `BA`: 1, 3; both count 2, gap 2 |
| `ABABA` | 3 | 0, 1, 2 | 2 | `ABA`: 0, 2; count 2; gap 2. `BAB` occurs once. |
| empty | 2, 3 | none | 0 | insufficient sample |
| `A` | 2 | none | 0 | insufficient sample |
| `AB` | 2 | 0 | 1 | computed, no repeated pattern |

For real GP `ᚦᚪᚦ`, the original rune sequence has the pairs `ᚦᚪ` and
`ᚪᚦ`; neither repeats. The canonical expanded Latin sequence is `thath`.
It has four pair candidates: `th` at starts 0 and 3, `ha` at 1, `at` at 2.
Its three triple candidates are `tha`, `hat`, `ath`, all singletons. The two
`th` pairs each come from one `ᚦ` rune. The source rune ordinals for the five
Latin positions are 0, 0, 1, 2, 2, with offsets 0, 1, 0, 0, 1 and expansion
lengths 2, 2, 1, 2, 2.

For `ᛏᚻᛏᚻ`, expanded Latin is `thth`. Its `th` pairs start at 0 and 2,
each spanning two distinct source rune ordinals. Rune ordinals by Latin
position are 0, 1, 2, 3, each with offset 0 and expansion length 1.

For the saved transformation control, the literal original source is
`ᚦᚪᚦᚪ`. GP indices are 2, 24, 2, 24. Gematria Primus Atbash maps each
index `i` to `28-i`, so the mirrored runes are `ᚣᚱᚣᚱ` (indices 26, 4,
26, 4). Its `ᚣᚱ` pair starts at 0 and 2. Reversing the four rune tokens
gives `ᚱᚣᚱᚣ`, with `ᚱᚣ` at starts 0 and 2. Both have pair candidate count
3, distinct pair count 2, repeated pattern count 1, repeated occurrence
count 2, and a consecutive start gap of 2. The original source rune
indices mapped to reversed current positions are 3, 2, 1, 0. This
calculation uses the published GP order and literal token reversal;
it does not use transformed output or analyzer output as an oracle.

When checking order, use the declared alphabet indices. For the `ABABA`
spec, A is `ᚪ` at GP index 24 and B is `ᚠ` at index 0. Therefore `BA`
precedes `AB` in the retained pair array despite first occurring later.
