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

## Independent symbol statistics

Count one symbol per rune and split each canonical Latin expansion into
letters. The four-rune control gives these nonzero bins; every unlisted bin
in the 29-rune or 26-letter alphabet is zero. These counts and fractions were
computed from the literal strings above, without Primus code.

| Capture | Rune bins | Latin bins | Rune N / distinct / raw IC | Latin N / distinct / raw IC |
| --- | --- | --- | --- | --- |
| original | ᚳ=1 ᚻ=1 ᛇ=1 ᛒ=1 | c=1 h=1 e=1 o=1 b=1 | 4 / 4 / 0/12 | 5 / 5 / 0/20 |
| first | ᚱ=1 ᚻ=1 ᛁ=1 ᛈ=1 | r=1 h=1 i=1 p=1 | 4 / 4 / 0/12 | 4 / 4 / 0/12 |
| second | ᚦ=1 ᚱ=1 ᛁ=1 ᚹ=1 | t=1 h=1 r=1 i=1 w=1 | 4 / 4 / 0/12 | 5 / 5 / 0/20 |
| letters/final | ᚦ=1 ᚱ=1 ᛁ=1 ᚹ=1 | t=1 h=1 r=1 i=1 w=1 | 4 / 4 / 0/12 | 5 / 5 / 0/20 |

Every nonzero relative frequency is 1/N for its representation.

## Independent nonzero-IC control

The source body is exactly `ᚦᚪᚦ`, without a delimiter. Its GP indices are
`(2,24,2)`. A totient layer starting at prime 2 and skipping ordinal 1
gives `(1,24,0)`, or `ᚢᚪᚠ`. A second layer starting at prime 3 and
skipping ordinal 2 gives `(28,20,0)`, or `ᛠᛚᚠ`. Latin compatibility
renders the terminal capture as `ealf`.

| Capture | Exact bytes rendered as text | UTF-8 bytes | SHA-256 |
| --- | --- | ---: | --- |
| original | `ᚦᚪᚦ` | 9 | `5fc92ec015c73fa3e783161d1ce47d59afcaed785c8845c2bcd55c3f24298754` |
| first | `ᚢᚪᚠ` | 9 | `699a4e1fcdec3ef65b8e8b812d155dd6fb53d8da907c013112150d9023a03006` |
| second | `ᛠᛚᚠ` | 9 | `3f86a0698234a23a7308cc0f9e92f426696976ff12dadbf50dcddc9be5daf564` |
| letters | `ealf` | 4 | `3cdd3c1d79ab397e93951466299f8e8f0cc7c63c7550402c1c6ea6c4069447cd` |

These byte lengths and digests were checked separately with Python 3's
UTF-8 encoder and `hashlib.sha256`, not production code. Original rune bins
are ᚦ=2 and ᚪ=1: N=3, distinct=2, numerator=2, denominator=6, raw IC=1/3;
their relative frequencies are 2/3 and 1/3. Original expanded Latin is
`thath`: t=2, h=2, a=1, N=5, distinct=3, numerator=4, denominator=20,
raw IC=1/5; relative frequencies are 2/5, 2/5 and 1/5. First is `uaf`:
three unique runes and three unique letters, each with numerator 0 and
denominator 6. Second/final has three unique runes (0/6) and `ealf` has
four unique letters (0/12). All unlisted bins are zero.
