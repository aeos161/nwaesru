# Lossless transcription beneath the document model

Branch: `codex/lossless-input`, based on local `main` at `ac25910`.

## Goal

Introduce `Primus::Transcription` beneath `Primus::Document`: the lexer produces lossless source tokens, and the parser interprets those tokens as words and sentences. Layout transformations return a new transcription that can be parsed into a fresh document without changing original source coordinates.

The thin Transcription layer, standalone Transformation interface, and unchanged Document public API are agreed decisions. A transformation owns its operation parameters and implements `call(transcription)`, returning a new Transcription without changing its input or source provenance. Operations compose externally; Transcription owns no reversal methods, dispatch, registry, or execution history. The exact reversal and boundary conventions below are recommendations for review before test writing. This prerequisite includes preservation bug fixes as well as restructuring; it is not purely behavior-preserving. It does not implement the [decoding-chain milestone](page-54-55-research.md).

## Acceptance criteria

### Source capture and lexical representation

- Preserve raw YAML artifact bytes separately from the extracted `body` string. Project code does not trim, lowercase, or normalize that body; YAML folding/chomping still applies during extraction.
- An original transcription reconstructs every page body exactly from ordered raw lexemes. Each source character is covered exactly once. A transformed transcription renders its new ordering; the original artifact/body remain independently available.
- Every token retains its exact raw lexeme and original source location, including punctuation, whitespace, line endings, and unrecognized valid characters. Recognized pairs are matched completely before consuming a second character.
- Source locations identify the page occurrence and zero-based page-local, end-exclusive byte/character spans and physical line/column. Recognized GP runes additionally have a page-local rune index. These are independent of current traversal order and legacy cipher positions.
- Page composition introduces explicit boundary records, not newline characters. Empty pages and repeated occurrences of the same page remain identifiable.
- A separate line projection derives physical lines from current token order and actual line-break tokens, independently within each page. Original line membership remains available from source locations after transformations.

### Interpretation and compatibility

- Parser consumes a transcription and applies the existing runic/Latin punctuation conventions through a named compatibility policy. Transcription tokens do not claim to be words or sentences.
- Parsing, rendering, and transformation leave the original transcription unchanged. A parser invocation creates a fresh Document, Word, and Sentence graph.
- Document public methods and return shapes stay unchanged: `tokens` remains word-oriented; `words`, `sentences`, `[]`, visitor entry points, and `reverse` retain their existing role. Full lexical access lives on Transcription; standalone transformation objects consume it. Neither model gains new reversal dispatch.
- Generic punctuation no longer disappears. The compatibility view retains it without silently adding it to the GP rune projection or consuming a cipher step.
- The seven existing decoding controls retain their established rendered plaintext. Page 56 still exempts rune index 56 without consuming the next prime. Compatibility positions continue to support existing skip and lookup behavior.
- Source references survive translation and transformations exercised by the known decoding controls. Fresh derived tokens do not mutate source tokens or alphabet entries. Real locations do not compare equal to `nil`.

### Layout transformations

- Provide standalone `ReverseLineOrder`, `ReverseTokensWithinLines`, and `ReverseEntireSequence` objects (illustrative names), each implementing `call(transcription)`. Each returns a new Transcription, preserves token identity/source locations, and supports parsing into a fresh Document.
- Each object owns its operation parameters and rules; external callers can pass one result into another operation. Repeated calls do not retain input-specific execution state. Transcription remains ordered content, page boundaries, and source references only; it has no transform methods, registry, dispatch, or history.
- Keep existing Document visitors for its nested word/sentence model. The flat transcription layer does not require a visitor, decorator, base class, or operation registration system to satisfy the Transformation interface.
- Their exact treatment of marks, multi-character lexemes, line endings, and page scope follows the reviewed contract below. None performs geometric glyph reflection, Atbash, or language-based word reversal.
- Token-within-line and entire-sequence reversal restore token order and rendered bytes when applied twice. Line-order reversal needs the empty-line/unterminated-line decision below resolved before promising this property for every input. Literal expected-output examples remain required.

## Approach

### 1. Add the source model and exact loading

Likely additions:

