# Final plan: Liber Primus page 55 and pages 54–55

## Goal and status

Develop and test a bounded set of explanations for page 55, treating pages 54–55 as a possible shared decoding unit. Prioritize self-reference and reversal hypotheses motivated by the user's observations and reported historical mechanisms.

This plan records the agreed research direction and code requirements. The first implementation milestone is one reproducible, explicitly configured deciphering chain with trustworthy hash checkpoints. No implementation or search has been completed under this plan. Open research parameters remain explicit; a completed experiment need not produce a decipherment.

## Evidence and motivation

- [2012 account, before “The Phone Number”](../research/what-happened-2012-before-phone-number.md): a reported Vigenère key was supplied externally through a subreddit clue and also derived from initials in the plaintext. The displayed eight line initials match its prefix; complete correspondence remains to be verified.
- [2014 account](../research/what-happened-part-1-2014.md): reported internal plaintext reuse as key material provides a related precedent.
- [Post-2014 account](../research/what-happened-liber-primus-post-2014.md): corpus and solver context; source interpretations remain attributed claims.
- [2016 message](../research/2016-message.md): paired tree/cicada motifs motivate prioritizing page 55. Their exchanged vertical positions may suggest reversal but do not specify a cipher operation.
- Local transcriptions contain **232 runes on page 54**, **76 on page 55**, **308 combined**. These counts are observations of the current YAML, pending a complete image-to-transcription audit.
- Matching margins, a red opening on 54, and a closing mark on 55 suggest a possible common section. They do not prove shared cipher state.

The user's broader interpretation connects self-reliance, self-reference, koans, internal key reuse, Atbash, reversals, and 3301/1033. This motivates experiment selection; it does not independently identify a mechanism. The proposed title callback from “first book” to the 2012 book is another hypothesis.

## 1. Establish faithful inputs

Compare [54.jpg](../../data/encoded/liber_primus/images/54.jpg) and [55.jpg](../../data/encoded/liber_primus/images/55.jpg) with their [page 54](../../data/encoded/liber_primus/page_54.yml) and [page 55](../../data/encoded/liber_primus/page_55.yml) transcriptions.

Record rune identity, punctuation, word separators, physical line boundaries, color, and page boundaries without silently normalizing them. Distinguish physical line wraps from linguistic boundaries. Assign stable source positions so every transformed rune can be traced back to the image. Mark ambiguous readings and test them as named alternatives.

Keep observation, historical source claim, and project interpretation in separate fields. Use repository filenames 54 and 55 consistently to avoid numbering-system confusion.

## 2. Verify controls and transformation semantics

Before interpreting search results, reproduce relevant known solutions using the existing feature examples in `spec/features/decode_a_page_spec.rb`: Atbash, Vigenère, and the page-56 prime-based shift. Check skip positions, key consumption, resets, alphabet indexing, and modulus against the intended mechanism.

For a 2012 control, first obtain the original encrypted posts and correctly formatted plaintext. Reproduce the 23-symbol key conversion, the full line-initial correspondence, and post-level resets. Keep its Latin alphabet and formatting conventions separate from the Liber Primus rune alphabet. Do not assume the existing reversal API implements every proposed spatial or textual reversal.

## 3. Compare decoding units explicitly

| Configuration | Input | Cipher state at page boundary |
| --- | --- | --- |
| A | Page 55 | Starts at page 55 |
| B | Page 54 followed by 55 | Continues across boundary |
| C | Page 54 followed by 55 | Resets at page 55 |

Use page 54 alone as a diagnostic where helpful. Reversing the entire combined stream and exchanging the pages while preserving their internal order are distinct operations. A page-order swap is a secondary hypothesis, not an implicit meaning of “reverse.”

For any self-derived key, also specify its source: page 55, page 54, or the pair. Shared extraction does not automatically imply continuous cipher state, and vice versa.

## 4. First-round key families

### 4.1 Keys from already available corpus plaintext

Create a short, versioned list of passages with a stated reason for inclusion. Prioritize historically reused passages and text specifically connected to the self-reference interpretation. Record exact rune encoding; Latin strings with multiletter rune equivalents cannot simply be split into letters without an explicit policy.

