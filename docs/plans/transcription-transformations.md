# Standalone transcription transformations

## Status and dependency

Reconciled against merged `381cd90` (Add lossless transcription beneath
Document), including source and lossless/compatibility specs. The
[lossless prerequisite](lossless-input.md) has merged; its proposal and
historical status text are not the current API contract. This revision is
planning only: no source changes, test implementation, or test-writer
handoff. Line-order semantics below still require a choice before tests
are frozen. No further prerequisite refactor is justified by this review.

## Goal

Provide three standalone, page-local reversals over Transcription, with
explicit reparsing into fresh Document views. Preserve original source
provenance while keeping current token order separate from source order.

## Acceptance criteria

- `operation.call(transcription)` returns a distinct Transcription and
  leaves input arrays, tokens, source locations, page bodies, and artifacts
  unchanged. Preserve every original token object exactly once, including
  marks, whitespace, unrecognized text, and atomic multi-character tokens.
- Results own new `tokens`, `pages`, and `boundaries` arrays. Page, boundary,
  lexical token, and source-location objects are shared read-only by the
  operations. No promise of deep immutability is added to the existing API.
- Preserve page order, empty occurrences, repeated page occurrences, and
  original boundary objects. No token moves between occurrences.
- Each operation owns its rules and any parameters; retain no input-specific
  state between calls. Compose externally: `second.call(first.call(input))`.
- Transcription stays thin. Add no operation methods, dispatcher, registry,
  line-slot state, or history. Keep Document public API, existing `reverse`,
  and nested visitors unchanged.
- Within-line and entire-sequence reversals are involutions: applying twice
  restores token identity order and exact current bodies. Line-order
  involution is conditional on the selected convention below, not yet an
  approved universal acceptance criterion.
- Reparse current tokens directly through Parser with explicit strategy and
  compatibility options. Never render and re-lex a transformation or rebuild
  it through Document::Builder, which would restore original page bodies.

## Approach

### Merged API and ownership contract

| Actual implementation | Consequence for transformations |
| --- | --- |
| `Transcription.new(pages: [], tokens: [], boundaries: [])` stores supplied arrays directly; readers expose them | Construct directly with fresh arrays; do not use in-place array reversal on input. |
| `Transcription#source_bodies` maps `pages.map(&:source_body)` | These are original extracted bodies, even after token rearrangement. This is not a current-output renderer. |
| `Transcription.compose` flattens page/token arrays and creates boundaries numbered `1...pages.size` | It does not rebase token occurrence IDs. Do not compose independently lexed default-occurrence-zero pages or call compose to construct operation results. |
| `PageBoundary.new(occurrence:)` identifies the following page occurrence | Boundaries are a separate array, not tokens or separators embedded in a stream. Preserve their identity/order and contribute no text. |
| A page occurrence is its index in `pages`; tokens carry `source_location.occurrence` | Enumerate page indices, including those with no tokens. Do not group by page number or page object equality: repeated pages may be the very same object. |
| `Transcription::Token.new(lexeme:, kind:, source_location:)` has readers | Lexemes and tokens are not frozen. Share them without mutation; do not freeze caller-owned objects as a side effect. |
| SourceLocation has readers for page number, occurrence, byte/character spans, line, column, rune index | Preserve the original object and all fields. Spans are zero-based and end-exclusive; rune index exists for GP runes only. Never rewrite these as current coordinates. |

Page/source strings and exposed arrays are also mutable in the merged
implementation. The contract is nonmutation by these operations, not
isolation from arbitrary later caller mutation of a shared token or page.
Fresh result arrays prevent clearing or reordering one result's collection
from changing the input collection. Deep freezing/copying would change
ownership or identity expectations and is outside this plan.

Supported input is the well-formed shape emitted by Document::Builder:
occurrences are globally numbered by page index, every token belongs to
one such index, and boundary occurrences are `1...pages.size`. Empty and
zero-page inputs are valid. Lexer.build accepts `occurrence:`; Builder
supplies it before composition. General normalization/validation of manually
malformed transcriptions is not part of these operations.

For current per-page bytes, enumerate every page index, select matching
tokens from the **current** `tokens` array in its existing order, and join
`lexeme`. This uses available APIs, needs no new Transcription renderer,
and yields an empty string for an empty occurrence. Joining all lexemes
alone loses page separation. Original bodies remain in `source_bodies`;
original YAML bytes and paths remain on the shared pages as `artifact_bytes`
and `source_path`. Do not regenerate them from transformed contents.

Original physical line membership is `source_location.line`; the current
line projection comes from current `kind == :line_break` positions. These
can disagree after rearrangement. Current offsets, if needed for display,
are derived separately and never written back to provenance.

### Files and responsibilities