| File/class | Responsibility and proposed API |
| --- | --- |
| `lib/primus/transcription.rb` / `Primus::Transcription` | Hold ordered lexical content, page occurrences/boundaries, and source references. Expose read access and exact current-body reconstruction per page; compose pages without inventing characters. No line interpretation, operation methods, dispatch, registry, or history. |
| `lib/primus/transcription/token.rb` | Raw lexeme, lexical kind, and source location. Distinguish rune, Latin symbol, punctuation, whitespace, line break, and unrecognized text without word/sentence semantics. |
| `lib/primus/transcription/source_location.rb` | Original page occurrence, byte/character spans, line/column, optional GP rune index. Read-only source coordinates; not the legacy mutable processing location. |
| `lib/primus/transcription/page_boundary.rb` | Structural relation between page occurrences, including empty pages; contributes no source bytes. |
| `lib/primus/transcription/line_projection.rb` | Separate projection over a supplied transcription: derive current line-content groups and line-break references per page. Optional lightweight line values remain derived data, not fields on Transcription. |
| `lib/primus/transformations/reverse_line_order.rb` | Standalone `ReverseLineOrder#call(transcription)`; owns reviewed page/line ordering rules and any supported parameters. Uses the line projection. |
| `lib/primus/transformations/reverse_tokens_within_lines.rb` | Standalone `ReverseTokensWithinLines#call(transcription)`; reverses content within projected lines under reviewed rules. |
| `lib/primus/transformations/reverse_entire_sequence.rb` | Standalone `ReverseEntireSequence#call(transcription)`; reverses page-local token streams including line-break tokens. |

Transformation is a shared Ruby call contract, not a requirement for an inheritance hierarchy or abstract base file. Operations receive parameters at construction where needed and the transcription at call time. An external caller may evaluate `second.call(first.call(input))`; no pipeline or history owner is added here.

These filenames are concrete implementation targets; collapse a trivial helper into its owner if that keeps responsibilities clearer. Do not introduce a large class hierarchy merely to match the table.

Update `lib/primus/page.rb` and `lib/primus/liber_primus/page.rb` to retain `source_body`, artifact bytes, and optional source path. Keep existing display-facing `data`/`to_s` compatibility where required: LiberPrimus currently trims on open; the lexer must explicitly read `source_body`, never that legacy trimmed projection. In-memory `data:` supplies the source body and has no invented file artifact. Retain `.load_data`'s extracted-string return contract or delegate it to a small shared loader rather than reading the file twice.

Validate UTF-8 and YAML body type with contextual errors. Add requires in `lib/primus.rb` in dependency order. Raw artifact offsets are not inferred from body offsets.

### 2. Make the lexer produce Transcription

Update `lib/primus/lexer.rb`, `lexer/{factory,runic,latin}.rb` and their callers. `Lexer#tokenize` produces/exposes a `transcription`; internal callers migrate to it. Retain accessors only where an actual caller needs compatibility, not as an excuse to maintain two unrelated tokenization engines.

Runic recognition consumes `᛫᛬`/`᛬᛫` only when the complete pair matches. A standalone mark is punctuation, never a rune-prefix container. GP membership is explicit, not inferred from the entire Unicode rune range. Preserve valid unsupported symbols as unrecognized tokens.

For Latin input, recognize existing GP digraphs/trigraphs case-insensitively but retain original spelling as raw lexeme. The interpreted mapping key may be lowercase. This preserves current `ing`/`ae` recognition while avoiding destructive case conversion. One recognized multi-character lexeme remains one token under layout reversal; reversing characters inside it is not part of these operations.

Track byte spans and character spans independently. CRLF is one line-break token covering two characters; LF and lone CR are also line breaks. No source tracking is disabled by `track_delimiters`; that option affects only compatibility positions.

### 3. Adapt parser and document construction

Update `lib/primus/parser.rb` to accept `transcription:` and apply one explicit compatibility policy, preferably `lib/primus/parser/compatibility.rb`. Existing token factories in `token/{runic,english}.rb` can be reused or narrowed as interpretation helpers: punctuation becomes a sentence delimiter here, not in the authoritative lexical model.

The policy supplies legacy `Primus::Token` objects with both a compatibility location and source reference. It preserves existing runic comma/full-stop/`᛭` sentence grouping and word delimiter conventions. Generic marks must be visited/rendered without becoming decodable letters. Choose their placement deliberately so preservation does not make `Document#tokens` silently include every punctuation mark.

The current parser can hold a newline inside a word. Preserve that compatibility when needed; it does not define physical lines. Fix EOF handling to flush pending text once, retain all input line breaks in the view before display normalization, and avoid phantom empty words/sentences. Remove unused `first_word` plumbing.

`Document::Builder` becomes load → lex each page → compose Transcription → parse. Expose its built transcription for callers needing source/layout work. Single-page and multi-page builds share this path. `LiberPrimus.page`/`.chapter` still return Document. Layout work passes the transcription to a standalone transformation and explicitly invokes the parser on its result; it does not mutate an existing Document and its memoized views.

