# Independent four-rune checkpoint oracle

The source body is `ᚳᚻ ᛇᛒ\n`, with a literal LF after `ᛒ`. The published
Gematria Primus order places those runes at indices 5, 8, 12, 17. This note
uses integer subtraction and a separate Python 3 `hashlib.sha256` invocation;
no Primus parser, transformation, runner, or printer generated the answers.

| Capture | Indices | Exact bytes rendered as text | UTF-8 bytes | SHA-256 |
| --- | --- | --- | ---: | --- |
| original | 5, 8, 12, 17 | `ᚳᚻ ᛇᛒ\n` | 14 | `5f80eab25d255b791df82f22560a8319c4d38a18296d8ef2304caf7ae506419b` |
| first | 4, 8, 10, 13 | `ᚱᚻ ᛁᛈ\n` | 14 | `9e2738c5fb38ea75df0825f3711630c266e9f085e60a754c75a51491fdb20927` |
| second | 2, 4, 10, 7 | `ᚦᚱ ᛁᚹ\n` | 14 | `fc4e037896f6364deed05acba06439355833e7fd3eacb6d08f008c061c677495` |
| letters | 2, 4, 10, 7 | `thr iw` | 6 | `026488a6a5365ca402a28c3821ebca0e470d08440059908fd4388ddc8c1c5ed3` |

First layer subtracts `(1, 0, 2, 4)` using primes 2, 3, 5 and skip ordinal
1. Second layer begins anew at prime 3 and subtracts `(2, 4, 0, 6)` using
primes 3, 5, 7 and skip ordinal 2. The skipped rune consumes no prime.
The original LF survives both rune layers and the terminal compatibility
rendering omits it. The final `th` is one GP token with a two-byte Latin span.

Original rune source spans in bytes are `[0,3)`, `[3,6)`, `[7,10)`,
`[10,13)`; character spans are `[0,1)`, `[1,2)`, `[3,4)`, `[4,5)`.
All four source rune indices are 0 through 3, line is zero, columns are
0, 1, 3, 4, page occurrence is zero, and page number is 99.