| Proposed file/class | Responsibility |
| --- | --- |
| `lib/primus/transcription/line_projection.rb` / `Primus::Transcription::LineProjection` | Separate read-only projection of one occurrence's current content groups and line-break references. No cached state attached to Transcription. |
| `lib/primus/transformations/reverse_tokens_within_lines.rb` | `Primus::Transformations::ReverseTokensWithinLines#call` reverses each content group. |
| `lib/primus/transformations/reverse_line_order.rb` | `Primus::Transformations::ReverseLineOrder#call` reverses content groups under the chosen convention. |
| `lib/primus/transformations/reverse_entire_sequence.rb` | `Primus::Transformations::ReverseEntireSequence#call` reverses all lexical tokens per occurrence. |
| `lib/primus.rb` | Declare the new Transformations namespace and require the additions in dependency order, following the current explicit loader. |

Use ordinary objects with a common call contract, not an abstract base class
or visitor hierarchy. Keep page selection/result assembly small and local;
extract a shared helper only if implementation reveals meaningful duplication.
Five-line methods are a heuristic, not grounds for a prerequisite refactor.
Broad Law of Demeter cleanup remains deferred. Existing Parser, Builder,
Document, source capture, and cipher visitors need no planned changes.

### Operation semantics and unresolved newline choice

Recommended scope remains every page occurrence independently, preserving
page order. No chapter-wide or page-order reversal is included.

**Within-line tokens:** reverse all non-line-break tokens in each current
line, including punctuation, spaces, tabs, and unknown characters. Breaks
stay between their original ordinal content groups; groups can change
length but token counts do not. Never reverse characters inside a lexeme.
This behavior does not depend on whether a terminal empty group is retained.

**Entire sequence:** reverse every lexical token in an occurrence, including
line-break tokens. A trailing break becomes leading. CRLF, recognized
punctuation pairs, and Latin digraph/trigraph tokens remain atomic.

**Line order:** reverse content groups, interleaving the original break
objects in their original ordinal order. “Fixed break slots” means ordinal
separator order, not fixed byte offsets or absolute token-array indices.
There is a real semantic choice about terminal empty content groups:

| Input | A: omit terminal empty group | B: include terminal empty group |
| --- | --- | --- |
| empty | empty (zero groups) | empty (zero groups; explicit special case) |
| `A` | `A` | `A` |
| `A\n` | `A\n` | `\nA` |
| `\nA` | `A\n` | `A\n` |
| `A\nB\n` | `B\nA\n` | `\nB\nA` |
| `A\n\n` | `\nA\n` | `\n\nA` |
| `\n` | `\n` | `\n` |
| `A\r\nB\nC` | `C\r\nB\nA` | `C\r\nB\nA` |

A is the prior provisional “physical lines” convention. It preserves a
terminal newline but is non-involutive: `\nA` becomes `A\n`, then stays
`A\n`. Likewise `A\n\n` becomes `\nA\n`, then `A\n\n`, whereas the
unterminated `\n\nA` also maps to `A\n\n`. The transformation is not
injective; retaining token identity and source coordinates does not supply
a stateless current-line rule that reverses every composition correctly.

B retains empty groups on both sides of breaks: any nonempty page with
N breaks has N+1 content groups. Reversing these groups and interleaving
unchanged break order is an involution without hidden state. It changes
ordinary terminal-newline expectations, explicitly shown above. Break
style order remains fixed even though leading/trailing placement can change.

**Recommendation, awaiting decision: B.** It gives a predictable stateless
reversal over all permitted layouts and composes naturally. If preserving
final-newline placement is the intended research behavior, choose A and
explicitly accept non-involution instead. A third choice is to reject
ambiguous layouts, but restricting the domain limits lossless research
inputs and needs its own precise domain specification; it is not recommended.
Do not silently pick either convention, reconstruct groups from original
line numbers, fabricate breaks, or add line-slot/history metadata to make
A appear invertible. Both A and B remain choices, not approved requirements.

For current body `ᚠ-ᚢ.\nᚦ,ᚩ\n`:

| Operation | Exact resulting body |
| --- | --- |
| Within-line tokens | `.ᚢ-ᚠ\nᚩ,ᚦ\n` |
| Line order A | `ᚦ,ᚩ\nᚠ-ᚢ.\n` |
| Line order B (recommended, unapproved) | `\nᚦ,ᚩ\nᚠ-ᚢ.` |
| Entire sequence | `\nᚩ,ᚦ\n.ᚢ-ᚠ` |
| Within-line followed by line order A | `ᚩ,ᚦ\n.ᚢ-ᚠ\n` |
| Within-line followed by line order B | `\nᚩ,ᚦ\n.ᚢ-ᚠ` |

The last B example equals entire-sequence output because its breaks are
identical. They are not generally equivalent: for `A\r\nB\nC`, line order
(with either convention) yields `C\r\nB\nA`, while entire sequence yields
`C\nB\r\nA`. Preserve break identities even when their lexemes match.

### Explicit reparsing and compatibility

