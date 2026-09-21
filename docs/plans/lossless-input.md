# Lossless source reading and optional segmentation

Branch: `codex/lossless-input`, based on local `main` at `ac25910` to include the committed research plan.

## Goal

Read encrypted transcriptions into an ordered, lossless source representation, preserving page identity and positions independently of any interpretation of punctuation as words or sentences. Keep existing known decoding results available through an explicit compatibility view.

This is a prerequisite to the decoding-chain milestone in [the page 54–55 research plan](page-54-55-research.md). It includes intentional input-preservation fixes as well as restructuring; it is not a purely behavior-preserving refactor. This plan is ready for discussion of test expectations; no test-writer handoff, implementation, or experiments are authorized by the document alone.

## Acceptance criteria

- Loading a YAML page preserves the original file bytes separately from the `body` string returned by YAML parsing. No trimming, case folding, or newline normalization is applied to that extracted body by project code. YAML scalar folding/chomping remains YAML behavior, not something the lexer reverses.
- Rejoining each page's source token lexemes reproduces its extracted body byte-for-byte. Tokens cover its characters exactly once, in order, without omissions or overlaps.
- Source tokenization preserves runes, Latin text and case, punctuation, quotes, spaces, tabs, and line endings. Recognized two-character punctuation is consumed together only when the complete pair matches. A lone `᛫` or `᛬`, including one before a rune or at EOF, cannot consume that rune or disappear.
- Unsupported but valid text is retained as an explicitly unrecognized source token. Transliteration or a language view may reject unsupported symbols explicitly; the source reader does not silently discard them. Invalid encoding and missing/non-string YAML bodies produce a clear input error.
- Every source token, including punctuation and whitespace, records page occurrence identity, page-relative byte and character span, and physical line/column. Recognized GP runes additionally have a zero-based page-local rune index. Character offsets, byte offsets, rune indices, and legacy cipher positions are distinct concepts.
- Multiple pages retain their order and explicit boundaries without inserting characters into their source bodies. An empty page and repeated occurrences of the same page remain distinguishable. Derived display separators have no fabricated source location.
- Words and sentences are optional derived views over tokens. Requesting or changing segmentation never rewrites, drops, or mutates the authoritative token sequence. The source API can be used without constructing `Word` or `Sentence` objects.
- Existing punctuation-based grouping is available as a named compatibility policy. Its current comma-as-sentence rule and cross-line/cross-page word continuation are explicit interpretations, not universal lexer rules. Generic punctuation remains represented, even where earlier parsing lost it.
- Exact source reconstruction is separate from the current normalized display renderer. Existing display trimming and Latin rendering can remain in the compatibility API; neither is advertised as exact source output.
- Existing seven known decoding examples retain their established rendered plaintext. Fixed input examples additionally verify that preservation repairs do not move GP rune indices or consume cipher state at non-rune tokens. Page 56 still skips rune index 56 without consuming the next prime.
- The compatibility route preserves source references through translation and the cipher operations exercised by the known controls. A result cannot overwrite its source lexemes or another candidate's provenance. A real location does not compare equal to `nil`.

## Approach

### 1. Agree the behavioral contract before writing tests

Review the open questions and proposed test examples below with the user. Separate compatibility assertions from intentional changes: preserving formerly discarded punctuation, retaining trailing whitespace and original case in source, fixing partial-pair consumption, and correcting location equality must not be mistaken for accidental regressions.

Inspect existing callers of `Primus.parse`, `LiberPrimus.page`, the page loader, lexer/token factories, builder, and printer. Record which public methods are display-oriented and which new methods expose source data. Avoid changing every consumer to a new model at once.

### 2. Capture the source independently of interpretation

Likely files: `lib/primus/page.rb`, `lib/primus/liber_primus/page.rb`, and small source/token value objects under `lib/primus/` following existing naming conventions.

Represent the original artifact, extracted body, page identity, and ordered source tokens separately. Preserve raw file bytes even though YAML decoding can produce a body with different line endings or scalar formatting. In-memory pages have source bodies and identities but no invented artifact bytes/path.

Use page-relative spans into the extracted body. Preserve an occurrence identifier when one page is included twice. Original source coordinates remain fixed; sequence order is derived by traversal, not by editing locations.

### 3. Separate lexical recognition from segmentation

Likely files: `lib/primus/lexer.rb`, `lib/primus/lexer/{factory,runic,latin}.rb`, `lib/primus/token/{runic,english,location,no_location,line_break}.rb`, and the new source-token representation.

Keep source lexemes verbatim. Attach recognized GP identity independently of raw spelling. For Latin input, existing GP digraph/trigraph interpretation belongs to a conversion/compatibility policy; lowercasing must not destroy its source lexeme. Identify complete punctuation pairs with bounded lookahead. Keep unknown valid characters as source data.

Give all source tokens spans. Keep legacy `track_delimiters` behavior only in compatibility position calculation; it must no longer disable source provenance. Define LF, CRLF, and lone CR line accounting explicitly, preserving their bytes.

### 4. Reduce document building to composition plus an optional view

Likely files: `lib/primus/document/builder.rb`, `lib/primus/parser.rb`, `lib/primus/document.rb`, `lib/primus/word.rb`, and `lib/primus/sentence.rb`.

Compose page sources through one path for zero, one, or many pages. Replace synthetic source newlines with explicit boundary records. Move the existing word/sentence rules behind the compatibility view, and retain generic marks there rather than dropping them. Keep cross-page word continuation available as an explicit compatibility choice; do not invent a mandatory linguistic break.

