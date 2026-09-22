# Lossless transcription beneath the document model

Branch: `codex/lossless-input`, based on local `main` at `ac25910`.

## Goal

Introduce `Primus::Transcription` beneath `Primus::Document`: the lexer produces lossless source tokens, and the parser interprets those tokens as words and sentences.

The thin Transcription layer and unchanged Document public API are agreed decisions. This plan covers only lossless source capture and backwards-compatible Document construction. Transformation design is deferred to [its separate follow-on plan](transcription-transformations.md), including line projection. This prerequisite includes deliberate preservation bug fixes as well as restructuring; it is not purely behavior-preserving. No implementation or test-writer handoff has occurred.

## Acceptance criteria

### Source capture and lexical representation

- Preserve raw YAML artifact bytes separately from the extracted `body` string. Project code does not trim, lowercase, or normalize that body; YAML folding/chomping still applies during extraction.
- An original transcription reconstructs every page body exactly from ordered raw lexemes. Each source character is covered exactly once. The original artifact/body remain independently available.
- Every token retains its exact raw lexeme and original source location, including punctuation, whitespace, line endings, and unrecognized valid characters. Recognized pairs are matched completely before consuming a second character.
- Source locations identify the page occurrence and zero-based page-local, end-exclusive byte/character spans and physical line/column. Recognized GP runes additionally have a page-local rune index. These are independent of current traversal order and legacy cipher positions.
- Page composition introduces explicit boundary records, not newline characters. Empty pages and repeated occurrences of the same page remain identifiable.
- Line breaks and original physical line/column coordinates are captured by the lexer. No separate line projection or layout abstraction is required for this scope.

### Interpretation and compatibility

- Parser consumes a transcription and applies the existing runic/Latin punctuation conventions through a named compatibility policy. Transcription tokens do not claim to be words or sentences.
- Parsing and rendering leave the original transcription unchanged. A parser invocation creates a fresh Document, Word, and Sentence graph.
- Document public methods and return shapes stay unchanged: `tokens` remains word-oriented; `words`, `sentences`, `[]`, visitor entry points, and `reverse` retain their existing role. Full lexical access lives on Transcription. No operations are added to either model.
- Generic punctuation no longer disappears. The compatibility view retains it without silently adding it to the GP rune projection or consuming a cipher step.
- The seven existing decoding controls retain their established rendered plaintext. Page 56 still exempts rune index 56 without consuming the next prime. Compatibility positions continue to support existing skip and lookup behavior.
- Source references survive translation and existing cipher paths exercised by the known decoding controls. Fresh derived tokens do not mutate source tokens or alphabet entries. Real locations do not compare equal to `nil`.

## Approach

### 1. Add the source model and exact loading

Likely additions:

| File/class | Responsibility and proposed API |
| --- | --- |
| `lib/primus/transcription.rb` / `Primus::Transcription` | Hold ordered lexical content, page occurrences/boundaries, and source references. Expose read access and exact current-body reconstruction per page; compose pages without inventing characters. No line interpretation, operation methods, dispatch, registry, or history. |
| `lib/primus/transcription/token.rb` | Raw lexeme, lexical kind, and source location. Distinguish rune, Latin symbol, punctuation, whitespace, line break, and unrecognized text without word/sentence semantics. |
| `lib/primus/transcription/source_location.rb` | Original page occurrence, byte/character spans, line/column, optional GP rune index. Read-only source coordinates; not the legacy mutable processing location. |
| `lib/primus/transcription/page_boundary.rb` | Structural relation between page occurrences, including empty pages; contributes no source bytes. |

These filenames are concrete implementation targets; collapse a trivial helper into its owner if that keeps responsibilities clearer. Do not introduce a large class hierarchy merely to match the table.

Update `lib/primus/page.rb` and `lib/primus/liber_primus/page.rb` to retain `source_body`, artifact bytes, and optional source path. Keep existing display-facing `data`/`to_s` compatibility where required: LiberPrimus currently trims on open; the lexer must explicitly read `source_body`, never that legacy trimmed projection. In-memory `data:` supplies the source body and has no invented file artifact. Retain `.load_data`'s extracted-string return contract or delegate it to a small shared loader rather than reading the file twice.

Validate UTF-8 and YAML body type with contextual errors. Add requires in `lib/primus.rb` in dependency order. Raw artifact offsets are not inferred from body offsets.

### 2. Make the lexer produce Transcription

Update `lib/primus/lexer.rb`, `lexer/{factory,runic,latin}.rb` and their callers. `Lexer#tokenize` produces/exposes a `transcription`; internal callers migrate to it. Retain accessors only where an actual caller needs compatibility, not as an excuse to maintain two unrelated tokenization engines.

Runic recognition consumes `᛫᛬`/`᛬᛫` only when the complete pair matches. A standalone mark is punctuation, never a rune-prefix container. GP membership is explicit, not inferred from the entire Unicode rune range. Preserve valid unsupported symbols as unrecognized tokens.