Use `Primus::Parser.new(transcription: result, policy: :compatibility,
strategy: :runic, track_delimiters: false)` (choose `:latin` when appropriate),
then `parse`, which returns a fresh Document and updates `parser.result`.
Repeated `parse` on the same Parser also creates fresh graphs. There is no
Transcription `parse`, `reparse`, or strategy attribute. Callers retain the
chosen strategy/options outside the source model. `Primus.parse` is the
existing text-to-words helper, not the Transcription reparse API.

Parser selects tokens by occurrence while preserving their current order;
it does not consume `boundaries` directly. It removes trailing whitespace
and break tokens from intermediate pages in its view and inserts a synthetic
LF with no source location. The printer applies final `rstrip`. Thus parsed
rendering is not an exact transformed-body oracle. Physical lines can still
continue inside one parsed Word. Preserve these compatibility behaviors.
Compatibility creates new interpreted tokens and attaches the original
source-location object; legacy position/line tracking is separate and must
not be mistaken for new authoritative source coordinates. Synthetic page
breaks do not claim source positions. Reordering punctuation can alter word
and sentence membership without altering source provenance.

## Proposed verification and migration

This is a future test plan, not tests written or run in this reconciliation.
Use literal expectations plus object identity and full field assertions;
existing equality/rendering alone cannot establish losslessness.

1. Resolve A/B and the recommended page-local/all-mark scope before
   test-writer handoff. Replace conditional expected outputs consistently.
2. Add projection/operation specs for empty input, empty pages, `A`, `A\n`,
   `\nA`, `\n\nA`, `A\n\n`, `\n`, lone CR, CRLF, and mixed break styles.
   Pin all chosen groups and break identities, then each literal reversal.
3. Verify every token identity occurs exactly once, including punctuation
   pairs, quotes, whitespace, unknown Unicode, and Latin `ThING` tokens
   `Th`, `ING`. Entire reversal gives `INGTh` with original spans `[2,5)`
   then `[0,2)`; never character-reversed `GNIhT`. Add an adjacency case
   where re-lexing would merge formerly separate Latin tokens.
4. Use repeated page objects with an empty middle page. Verify page indices,
   boundary identity/order, unchanged original source_bodies/artifacts, and
   separately reconstructed current bodies. Confirm fresh result arrays;
   clearing one result's array must not change input arrays.
5. Assert all SourceLocation fields unchanged (including byte versus
   character spans and page-local rune indices). Verify current order can
   be nonmonotonic in original coordinates. Operations must not depend on
   original line numbers after an earlier entire-sequence reversal.
6. Reuse an operation on A, B, then A; compare literal A results and token
   identities. Verify external composition, input nonmutation, and double
   reversal guarantees. Under A, explicitly pin the non-involution; under
   B, pin full involution including leading/trailing empty groups.
7. Reparse transformed `ᚠ,ᚢ` after entire reversal: fresh sentences render
   `ᚢ,` and `ᚠ`; the source document stays `ᚠ,ᚢ`. Check translated token
   values and source locations independently. Reparse Latin with explicit
   `:latin`; pin case-preserving lexical output separately from interpreted
   lowercase mappings. Include multi-page synthetic separator behavior.
8. Run focused new specs plus existing `lexer_lossless_spec.rb`,
   `parser_lossless_spec.rb`, `document/builder_lossless_spec.rb`,
   `features/transcription_compatibility_spec.rb`, Document reversal/visitor
   regressions, and seven `features/decode_a_page_spec.rb` controls; then
   the full suite. No plaintext expectation changes are implied.

## Edge cases

- Zero pages versus one empty page; repeated page number/object with distinct
  occurrence IDs; a page with only line breaks or whitespace.
- CRLF covers two characters but is one token; lone CR is also a break.
- New token adjacency must not trigger normalization or lexical merging.
- Parser trims only its compatibility view; source and transformed lexical
  bodies must survive reparsing/rendering unchanged.
- Shared objects are not deeply immutable; no operation may mutate or freeze
  them. Source-body equality cannot prove current-order correctness.

## Out of scope

- Implementation or test-writer invocation during this reconciliation.
- New Document APIs, changes to existing reverse/visitors, or broad cleanup.
- A new source renderer, deep immutability, malformed-input normalization,
  compose rebasing, or changing original source coordinate semantics.
- Chapter/page-order reversal, glyph reflection, geometric routes, and ciphers.
- Chain runner, hashes, checkpoints, history, registry, scoring, and searches.
  The [page-54/55 research plan](page-54-55-research.md) motivates provenance
  requirements but is not expanded or implemented here; original line
  extraction and current line traversal remain distinct research choices.

## Open questions

1. Choose line-order A (terminal newline retained, non-involutive) or the
   recommended B (terminal empty groups retained, involutive). This changes
   ordinary outputs, not just an obscure edge case.
2. Confirm recommended page-local scope, all-mark reversal, and atomic
   lexemes. Full-sequence reversal moves breaks; line-order preserves their
   ordinal identity/order under the selected convention.

The merged constructors, occurrence representation, ownership, reconstruction,
and explicit Parser entry point have now been reviewed; they are no longer
open API-discovery tasks. No broader chain/hash decision is required to
review this plan.