Recommended compatibility boundary rendering: reproduce the existing per-page `rstrip` plus one inter-page newline as a **view policy**, without changing Transcription. A trailing synthetic newline is unnecessary because final display already trims. This preserves known combined-page display results even when source YAML bodies include terminal newlines. A page boundary does not implicitly force a word or sentence break in this compatibility view. Synthetic view separators have no false source position.

### 4. Specify standalone transformations before implementing them

**Recommended initial scope:** operate independently within every page occurrence; preserve page order and boundary records. Do not expose a whole-chapter reversal yet. This prevents a reversal from silently reassigning text between pages or turning page boundaries into source text. A later explicitly named page-order operation can be added if research requires it.

**`ReverseTokensWithinLines#call`:** derive current lines; reverse all non-line-break tokens within each line, including whitespace and punctuation. Line-break tokens stay in their existing slots. No token's raw lexeme is reversed internally.

**`ReverseLineOrder#call`:** reverse line-content groups while leaving line-break tokens in their existing ordinal slots. Thus a final newline stays final, mixed newline styles keep their slot order, and an unterminated final line does not accidentally fuse with its neighbor. Source coordinates belong to tokens, so after rearrangement a line-break token need not share original line membership with its newly preceding contents.

Define line contents as follows: an empty page has zero lines; a newline-terminated page has no extra phantom line after the terminal break; consecutive breaks create empty content lines. For example, `A\n\n` has content groups `[A, empty]` and two breaks. An unterminated final nonempty group is a line. These conventions preserve tokens, but do not alone guarantee reversible line grouping: `\nA` reverses to `A\n`, whose reparsed line view no longer includes the formerly leading empty line. Resolve this in the separate line projection and transformation contract: one option is a uniform split convention that includes terminal empty content groups (changing ordinary terminal-newline reversal expectations); another is the illustrated byte-defined convention, which is non-involutive for this edge case. Do not add hidden line-slot metadata/history to Transcription or silently add a newline to fix it. The examples below are provisional under the illustrated convention until this choice is reviewed.

**`ReverseEntireSequence#call`:** reverse all lexical tokens within a page, including line-break tokens. A terminal newline becomes leading. CRLF and recognized punctuation/Latin n-grams remain atomic tokens. This is intentionally different from reversing line contents with separator slots fixed.

Example current body `ᚠ-ᚢ.\nᚦ,ᚩ\n`:

| Operation | Exact resulting body (`\n` denotes one LF) |
| --- | --- |
| `ReverseTokensWithinLines` | `.ᚢ-ᚠ\nᚩ,ᚦ\n` |
| `ReverseLineOrder` | `ᚦ,ᚩ\nᚠ-ᚢ.\n` |
| `ReverseEntireSequence` | `\nᚩ,ᚦ\n.ᚢ-ᚠ` |

Transform token sequences directly; do not render and re-lex, which could merge Latin symbols or lose original identities. Reparse the resulting transcription to recompute word/sentence structure. No operation promises sensible English punctuation.

### 5. Preserve existing consumers and provenance

`Primus.to_word` in `lib/primus.rb` currently feeds `lexer.tokens` directly to Translator. Adapt it through the same compatibility token projection; preserve `Primus.parse` return shapes and existing GP key interpretation. Avoid a second hidden parser path with different raw-token handling.

Inspect `Document::Translator`, GP token construction/arithmetic, `TotientShift`, and `Affine` for source-reference propagation on the known decoding paths. Keep raw source lexemes separate from mapped rune/letter values. Dictionary lookup must produce fresh derived tokens before location assignment; inspect actual lookup behavior rather than assume it returns shared instances.

Keep `Document::Printer#to_s` as normalized display. Exact rendering belongs to Transcription. Do not redefine `Document#tokens`: `NgramConverter` assumes a word-oriented GP-token sequence and indexes its items as GP symbols. Add regression coverage for that distinction rather than blindly forwarding all transcription tokens.

Correct `Token::Location#==` for nil and incompatible objects. New source-location equality compares complete source fields. Existing character/GP equality omits locations and `Sentence#==` can compare prefixes, so neither is sufficient to prove preservation.

### 6. Migration sequence and verification

1. Agree the reversal/boundary defaults and test expectations below.
2. Add the source model, raw/extracted loading, and literal byte/span examples.
3. Migrate lexer output, then Parser/Builder and `Primus.to_word`, keeping Document interfaces stable.
4. Add the separate line projection and standalone transformation objects, verify their shared call contract and external composition, then add fresh-document reparsing tests.
5. Repair provenance propagation on known controls and run compatibility regressions.
6. Run focused specs, all seven known decoding examples, and the complete suite. Classify failures as intended preservation fixes or regressions; do not silently rewrite known plaintext expectations.