For Latin input, recognize existing GP digraphs/trigraphs case-insensitively but retain original spelling as raw lexeme. The interpreted mapping key may be lowercase. This preserves current `ing`/`ae` recognition while avoiding destructive case conversion. Preserve the exact span of each recognized multi-character lexeme.

Track byte spans and character spans independently. CRLF is one line-break token covering two characters; LF and lone CR are also line breaks. No source tracking is disabled by `track_delimiters`; that option affects only compatibility positions.

### 3. Adapt parser and document construction

Update `lib/primus/parser.rb` to accept `transcription:` and apply one explicit compatibility policy, preferably `lib/primus/parser/compatibility.rb`. Existing token factories in `token/{runic,english}.rb` can be reused or narrowed as interpretation helpers: punctuation becomes a sentence delimiter here, not in the authoritative lexical model.

The policy supplies legacy `Primus::Token` objects with both a compatibility location and source reference. It preserves existing runic comma/full-stop/`᛭` sentence grouping and word delimiter conventions. Generic marks must be visited/rendered without becoming decodable letters. Choose their placement deliberately so preservation does not make `Document#tokens` silently include every punctuation mark.

The current parser can hold a newline inside a word. Preserve that compatibility when needed; it does not define physical lines. Fix EOF handling to flush pending text once, retain all input line breaks in the view before display normalization, and avoid phantom empty words/sentences. Remove unused `first_word` plumbing.

`Document::Builder` becomes load → lex each page → compose Transcription → parse. Expose its built transcription for callers needing source inspection. Single-page and multi-page builds share this path. `LiberPrimus.page`/`.chapter` still return Document. Repeated parsing creates fresh document graphs rather than mutating memoized views.

Recommended compatibility boundary rendering: reproduce the existing per-page `rstrip` plus one inter-page newline as a **view policy**, without changing Transcription. A trailing synthetic newline is unnecessary because final display already trims. This preserves known combined-page display results even when source YAML bodies include terminal newlines. A page boundary does not implicitly force a word or sentence break in this compatibility view. Synthetic view separators have no false source position.

### 4. Preserve existing consumers and provenance

`Primus.to_word` in `lib/primus.rb` currently feeds `lexer.tokens` directly to Translator. Adapt it through the same compatibility token projection; preserve `Primus.parse` return shapes and existing GP key interpretation. Avoid a second hidden parser path with different raw-token handling.

Inspect `Document::Translator`, GP token construction/arithmetic, `TotientShift`, and `Affine` for source-reference propagation on the known decoding paths. Keep raw source lexemes separate from mapped rune/letter values. Dictionary lookup must produce fresh derived tokens before location assignment; inspect actual lookup behavior rather than assume it returns shared instances.

Keep `Document::Printer#to_s` as normalized display. Exact rendering belongs to Transcription. Do not redefine `Document#tokens`: `NgramConverter` assumes a word-oriented GP-token sequence and indexes its items as GP symbols. Add regression coverage for that distinction rather than blindly forwarding all transcription tokens.

Correct `Token::Location#==` for nil and incompatible objects. New source-location equality compares complete source fields. Existing character/GP equality omits locations and `Sentence#==` can compare prefixes, so neither is sufficient to prove preservation.

### 5. Migration sequence and verification

1. Agree source-coordinate and compatibility-display defaults and test expectations below.
2. Add the source model, raw/extracted loading, and literal byte/span examples.
3. Migrate lexer output, then Parser/Builder and `Primus.to_word`, keeping Document interfaces stable.
4. Repair provenance propagation on known controls and run compatibility regressions.
5. Run focused specs, all seven known decoding examples, and the complete suite. Classify failures as intended preservation fixes or regressions; do not silently rewrite known plaintext expectations.

Source/test implementation and test-writer handoff remain subsequent actions, not work performed by this planning document.

## Detailed test plan

Use ordered `eq` comparisons for token sequences instead of existing `match_array` checks. Assert literal strings, token kinds, complete counts, and individual location fields; do not compute expected results with the same parser/renderer being tested. Fixtures for decoding expectations must be read independently of the modified loader. Existing LiberPrimus specs trim fixture content (including leading whitespace); new source round-trip assertions must never strip fixtures. Keep existing `Document#reverse` behavior and implementation role unchanged.