Expose a separately named full lexical stream and rune projection. Do not silently redefine the existing word-oriented `Document#tokens`: `NgramConverter` and other consumers depend on its shape and indexing. Existing erroneous parser counts are not compatibility guarantees.

Remove the unused `first_word` path and special EOF logic only as their responsibilities are replaced. Avoid introducing a configurable grammar framework: one documented compatibility policy and access to unsegmented source tokens are sufficient for this work.

### 5. Bridge existing rendering and known decoders

Likely files: `lib/primus/document/{printer,translator,decoder,totient_shift,affine}.rb`, GP token construction, and any concrete known-control path found to lose locations.

Expose exact source reconstruction separately from normalized output. Preserve existing CLI display conventions. Ensure new derived tokens retain source references without modifying shared alphabet entries or earlier objects. Limit cipher changes to compatibility and provenance needed by this input contract; unrelated direction, key, factory, and cipher-state bugs remain separate work.

### 6. Verify preservation and compatibility

Likely tests: existing lexer, parser, token/location, page and builder specs; `spec/features/decode_a_page_spec.rb`; focused source-reading examples in matching spec directories. Use fixed expected strings and offsets rather than generating expectations with the serializer or loader under test. Assert exact lengths and fields as well as bytes; existing `Sentence#==` prefix-comparison behavior makes object equality alone insufficient for preservation checks.

Proposed discussion examples (behaviors, not test implementations):

| Input or situation | Expected distinction |
| --- | --- |
| `ᚠ'ᚢ`, `ᚠ᛫᛬ᚢ`, `ᚠ᛫ᚢ` | Preserve every mark; the second rune always remains a rune. |
| `ᚠ,ᚢ` | Exact source unchanged; compatibility policy may derive two sentences. |
| `A,b;C` and mixed-case GP digraphs | Original case/marks survive; a separate Latin conversion can normalize for alphabet lookup. |
| Empty body, whitespace-only body, terminal mark | No phantom word, consumed neighbor, or lost final token. |
| Multiple trailing newlines, CRLF, tabs | Exact body reconstruction and independently specified physical coordinates. |
| Multibyte rune followed by ASCII | Byte offsets differ from character offsets; rune index excludes marks. |
| Two pages containing one rune each | Explicit page boundary; no source newline; compatibility view may display a separator. |
| Same page included twice | Distinct occurrences with identical page-local spans. |
| YAML literal/folded and chomped scalar forms | Preserve artifact bytes and the parsed body as two different representations. |
| Segmentation/rendering requested repeatedly | Original source tokens and locations remain unchanged. |
| Known page-56 decode | Exact exceptional rune identity/index and prime advancement preserved. |

After focused examples, run all existing known decoding controls and the full existing suite. Investigate changed expectations explicitly; do not update expected plaintext merely to make tests pass.

## Edge cases

- Zero input pages, empty pages between nonempty ones, and pages without a final newline.
- Consecutive punctuation, standalone punctuation prefixes, leading/trailing quotes, and text outside the GP alphabet.
- Rune-range Unicode characters that are not members of the selected GP alphabet: preserve the source, distinguish recognition from alphabet membership.
- Latin multiletter symbols spanning several source characters; do not call their positions rune indices until an explicit conversion defines that correspondence.
- Relative paths versus page identifiers, repeated pages, and in-memory strings without filenames.
- Shared token/alphabet objects and visitors that currently return or mutate objects in place.
- Legacy callers relying on delimiter positions or normalized `to_s`; source coordinates must not silently replace cipher counters.

## Out of scope

- Chain execution, hashing algorithms, hash serializers, experiment configuration, replay, scoring, search, or key solving.
- New skip/reset hypotheses, arbitrary reversal variants, and unrelated cipher bug fixes.
- Recovering image colors, artwork, or original visual layout absent from YAML.
- Editing corpus transcriptions or choosing a new linguistically correct sentence grammar.
- Replacing every document visitor, broad performance tuning, or introducing a generic parsing framework.
- Writing tests or handing work to the test-writer before the user discussion.

## Open questions

The proposed defaults below are explicit decisions for discussion, not confirmed external requirements.

1. **Public API:** Prefer additive source access and a compatibility document adapter, leaving current display-facing entry points recognizable. Agree exact method names and whether any existing loader method may change its return semantics before writing contract tests.
2. **Coordinates:** Propose zero-based byte/character offsets, rune indices, lines, and columns, with end-exclusive spans. CRLF is one physical break; lone CR is also a break. All are relative to the extracted body, not YAML-file coordinates.
3. **Unknown symbols:** Propose retaining valid unknown characters with an explicit token category and rejecting malformed encoding/body schema at the loader. Confirm desired diagnostics and accepted encodings; UTF-8 is the initial proposal.
4. **Segmentation:** Preserve current word/sentence rules as the compatibility policy, including page-boundary continuation, while keeping page boundaries available. Decide whether a second page-isolated view is needed now or deferred.
5. **Compatibility surface:** Establish which normalized CLI/`to_s` outputs must remain stable. Lossless source output intentionally differs from previously trimmed or punctuation-dropping output.
6. **Provenance through transformations:** This work covers translation and the known decoding-control paths. Broader propagation through every experimental visitor should be separately scoped if those callers require it now.

## Follow-up

Original request: “Next step, let's dig into the first bullet of the plan and outline the actual work that needs to be done to achieve that goal”. That bullet is the reproducible explicit deciphering chain with hash checkpoints in the existing research plan.

This prerequisite includes preservation fixes, not only a refactor. Treat its merge as the boundary before detailing the chain feature against the new input model.

Do not begin work on this until the refactor above has merged. Then invoke planner fresh with the request above — do not reuse this plan or branch.