Source/test implementation and test-writer handoff remain subsequent actions, not work performed by this planning document.

## Detailed test plan

Use ordered `eq` comparisons for token sequences instead of existing `match_array` checks. Assert literal strings, token kinds, complete counts, and individual location fields; do not compute expected results with the same parser/renderer being tested. Fixtures for decoding expectations must be read independently of the modified loader. Existing LiberPrimus specs trim fixture content (including leading whitespace); new source round-trip assertions must never strip fixtures. Existing WordReverser delegation assertions do not establish sequence semantics: new layout tests pin literal output and metadata, and `Document#reverse` is not silently rerouted to a different standalone transformation.

| Spec target | Required behaviors and independent examples |
| --- | --- |
| `spec/lib/primus/page_spec.rb`, `liber_primus/page_spec.rb` | Raw artifact versus body: literal YAML `body: |` with `  A` and final LF yields body `A\n`; `|-` yields `A`; `>` folds two ordinary lines into `A B\n`. Pin raw fixture bytes separately. Missing/non-string body and invalid UTF-8 fail clearly; in-memory page has no artifact. Legacy display may trim while source body does not. |
| New `transcription_spec.rb` | Ordered composition of pages `ᚠ` and `ᚢ` retains two bodies and one zero-byte boundary; no newline is invented. Empty middle page and duplicate page occurrences retain identities. Original and transformed rendering are distinct; source remains unchanged. |
| Existing `lexer_spec.rb`, `lexer/runic_spec.rb` | `ᚠ'ᚢ` → raw lexemes `[ᚠ, ', ᚢ]`; `ᚠ᛫᛬ᚢ` → `[ᚠ, ᛫᛬, ᚢ]`; `ᚠ᛫ᚢ` → `[ᚠ, ᛫, ᚢ]`; lone final `᛫` survives. Each second rune has rune index 1. Unknown `?` survives lexing rather than raising the old unknown-token error. |
| Existing `lexer/latin_spec.rb` | `A,b;C` round-trips exactly; old forced-lowercase expectation changes intentionally. `ThING` lexes raw `Th`, `ING` with independent lowercase mapping keys. A reversed token sequence is `INGTh`, not character-reversed `GNIhT`. |
| New `transcription/source_location_spec.rb` | For `ᚠ-ᚢ\r\nA`, spans are rune0 bytes `[0,3)`, chars `[0,1)`; hyphen `[3,4)`, `[1,2)`; rune1 `[4,7)`, `[2,3)`; CRLF `[7,9)`, `[3,5)`; A `[9,10)`, `[5,6)`, physical line 1 column 0. First/second runes have indices 0/1; others have no GP rune index. |
| New `transcription/line_projection_spec.rb` | Empty, `A`, `A\n`, `A\n\n`, `\n`, and mixed CRLF/LF cases pin exact content groups and break tokens. Physical lines do not depend on commas or word delimiters. |
| New `transformations/reverse_line_order_spec.rb`, `reverse_tokens_within_lines_spec.rb`, `reverse_entire_sequence_spec.rb` | Assert all three literal rune examples above. For `A\r\nB\nC`, line-order reversal → `C\r\nB\nA`; whole sequence → `C\nB\r\nA`. For `A\n\n`, line-order reversal → `\nA\n`. Include punctuation pairs, spaces, quotes, single/empty lines, and two pages. Pin page order and original token coordinates. Double reversal restores original token order/bytes for token reversal operations; include `\nA` as the unresolved line-order regression before claiming the same for every line layout. Parsing transformed output never mutates either transcription. |
| Shared transformation contract examples in transformation specs | Each `call(input)` returns a distinct Transcription with unchanged input bytes/order and original token source fields. Reuse the same operation on A, then B, then A; both A results agree. For `ᚠ-ᚢ.\nᚦ,ᚩ\n`, external within-line reversal followed by line-order reversal yields `ᚩ,ᚦ\n.ᚢ-ᚠ\n` under the provisional line convention. Pin the literal output and preservation fields; do not merely assert delegation. No history is attached to results. |
| Existing `parser_spec.rb` | Feed Transcription rather than fabricated language tokens. `ᚠ,ᚢ` has two sentences under runic compatibility policy; source stays unchanged. Apostrophes and pair marks remain renderable. Preserve documented word continuation across physical lines/boundaries without asserting lost punctuation as correct behavior. Terminal delimiters/newlines flush once. Reparse a reversed punctuation example into fresh grouping. |
| Existing `document/builder_spec.rb` | Replace mock-only call counts with source→document outcomes. Zero/one/many pages share behavior; source bodies have no added LF; compatibility rendering has intended separators. Repeated build/reparse is deterministic. |
| Existing `token/location_spec.rb`, translator/cipher specs | Non-nil location differs from nil; source reference survives translation and relevant shifts; changing derived token metadata does not alter another token/source/alphabet entry. Source index stays fixed after layout reversal; compatibility processing index reflects current traversal. |
| Existing Document/ngram/Primus helper specs | Public return types, word-oriented `Document#tokens`, `Primus.parse`/`to_word` GP mapping, and ngram expectations remain intact. New full lexical token access lives on Transcription. |
| `spec/features/decode_a_page_spec.rb` | Seven existing plaintext controls with independently loaded fixed expectations; direct page-56 index-56 unchanged-rune assertion and following-prime assertion. Add a small parse→layout-transform→reparse→translate example to connect the new layer without implementing a chain runner. |