Do not expand to arbitrary substrings of the entire corpus initially. Record each candidate's source and boundaries before evaluating its output.

### 4.2 Keys derived from the target plaintext itself

Promote this family into the first round because of the 2012 precedent. Start with a **repeating key extracted from plaintext line initials**, not an assumption of conventional autokey.

For a chosen extraction rule E and decryption operation D, seek candidates satisfying:

```text
P = D(C, K)
K = E(P)
```

Here C is the fixed ciphertext, P the candidate plaintext, and K the repeating key. In the rune experiment, define “initial” as the first rune of the selected line, not the first Latin character of a transliteration.

Physical-line counts in the current transcriptions are 11 for page 54, 4 for page 55, and 15 for the pair. Taking one initial per physical line would therefore imply candidate key lengths 11, 4, and 15 respectively. These lengths follow from this extraction hypothesis; they are not discoveries about the actual cipher.

Test line-initial extraction in normal source order first. A reversed extraction order is a separately logged variant. Preserve physical source-line membership even if the reading stream is reversed; define explicitly which end supplies the initial. Word initials, final runes, and other selections belong to later named families.

Prefer solving the resulting modular constraints or pruning inconsistent assignments before broad enumeration. A fixed-point match is necessary under this hypothesis but not sufficient evidence of intended plaintext: accidental or underconstrained solutions may exist.

### 4.3 Bounded 2012 callback candidates

Treat these as separate alternatives:

- Reuse of the reported 2012 key.
- Reuse of the opening Mabinogion passage or its initials.
- Reuse of the extraction mechanism with new Liber Primus content.

The third is covered above. Testing the first two requires an explicit Latin-to-rune encoding policy and, for passage-based keys, a verified source/layout. “First book” motivates this small family without establishing any one member.

### 4.4 Deferred families

Cross-page ciphertext-derived keys and conventional plaintext/ciphertext autokey remain in scope for later research. Specify alignment, seed, extension, cycling, and resets before running them. Do not mix them into the first round as undocumented variations of self-reference.

## 5. Reversal and reflection variants

Distinguish alphabet reflection (Atbash), reversal of the rune stream, reversal of the key, and reversal of page order. Record whether reflection applies to input, key, or output, and in what order operations occur. Maintain a mapping back to original punctuation and boundaries.

Begin with a small explicit matrix of ordinary/reversed rune order and ordinary/reversed key order, with Atbash variants justified individually. Remove mathematically equivalent combinations so repeated results do not appear to be independent evidence.

Defer line-by-line reversal, geometric routes, arbitrary shifts of alignment, and four-operation constructions inspired solely by “do four unreasonable things” until a specific rule or observation motivates them.

## 6. Evaluate evidence

Rank full passages using rune-aware language measures, word-boundary plausibility, and coherent grammar/meaning. Do not treat isolated English-looking fragments in 76 runes as a solution. Keep raw outputs, not only high scores or attractive excerpts.

Compare leading results with controls under the same search procedure, such as shuffled inputs preserving relevant lengths and separators. Report the number of candidates searched and the flexibility used. Prefer explanations requiring fewer exceptions. Do not change extraction rules after seeing output without registering a new experiment.

For self-derived candidates, require exact key/extraction agreement and re-encryption back to the original ciphertext. These demonstrate internal consistency, not historical intent. Use additional text or a neighboring page as a check when the hypothesis genuinely predicts it; do not force every standalone-page hypothesis to explain page 54.

## 7. Hash as a possible confirmation mechanism

The user proposes that the page-56 deep-web hash could identify the original plaintext of a Liber Primus page. Preserve this as an unconfirmed target interpretation. A 128-hex-character value does not by itself establish the hash algorithm.

Check the original input and every deciphering checkpoint against a small declared serialization list: rune or transliterated text, case, separators, line endings, encoding, and final newline. Record the algorithm and exact bytes for every test. A match would be strong evidence about those bytes; a mismatch rejects only the tested algorithm/representation combination. Hash output provides no useful measure of closeness and should not drive the language search.

