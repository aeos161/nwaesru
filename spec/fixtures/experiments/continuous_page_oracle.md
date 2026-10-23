# Independent two-source oracle

The complete source bodies are `ᚳ-ᚻ` (page 99, seven UTF-8 bytes, no final
newline) and `ᚷᚻ` (page 100, six UTF-8 bytes). The aggregate source bytes are
exactly `ᚳ-ᚻᚷᚻ`; the boundary is byte 7. The hyphen is punctuation and does not
consume a prime. GP indexes are 5, 8, 6, 8. The first four primes are 2, 3,
5, 7, so subtraction of p − 1 gives indexes 4, 6, 2, 2 modulo 29. Their runes
are `ᚱ-ᚷᚦᚦ`. Page 100's first rune is `ᚦ` under the continuing prime 5;
restarting at prime 2 would make it `ᚳ`. The compatibility parser renders
the hyphen as a word space and the page boundary as a line break. The final
Latin bytes are `r g\nthth`, with `th` expanding each `ᚦ`.

SHA-256, calculated separately over UTF-8 bytes using Python hashlib:

| Layer | SHA-256 |
| --- | --- |
| Aggregate original | `370480baec1ce0733ce2dbc480c8c7676169ff5702d6cbb5cce1b28501ba406a` |
| Totient | `a16e1440b8d3096cd9603f2a32310acf7990628f24fd7b96cb7efb6209cfd6aa` |
| Final Latin | `64576525ccfda6ed5e37a3a15e64051f6a762836745d588280b667760fb2b5ba` |

Rune source coordinates, in global ordinal order, are:

| Ordinal | Page | Occurrence | Byte range | Character range | Line, column | Page rune index |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | 99 | 0 | [0, 3) | [0, 1) | 0, 0 | 0 |
| 1 | 99 | 0 | [4, 7) | [2, 3) | 0, 2 | 1 |
| 2 | 100 | 1 | [0, 3) | [0, 1) | 0, 0 | 0 |
| 3 | 100 | 1 | [3, 6) | [1, 2) | 0, 1 | 1 |

This oracle is a test fixture. It does not describe a research run or its
target hash.