## Edge cases

- Empty input, empty pages, repeated pages, missing final newline, and multiple final line breaks.
- CRLF as one token, lone CR, mixed newline styles, tabs, and whitespace-only lines.
- Multi-character punctuation/Latin lexemes remain atomic; Unicode codepoints outside GP remain source data.
- YAML source formatting is not body formatting; source body offsets never claim to identify raw YAML-file offsets.
- Reordered tokens can have nonmonotonic original source positions. Current processing counters must not use those positions as traversal order.
- Source page identity versus page occurrence; no phantom newline or arbitrary page-crossing transformation.
- Existing memoized Document views and mutable GP tokens: use fresh parsed/derived objects rather than mutating old graphs.

## Out of scope

- Chain runner, checkpointing, history, operation registries, hashing, search/scoring, serializers for candidate hash policies, and key solving. A future runner owns chain orchestration/history; this work only demonstrates ordinary external composition.
- Glyph reflection, Atbash-as-layout, arbitrary routes, page-order reversal, and whole-chapter reversal.
- New cipher skip/reset rules and unrelated cipher behavior fixes.
- Replacing Document public API, all visitors, or the existing language-analysis model.
- Image/color recovery, editing corpus transcriptions, or declaring punctuation linguistically correct.
- Writing implementation/tests or invoking the test-writer in this planning step.

## Open questions

Agreed: Transcription is a thin ordered source model below Document; Parser is the interpretation boundary; Document public API remains unchanged. Standalone transformations implement `call(transcription)`, return new Transcriptions, preserve input/provenance, and compose externally. Line projection is separate. Transcription contains no operation methods, dispatch, registry, or history. Existing nested Document visitors remain; a visitor/decorator is not imposed on the flat transcription. Results are explicitly reparsed when a Document view is needed.

Review these remaining semantics before freezing tests:

1. **Reversal boundaries:** Approve page-local scope, all-mark reversal, atomic multi-character tokens, fixed newline slots for line-order reversal, and newline movement for entire-sequence reversal. Resolve the leading-empty-line plus unterminated-last-line ambiguity (`\nA` → `A\n`) in the projection/operation contract before finalizing line reversal tests, without adding hidden layout state to Transcription. These are recommendations, not claims about the intended cipher.
2. **Compatibility display:** Approve per-page trim plus one inter-page display LF as an explicit view policy to preserve prior output. Exact source access never uses that policy.
3. **Unknown text after lexing:** Recommend clear conversion errors when an unrecognized token is asked to become GP text, while lexical capture/reversal/reconstruction succeeds. Generic recognized punctuation passes through. Confirm desired strictness at this conversion boundary.
4. **Coordinates:** Recommend UTF-8, zero-based source coordinates/end-exclusive spans, CRLF and lone CR line-break treatment. Latin GP symbol ordinals are compatibility positions, not source rune indices.

Exact helper names can be refined by the implementer without changing these public behavioral commitments. Broader provenance fixes for experimental visitors outside known controls remain a later scope decision.

## Follow-up

Original request: “Next step, let's dig into the first bullet of the plan and outline the actual work that needs to be done to achieve that goal”. That bullet is the reproducible explicit deciphering chain with hash checkpoints in the existing research plan.

This prerequisite includes preservation fixes, not only a refactor. Treat its merge as the boundary before detailing the chain feature against the new input model.

Do not begin work on this until the refactor above has merged. Then invoke planner fresh with the request above — do not reuse this plan or branch.