| Spec target | Required behaviors and independent examples |
| --- | --- |
| `spec/lib/primus/page_spec.rb`, `liber_primus/page_spec.rb` | Raw artifact versus body: literal YAML `body: \|` with `  A` and final LF yields body `A\n`; `\|-` yields `A`; `>` folds two ordinary lines into `A B\n`. Pin raw fixture bytes separately. Missing/non-string body and invalid UTF-8 fail clearly; in-memory page has no artifact. Legacy display may trim while source body does not. |
| New `transcription_spec.rb` | Ordered composition of pages `ᚠ` and `ᚢ` retains two bodies and one zero-byte boundary; no newline is invented. Empty middle page and duplicate page occurrences retain identities. Repeated parsing and display leave exact source bytes unchanged. |
| Existing `lexer_spec.rb`, `lexer/runic_spec.rb` | `ᚠ'ᚢ` → raw lexemes `[ᚠ, ', ᚢ]`; `ᚠ᛫᛬ᚢ` → `[ᚠ, ᛫᛬, ᚢ]`; `ᚠ᛫ᚢ` → `[ᚠ, ᛫, ᚢ]`; lone final `᛫` survives. Each second rune has rune index 1. Unknown `?` survives lexing rather than raising the old unknown-token error. |
| Existing `lexer/latin_spec.rb` | `A,b;C` round-trips exactly; old forced-lowercase expectation changes intentionally. `ThING` lexes raw `Th`, `ING` with independent lowercase mapping keys. Assert original character/byte spans for both symbols. |
| New `transcription/source_location_spec.rb` | For `ᚠ-ᚢ\r\nA`, spans are rune0 bytes `[0,3)`, chars `[0,1)`; hyphen `[3,4)`, `[1,2)`; rune1 `[4,7)`, `[2,3)`; CRLF `[7,9)`, `[3,5)`; A `[9,10)`, `[5,6)`, physical line 1 column 0. First/second runes have indices 0/1; others have no GP rune index. |
| Existing `parser_spec.rb` | Feed Transcription rather than fabricated language tokens. `ᚠ,ᚢ` has two sentences under runic compatibility policy; source stays unchanged. Apostrophes and pair marks remain renderable. Preserve documented word continuation across physical lines/boundaries without asserting lost punctuation as correct behavior. Terminal delimiters/newlines flush once. Reparse the same source twice into independent document graphs. |
| Existing `document/builder_spec.rb` | Replace mock-only call counts with source→document outcomes. Zero/one/many pages share behavior; source bodies have no added LF; compatibility rendering has intended separators. Repeated build/reparse is deterministic. |
| Existing `token/location_spec.rb`, translator/cipher specs | Non-nil location differs from nil; source reference survives translation and relevant shifts; changing derived token metadata does not alter another token/source/alphabet entry. Source coordinates remain distinct from compatibility positions, including combined pages and delimiter tracking. |
| Existing Document/ngram/Primus helper specs | Public return types, word-oriented `Document#tokens`, `Primus.parse`/`to_word` GP mapping, and ngram expectations remain intact. New full lexical token access lives on Transcription. |
| `spec/features/decode_a_page_spec.rb` | Seven existing plaintext controls with independently loaded fixed expectations; direct page-56 index-56 unchanged-rune assertion and following-prime assertion. |

## Edge cases

- Empty input, empty pages, repeated pages, missing final newline, and multiple final line breaks.
- CRLF as one token, lone CR, mixed newline styles, tabs, and whitespace-only lines.
- Multi-character punctuation/Latin lexemes remain atomic; Unicode codepoints outside GP remain source data.
- YAML source formatting is not body formatting; source body offsets never claim to identify raw YAML-file offsets.
- Source page-local indices and chapter-wide compatibility positions have distinct meanings.
- Source page identity versus page occurrence; no phantom source newline.
- Existing memoized Document views and mutable GP tokens: use fresh parsed/derived objects rather than mutating old graphs.

## Out of scope

- All Transformation work: operation interfaces/classes, reversal rules, external operation composition, layout projections, and transformation-specific tests. Those belong to the separate follow-on plan.
- Chain runner, checkpoints, history, registry, hashing, scoring, and key search.
- New cipher rules and unrelated cipher behavior fixes. Existing known-control provenance/compatibility remains in scope.
- Replacing Document public API, all visitors, or the language-analysis model.
- Image/color recovery, corpus edits, or declaring punctuation linguistically correct.
- Writing implementation/tests or invoking the test-writer during this planning step.

## Open questions

Agreed: Transcription is a thin ordered source model below Document; Parser is the interpretation boundary; Document public API remains unchanged. Transcription contains no operations, dispatch, registry, or history. Existing nested Document visitors remain. No line projection is introduced in this work.

Review these remaining semantics before freezing tests:

1. **Compatibility display:** Approve per-page trim plus one inter-page display LF as an explicit view policy to preserve prior output. Exact source access never uses that policy.
2. **Unknown text after lexing:** Recommend clear conversion errors when an unrecognized token is asked to become GP text, while lexical capture/reconstruction succeeds. Generic recognized punctuation passes through. Confirm desired strictness at this conversion boundary.
3. **Coordinates:** Recommend UTF-8, zero-based source coordinates/end-exclusive spans, CRLF and lone CR line-break treatment. Latin GP symbol ordinals are compatibility positions, not source rune indices.

Exact helper names can be refined by the implementer without changing these public behavioral commitments. Broader provenance fixes for experimental visitors outside known controls remain a later scope decision.

## Follow-up

This Transcription plan is the current implementation scope. After it is complete and merged, review [standalone transcription transformations](transcription-transformations.md) against the actual code with a fresh planner invocation before implementation or test-writer handoff. That separate document preserves agreed design and proposed semantics; it is not part of this branch's implementation acceptance criteria.

The [decoding-chain milestone](page-54-55-research.md) remains separate later work. Plan it against the completed source and operation APIs; do not implement chaining, hash checkpoints, or history here.
