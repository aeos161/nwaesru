# Independent IC oracle for solved GP controls

Frozen at source revision `5c45d487d0ff62ded5f537eb2f3b90aee21a20a3`.
The adjacent JSON is a literal test oracle, not the production reference
packet. Source bytes and their SHA-256 digests are recorded in that file:
`data/encoded/liber_primus/page_56.yml`
(`05ef023a9165ed3300712bfacec538863e7e82b7a4b0327bde0abb9182e71e7e`)
and `data/encoded/liber_primus/page_57.yml`
(`c7055db0173e43eb231608812f5d52569e4c0817934b1a65427cebf332759fff`).
The canonical rune-to-letter map is `data/gematria_primus.yml`, SHA-256
`e1ab250b5eb17a454545c18440a8780fda4443fd58ea75a92139c89a9138909f`.

I extracted YAML `body` scalars with Ruby Psych, selected only characters in
the 29-rune GP alphabet, and counted their zero-based rune ordinals. I then
independently enumerated primes by trial division. For page 56, each rune
except ordinal 56 is shifted backward by prime minus one modulo 29; ordinal
56 is retained and consumes no prime. Page 57 uses the source runes directly.
The resulting GP-token strings are recorded literally in JSON. I expanded
each token through the canonical `letter` map, including `u`, `c`, `s`, `ng`,
`io`, and the other multi-letter mappings, then counted alphabet bins with
simple integer counting. This procedure did not call any Primus parser,
transformation, SymbolStatistics, or analyzer. It did not retokenize Latin
plaintext to infer rune identity.

As a separate check, the expanded letter streams agree with the existing
decoded plaintext fixtures after omitting punctuation, whitespace, and the
five page-56 hexadecimal passthrough lines. Those fixtures are
`spec/fixtures/experiments/page_56_expected.txt` (SHA-256
`be341e15b67a3363b429319e23fd8ef4d172b9aea879016402bdd477348e7868`)
and `spec/fixtures/experiments/page_57_expected.txt` (SHA-256
`2d450628c6431f9497a6709f5af25d3dad2aa509c31d99ec3a00b07a42eb9a39`).
This checks spelling and sequence only; the rune oracle comes from the
encoded GP source and shift rule.

| Control | Representation | N | Numerator / denominator | Reduced IC |
| --- | --- | ---: | ---: | ---: |
| page 56 | GP runes | 85 | 500/7140 | 25/357 |
| page 57 | GP runes | 95 | 560/8930 | 56/893 |
| page 56 | expanded Latin | 91 | 638/8190 | 319/4095 |
| page 57 | expanded Latin | 100 | 640/9900 | 32/495 |

The numerator in every row is `sum(c * (c - 1))` across the literal ordered
histogram; the denominator is `N * (N - 1)`. These references are only two
short solved GP-English controls. They do not define a universal English IC,
probability, or decryption score. The theoretical uniform benchmarks are
independently `1/29` for GP rune draws and `1/26` for uniform Latin letter
draws; canonical expansion of uniform runes does not yield uniform Latin.