## 8. Experiment record and research milestone

Every run should retain input version/digest, source positions, decoding unit, alphabet, key source or extraction rule, operation order, key alignment/reset/skip policies, search bounds, raw output, scores, consistency checks, and interpretation. Preserve negative results to prevent repeated searches.

The initial research campaign is complete when:

1. Both transcriptions and relevant visual boundaries have been audited.
2. Relevant known-solution controls pass, with unresolved source limitations stated.
3. A finite first-round matrix and resource cap are recorded before execution.
4. Corpus-key and line-initial self-derived-key families have been compared across A/B/C, or a precise blocker has been documented.
5. Results include reproducible configurations, negative findings, and a reasoned next decision.

Do not require a decipherment to declare an experiment complete. Do not claim a hypothesis disproved beyond the parameter space actually tested.

## Open decisions before implementation or search

- Exact corpus-derived key shortlist and any 2012 artifact retrieval needed.
- Whether the first self-derived experiment uses page-55 initials alone, pair-wide initials, or both; how key source relates to state resets.
- Exact Atbash compositions, reversal boundary policies, and key-encoding conventions.
- Runtime/candidate cap and language-ranking method. No expensive or unbounded search is authorized by this document alone.
- Exact implementation interfaces and selection of an original BLAKE-512 dependency; the required capabilities and delivery order are specified below.

## Out of scope for this milestone

A whole-corpus brute-force campaign; assumptions that pages 54–55 must resolve together; treating the 2016 imagery as a proven reversal instruction; downstream 2012 stages beginning with “The Phone Number”; and publishing, committing, or pushing results without the applicable authorization.


## 9. Layered decoding and self-reference

The known controls motivate testing chains without establishing a numerical progression:

| Page or experiment | Conceptual decoding stages |
| --- | --- |
| Page 57 | Gematria Primus transliteration |
| Page 56 | Undo successive prime-totient shifts, then transliterate |
| Next section: two stages | One cipher reversal, then transliteration |
| Next section: three stages | Two cipher reversals, then transliteration |

Page 57's language about shedding circumferences and finding divinity within motivates the possibility of successive enclosing layers. The earlier passage declaring primes and the totient function sacred motivates choosing operations from corpus clues. Neither interpretation determines the next algorithm or proves multiple cipher layers.

Page 56's unchanged rune occupies zero-based rune index 56 (the 57th rune) on `56.jpg`. This may further support the broader self-reference thesis. Verify original numbering and counting before assigning significance. It does not establish a universal page-index skip rule; page 57 has no comparable cipher exception. Keep skipping as an optional, separately motivated experiment rather than the expected next mechanism.

Use one-, two-, and three-stage cases initially, with deeper chains deferred rather than ruled out. Hash checks do not count as decoding layers. Intermediate ciphertext need not resemble English and a hash mismatch must not terminate its chain. Repeated operations are permitted, but cancellations and equivalent paths should not consume redundant search work.

Internally, existing code translates parsed runes into Gematria Primus tokens before arithmetic. These tokens carry rune, letter, and index representations. That internal conversion must not introduce a fictitious extra encryption layer into experiment reports.

## 10. Hash target and algorithm selection

The research transcription and decoded page-56 YAML agree on:

```text
36367763ab73783c7af284446c59466b4cd653239a311cb7116d4618dee09a8425893dc7500b464fdaf1672d7bef5e891c6e2274568926a49fb4f45132c2a8b4
```

It contains 128 hexadecimal characters representing **64 bytes / 512 bits**. The ASCII hexadecimal representation itself occupies 128 bytes. Verify the transcription against the original page before treating it as authoritative. Digest length does not identify an algorithm or reveal input length.

First-round algorithms:

- **Original BLAKE-512**, final 2010 variant. The William Blake artwork provides a thematic reason to prioritize it, not proof of use. See the [designer's specification and reference implementation](https://www.aumasson.jp/blake/).
- **BLAKE2b with 64-byte output**, ordinarily unkeyed with default parameters. Available before 2014; distinct from original BLAKE-512. See the [project](https://www.blake2.net/) and [RFC 7693](https://www.rfc-editor.org/rfc/rfc7693.html).
- **SHA-512**, as a baseline compatible digest. See [FIPS 180-4](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf).

Use identical candidate bytes for algorithm comparisons. Keyed/salted variants are not implicit. Verify each implementation against independent published vectors, including empty and multi-block inputs. A 64-byte output alone is not a correctness check.

Ruby's standard `Digest::SHA512` supplies SHA-512. BLAKE2b availability through `OpenSSL::Digest` depends on the linked library. Original BLAKE-512 requires a separate verified implementation or binding. See [Ruby Digest](https://docs.ruby-lang.org/en/2.7.0/Digest.html) and [OpenSSL BLAKE2](https://docs.openssl.org/3.1/man7/EVP_MD-BLAKE2/).

The repository specifies Ruby 2.7.4; the inspected tool shell instead ran Ruby 2.6.10 with LibreSSL 3.3.6 and lacked BLAKE2b. Establish the actual project runtime before choosing dependencies. An unavailable algorithm is an error/unsupported result, never a mismatch.

## 11. Implementation approach: constituent parts

Extend the existing document visitors and sequential CLI foundation. Static inspection found localized correctness gaps, not evidence that a separate architectural refactor must precede this work. Proposed responsibilities below need not map one-to-one to new classes.

| Responsibility | Existing foundation | Required behavior |
| --- | --- | --- |
| Candidate and provenance | Document, tokens, lexer, builder, locations | Preserve exact source separately from parsed tokens; retain page identity, physical boundaries, original positions, and transformation history |
| Operation specification | CipherFactory and document visitors | Independent operation, key, direction, skip and reset parameters per stage; validate symbol representation and supported options |
| Cipher state | Decoder counter and key enumerators | Fresh state per attempt and layer; explicit continuation/reset across page boundaries; preserve the page-56 pause semantics |
| Serialization and hash checking | Printer; no integrated hash checker | Named, explicit byte policies; three verified algorithms; distinguish match, mismatch, unavailable, and execution error |
| Deterministic chain runner | Sequential `decode` in `bin/primus` | Observe original and each stage; keep immutable or isolated snapshots; hash without mutating the next stage's input |
| Key sources and consistency | KeyFinder and GP alphabet | Explicit keys, selected corpus passages, line-initial extraction, and exact candidate/key consistency checks |
| Experiment generator | Some exploratory brute-force code | Later bounded enumeration of chains, keys, page configurations and depth; cycle detection and safe deduplication |
| Record/replay and evaluation | Existing IC/ngram utilities and known-solution specs | Machine-readable records, exact candidate artifacts, replay, bounds/errors, and language ranking that does not discard encrypted intermediates |

### Existing files and concrete gaps to address

- `bin/primus`: current sequential decoding shares one key/skip option across all stages and prints only the final result. Keep CLI orchestration thin; expose a callable runner for scripts.
- `lib/primus/document/cipher_factory.rb`: unconditionally assigns `skip_sequence`, but Atbash's Affine superclass lacks that setter. Verify and correct supported operation dispatch.
- `lib/primus/document/vigenere.rb`: stores direction but always subtracts; String keys split into individual characters rather than GP symbols. Validate supported directions and use explicit, unambiguous symbol encoding.
- `lib/primus/document/decoder.rb` and `totient_shift.rb`: preserve independently initialized stream state and the known skip-without-key-consumption behavior.
- `lib/primus/document/affine.rb` and `totient_shift.rb`: new output tokens currently lose location metadata. Preserve provenance across supported transformations.
- `lib/primus/token/location.rb` and `document/builder.rb`: locations lack page identity and chapter assembly introduces line breaks. Represent original page boundaries separately from presentation choices.
- `lib/primus/liber_primus/page.rb` and `document/printer.rb`: both strip trailing whitespace. Keep a separate exact source/serialization path rather than treating their rendered output as original bytes.
- `lib/primus/document.rb` and `document/word_reverser.rb`: existing reversal includes nested structure and delimiters. Define and test the chosen reversal semantics explicitly.
- `spec/features/decode_a_page_spec.rb`: use existing page 56/57 and other solutions as controls for the new runner, not just isolated decoder behavior.

Do not reuse the unfinished `Brute#crib` command as the chain orchestrator. Avoid introducing a general plugin framework, distributed executor, or database before a concrete need emerges.

## 12. Acceptance criteria for the first implementation milestone

- A Ruby caller can supply one finite, explicit chain whose stages have independent parameters; the CLI can invoke the same behavior.
- The runner records the original candidate and every intermediate output, including exact hash-input bytes or a lossless artifact reference and serialization policy.
- SHA-512, BLAKE2b-512, and original BLAKE-512 pass independent known vectors in the supported project runtime. Missing support is clearly reported, never silently substituted.
- Hashing does not mutate candidate data, affect cipher state, count as a deciphering stage, or stop continuation on a mismatch. A match records its exact path and bytes; any stop-on-match policy is explicit.
- Repeating a run produces identical candidates and digests. Running a different attempt between repetitions does not leak key or prime-stream state.
- Every supported operation preserves provenance or explicitly records a defined mapping. Original source positions and current processing positions remain distinguishable after reversal.
- Page 57 reproduces the stored rune-to-letter result; page 56 reproduces the stored result with rune index 56 unchanged and the next prime-stream value left unconsumed at that position.
- A synthetic example with two independently configured cipher reversals reproduces a fixed expected plaintext and independently known intermediate results, demonstrating a three-stage conceptual chain including transliteration.
- Named serialization policies distinguish trailing-newline, separator, case, and rune/Latin variants without silently changing the underlying candidate.
- Structured results distinguish match, mismatch, unsupported algorithm, invalid configuration, and operation failure. Failed stages cannot masquerade as valid partial solutions.
- Saved records contain input identity, page order, alphabet, operation sequence, key encoding, skip/reset policy, serializer and algorithm versions, and exact artifacts sufficient for replay.

No page-55 decipherment is required to complete this software milestone. The 2012 original-artifact retrieval is needed for the later self-derived-key control, not a blocker for the initial runner.

## 13. Delivery sequence

1. **Explicit chain and hash checkpoints:** establish runtime/dependencies; preserve inputs and provenance; implement independent operation configuration, serialization, verified hash adapters, and structured record/replay. Address relevant existing correctness gaps through focused tests.
2. **Known and layered controls:** complete the first milestone with pages 57/56 and the synthetic two-cipher example before interpreting any new search output.
3. **Key sources and self-consistency:** add the justified corpus shortlist, explicit GP encoding, and line-initial consistency checks. Keep finding a self-consistent key separate from checking a supplied candidate.
4. **Bounded experiment generation:** compare configurations A/B/C, one-to-three-stage chains, specified reversals and keys. Set concrete candidate/runtime/storage caps before execution.
5. **Improved ranking and constraint search:** add only where initial experiments justify it; preserve encrypted intermediate states and negative results.

Candidate deduplication must account for representation, source boundaries, relevant continuation state, and remaining allowed work. Equal rendered text alone does not prove two candidates have identical future behavior. Preserve alternative histories when they matter to interpretation.

## 14. Edge cases and remaining implementation decisions

Test empty input, non-rune punctuation, multi-character transliterations, ambiguous/invalid keys, newline variants, page-boundary resets, skip positions after reversal, repeated stateful stages, unavailable hash support, operation failures, and chains returning to an earlier state. Reject unsupported options rather than ignoring them.

Resolve during detailed implementation planning: the original BLAKE-512 dependency and version, precise supported Ruby/OpenSSL environment, initial serializer names/policies, chain configuration format, record/artifact storage format, and match-stop behavior. None changes the agreed first milestone. Research key lists, broader operation combinations, and search budgets remain separate open choices.

## 15. Out of scope for the initial software delivery

Automated large searches, probabilistic pruning of encrypted intermediates, a general-purpose cryptanalysis framework, arbitrary skip-combination searches, proving the self-reference thesis, or assuming the target must hash plaintext. No repository push is part of this plan.
