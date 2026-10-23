# Warning Atbash control

The source is `data/encoded/liber_primus/page_warning.yml` at SHA-256
`86a0a2a4d68c2fff1af86d3e7aa62bec05eb46a2bdbc480d4243bcf282561718`.
The independently stored decoded source is
`data/decoded/liber_primus/page_warning.yml` at SHA-256
`d359714fdba2c8d3a557dd7c745659ffb1137cb58ce5844e28e830f0217c1d1f`.

The literal rune fixture was calculated outside the Primus parser, operations,
and renderer. Read the 29 ordered rune/Latin entries from
`data/gematria_primus.yml`; for each GP rune at index `i`, write the rune and
Latin label at index `28 - i`. Copy every other source character unchanged in
the rune fixture. In the Latin fixture, translate source hyphens into spaces
and apply the existing terminal `rstrip` rule once. All 184 rune substitutions
produced the complete decoded YAML body before that final trim, including its
nine physical lines and trailing newline. The decoded file is therefore a
real-page plaintext control, not an expected value calculated through the
operation under test.

Frozen fixture SHA-256 values:

* `warning_original_runes.txt`:
  `37f796ad978ef7300a34dca76c238955082db11315dcc5073cb09192190771be`
* `warning_atbash_runes.txt`:
  `bcebb8ea5cb8d1cf6902561c2b003147d366c9a31778313856941b21e9fde353`
* `warning_atbash_latin.txt`:
  `8d130adee72285dbde3a94576cba6a1492660286fcd764561bd1215b0f8d7222`

The Warning source identity is the string `warning`. It is not page zero.
The attributed historical account is in
`docs/research/what-happened-part-1-2014.md`, section 3.2. It corroborates
the method and English reading, but the local encoded/decoded pair is the
exact byte-level oracle used here.
