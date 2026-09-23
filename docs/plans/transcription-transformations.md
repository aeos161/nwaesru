# Standalone transcription transformations

## Status and dependency

Follow-on design record requested separately by the user. Begin implementation only after [lossless Transcription and Document compatibility](lossless-input.md) are complete and merged. Invoke planner for a fresh review of the resulting code and resolve the open semantics before test-writer handoff. File/class names and tests below preserve the current proposals; they are not a claim that the prerequisite API already exists. No implementation or test-writer handoff has occurred.

## Goal

Provide standalone transformations over a Transcription without adding operations or execution history to the source model. A transformed result can be explicitly parsed into a fresh Document while retaining original source provenance.

## Acceptance criteria

- The agreed interface is `transformation.call(transcription)`: return a new Transcription, leave input unchanged, and preserve token identity, raw lexemes, source references and original coordinates.
- Each operation owns its parameters and rules. Calls have no retained input-specific state. Operations compose externally, for example `second.call(first.call(input))`.
- Transcription remains a thin ordered content/page boundary/source-reference model; no reversal methods, dispatch, registry, line-slot history, or chain history are added.
- Keep existing Document visitors for the nested model. Do not force a visitor, decorator, or inheritance hierarchy on flat source transformations. Document public API and existing `reverse` are unchanged.
- Implement named standalone line-order, within-line token, and entire-sequence reversal operations under reviewed semantics. Names below are illustrative.
- Token-within-line and entire-sequence reversal applied twice restore token order and bytes. Do not claim line-order involution until the empty/unterminated-line ambiguity below is resolved.
- Reparse results explicitly to obtain fresh word/sentence views. Never render and re-lex to transform tokens; that can merge symbols and destroy provenance.

## Approach

### Production code proposals

| Proposed file/class | Responsibility |
| --- | --- |
| `lib/primus/transcription/line_projection.rb` | Separate read-only projection of current line-content groups and break references, per page. Original line coordinates remain distinct. No projection state is stored on Transcription. |
| `lib/primus/transformations/reverse_line_order.rb` | `ReverseLineOrder#call(transcription)` owns reviewed page/line ordering rules and supported parameters. Uses line projection. |
| `lib/primus/transformations/reverse_tokens_within_lines.rb` | `ReverseTokensWithinLines#call(transcription)` reverses content within projected lines. |
| `lib/primus/transformations/reverse_entire_sequence.rb` | `ReverseEntireSequence#call(transcription)` reverses page-local lexical tokens including line-break tokens. |

Use a shared Ruby call contract rather than an obligatory abstract base class. Parameters belong on operation construction, input on `call`. Recheck actual prerequisite constructors, token ownership, exact reconstruction and parser APIs before implementation. Add requires in `lib/primus.rb` as needed; do not change the loader or Document interface to dispatch these operations.

### Operation semantics proposed for review


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


### Migration and verification

1. Review merged Transcription code and resolve page/line semantics with the user.
2. Add separate line projection only for these operations, then implement standalone operations against the agreed call contract.
3. Test literal output/provenance and reuse, followed by external composition and explicit reparsing into Document.
4. Run focused transformation specs and existing known decoding/Document compatibility regressions. Existing `Document#reverse` remains separate.

## Proposed test matrix

Pin literal output, exact counts and source fields; object equality or delegation assertions alone cannot establish preservation. Existing WordReverser delegation tests do not establish the semantics of these new operations. Never generate expected output with the implementation being tested.

| Spec target | Required behaviors and independent examples |
| --- | --- |
| New `transcription/line_projection_spec.rb` | Empty, `A`, `A\n`, `A\n\n`, `\n`, and mixed CRLF/LF cases pin exact content groups and break tokens. Physical lines do not depend on commas or word delimiters. |
| New `transformations/reverse_line_order_spec.rb`, `reverse_tokens_within_lines_spec.rb`, `reverse_entire_sequence_spec.rb` | Assert all three literal rune examples above. For `A\r\nB\nC`, line-order reversal → `C\r\nB\nA`; whole sequence → `C\nB\r\nA`. For `A\n\n`, line-order reversal → `\nA\n`. Include punctuation pairs, spaces, quotes, single/empty lines, and two pages. Pin page order and original token coordinates. Double reversal restores original token order/bytes for token reversal operations; include `\nA` as the unresolved line-order regression before claiming the same for every line layout. Parsing transformed output never mutates either transcription. |
| Shared transformation contract examples in transformation specs | Each `call(input)` returns a distinct Transcription with unchanged input bytes/order and original token source fields. Reuse the same operation on A, then B, then A; both A results agree. For `ᚠ-ᚢ.\nᚦ,ᚩ\n`, external within-line reversal followed by line-order reversal yields `ᚩ,ᚦ\n.ᚢ-ᚠ\n` under the provisional line convention. Pin the literal output and preservation fields; do not merely assert delegation. No history is attached to results. |
| Parser integration example | Parse source, call a standalone operation, then parse its result into a new Document. Pin new punctuation grouping and translated text independently; original document/transcription remain unchanged. No chain runner is required. |
| Latin atomic-token example | Under prerequisite `ThING` tokens `Th`, `ING`, sequence reversal yields `INGTh`, not character-reversed `GNIhT`. The two original source spans remain unchanged. |
| Existing Document compatibility | `Document#reverse`, visitor calls, word-oriented `tokens`, and all known decoded outputs remain compatible; do not silently route them through a new transformation. |

## Edge cases

- Empty pages, repeated pages and page occurrences, single lines, blank lines, missing final breaks, leading/trailing breaks.
- CRLF is atomic; mixed newline styles preserve bytes under explicitly reviewed placement rules.
- Marks, spaces, quotes and multi-character lexical tokens are moved as tokens; no glyph reflection or internal lexeme reversal.
- Current order may have nonmonotonic original coordinates. Never use source positions as current traversal counters.
- `\nA` becoming `A\n` exposes ambiguous line regrouping; no hidden metadata or fabricated newline may repair it implicitly.

## Out of scope

- Building the Transcription prerequisite or changing Document public API.
- Chain runner, checkpoint/hash checking, execution history, registry, scoring, key search, or automatic pipeline generation. A later runner owns those responsibilities.
- Geometric glyph reflection, Atbash-as-layout, page-order reversal, chapter-wide reversal, or arbitrary reading routes.
- New cipher algorithms/skip rules or broad rewriting of Document visitors.

## Open questions

1. Approve page-local scope with unchanged page order and all-mark reversal.
2. Approve atomic multi-character lexemes, fixed newline slots for line-order reversal, and moving newline tokens for full-sequence reversal.
3. Resolve `\nA` → `A\n`: choose a documented non-involutive convention or revise line splitting/terminal-empty-group semantics, updating every provisional example consistently. Do not add hidden state to Transcription.
4. Revalidate constructors and exact source/provenance access against the completed prerequisite before writing implementation tests.

## Follow-up

After this separate work, freshly review the [decoding-chain milestone](page-54-55-research.md). Chain orchestration, hashing, checkpoints and history are not implemented by this plan.
