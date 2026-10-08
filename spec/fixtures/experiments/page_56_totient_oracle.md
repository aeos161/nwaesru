# Independent page-56 oracle packet (2026-10-08)

The plaintext bytes come from `data/decoded/liber_primus/page_56.yml` using
`Psych.safe_load(File.binread(path)).fetch("body").rstrip`. The frozen output
is byte-identical to `experiments/expected/page-56-totient-latin.txt` and
`spec/fixtures/experiments/page_56_expected.txt`: 255 UTF-8 bytes, no BOM and
no terminal LF. The source SHA-256 and all literal answers are in the adjacent
JSON fixture. The historical `spec/fixtures/files/page56_latin.txt` has
different trailing bytes and is not the frozen oracle.

Preparation used Python 3.14.8 `hashlib.sha512(bytes).hexdigest()` and
`hashlib.blake2b(bytes, digest_size=64).hexdigest()`, each checked against
standalone `openssl dgst -sha512` and `openssl dgst -blake2b512` over the same
frozen file. The original BLAKE-512 answer came from `@noble/hashes` 1.8.0
`blake512(bytes)`, using the cached package whose tarball SHA-256 is
`e8a765d92c04faaccba8776411c5038cb195f812ee629fce07e1d2e6aec80ea0`
and `src/blake1.ts` SHA-256 is
`bc232796e5e0811d81d96b120c41ef7166f9df2f5d5af516075be31571f6f586`.
That source is pinned at commit `32f700f38ec49d7e6b2ab687904d6b2d7d60d80a`.
`node ../blake512-ruby/research/verify_vectors.js /tmp/primus-totient-oracle/package`
passed all 13 literal vectors against both noble and the designer C source.
The same C CLI independently confirmed the page-56 BLAKE-512 value.

No Primus decoder or hash wrapper supplied an expected value. The three
128-character lowercase digests are literal fixture values and must remain
literal in the named control definition.
