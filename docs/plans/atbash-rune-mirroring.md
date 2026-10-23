# Atbash and rune-order mirroring

## Goal

Add explicit, composable GP Atbash and rune-order reversal steps before terminal
Latin rendering, retaining source identity and independently verifiable saved
checkpoints. Use the real Liber Primus Warning page as the Atbash golden control.
This is a proposed plan for review; the mirroring contract below needs agreement
before test-writer or implementation work begins.

## Baseline and scope assessment

Inspected clean `main` and cached `origin/main`, both at
`8c7e388fd86c405ab729be7865aa43f54a82a69a` (continuous ordered page input),
on 2026-10-23. Branch: `codex/atbash-rune-mirroring`. No fetch, test suite,
research experiment, or baseline analysis was run in this planning pass.

No standalone prerequisite refactor is justified. Transcription is already a
thin carrier; operations have a `call(transcription)` seam; Steps, Chain and
CheckpointEvidence provide focused integration points. Add small owned operation
objects and targeted semantic validation instead of a generic pipeline framework.
Keep CQS, direct owned APIs, noun class names and the five-line method heuristic
as a guide rather than an artificial split requirement. Serialize at artifact
boundaries; do not propagate additional mutable deep hashes through the domain.

Earlier plans place audits and baseline research before later research trials.
Those are research gates, not prerequisites to writing or running software tests.
This increment executes no page-55 or combined-page research trials. Position
windows remain at the VERY END.

## Proposed mirroring contract — review decision

Use operation `reverse-runes`, with required parameters
`{scope: composed-input, non_runes: fixed}` (string keys/values in YAML/JSON).
The only supported scope in this increment is the complete current composed GP
rune stream. For input 54 then 55, reverse that one stream across the page boundary;
do not reverse each page separately, swap page blocks, or reverse Latin characters.
The source manifest remains ordered 54 then 55.

Extract current rune tokens, reverse their order, and place those tokens back
into the current rune slots. Every non-rune token stays in its lexical slot,
byte-identical: punctuation, whitespace, CRLF/newlines, Latin text, hexadecimal
text and unknown characters. A moved rune carries its original source location
and occurrence. Its output ordinal/span changes. Physical source line/column
remain source coordinates, not claims about the new output location. The original
page/boundary metadata remains source metadata; transformed occurrence order may
interleave and must not be reconstructed by grouping tokens by source page.

Example: source `ᚠ-ᚢ\nᚦ.` becomes `ᚦ-ᚢ\nᚠ.`. Reversing the lexical stream instead
would produce `.ᚦ\nᚢ-ᚠ`; that is a different operation. Existing
`ReverseEntireSequence` reverses all lexemes separately per occurrence via
PageMapper, and the existing within-line and line-order operations have their own
semantics. Preserve those APIs; none is an alias for this proposed operation.

This default interprets the user's phrase “rune-order reversal” literally.
If “mirroring the text” instead means moving delimiters/line breaks too, resolve
that before implementation and revise this plan. Do not implement a matrix of
both interpretations, per-line, per-page and page-swap variants automatically.

## Warning control and provenance

The exact local source is `data/encoded/liber_primus/page_warning.yml`; the
independently stored decoded body is
`data/decoded/liber_primus/page_warning.yml`. Its repository identity is
**warning**, as used by `spec/features/decode_a_page_spec.rb`, not a verified
numeric page number. Never coerce this identifier with `to_i` into page 0.

Frozen YAML SHA-256 values at the inspected baseline:

- encoded: `86a0a2a4d68c2fff1af86d3e7aa62bec05eb46a2bdbc480d4243bcf282561718`
- decoded: `d359714fdba2c8d3a557dd7c745659ffb1137cb58ce5844e28e830f0217c1d1f`

Local research provenance is
`docs/research/what-happened-part-1-2014.md`, section 3.2: an attributed adaptation
of the Uncovering Cicada Wiki account, consulted 2026-09-20, without a pinned
revision. It reports the reversed ordered GP alphabet and the English passage
“A WARNING / BELIEVE NOTHING FROM THIS BOOK ... FOR ALL IS SACRED.” Its spelling
and presentation are explanatory, not the literal renderer oracle. The research
also flags THEIR NUMBERS versus THE NUMBERS in a separate numerical table; the
local encoded/decoded pair resolves to “their numbers.” This pass does not claim
a new image/authenticity audit.

A standalone Ruby standard-library check in this planner pass read the alphabet
YAML, applied explicit index `28 - i`, expanded its literal Latin labels and
replaced hyphens with spaces. It used no Primus classes, parser, visitor or runner.
All 184 GP runes matched the complete decoded YAML body exactly, including its
nine physical lines and trailing newline. This verifies the stored pair and the
alphabet arithmetic independently of the implementation being extended; it is
not a research trial or independently authenticated scan verification.

Freeze the complete expected rune checkpoint and terminal Latin bytes as reviewed
literal test fixtures, with this derivation and both source checksums documented.
The final compatibility expectation is the decoded body with the existing
terminal trailing-whitespace rule applied once, not normalized English prose.
Preserve spellings such as `a warnng`, `belieue`, `nothng` and `booc`, split words,
internal/line-end spaces, and exact punctuation. Expected fixtures must not be
computed by production transforms/renderers at test runtime. No invented
synthetic Atbash plaintext control is required or substituted for Warning.

## Acceptance criteria

### Explicit operations and composition

- Extend v2 Steps to accept `atbash`, `reverse-runes`, and existing `totient` in
  any explicitly supplied sequence before exactly one terminal `latin`.
  Atbash uses exactly `{alphabet: gematria-primus, modulus: 29}`; reversal uses
  exactly the parameters proposed above; Latin still accepts no parameters.
  Reject unknown operations/keys, unsupported alphabets/moduli/scopes, duplicate
  or reserved step IDs, missing parameters and operations after Latin.
- Atbash maps every current GP index i to `28 - i`, leaving all non-rune tokens,
  token order and source locations unchanged. Reversal permutes existing rune
  tokens according to the agreed contract; neither mutates its input, pages,
  source bodies or a previously captured checkpoint. Both return Transcription.
- Named v2 definitions are the explicit composition interface for this increment.
  Each step owns its parameters; no shortcut silently attaches another operation
  or shares state. Existing CLI recipe shortcuts retain their meanings. Do not
  build a new CLI step grammar, presets or parameter-expansion/search facility.
- A 54-then-55 composed transcription uses one reversal domain. A later totient
  step consumes primes/skips in current global processing order, continuing across
  source boundaries. Atbash consumes no prime/key state. An intervening attempt
  must not alter repeat results. Only declared step order is executed.

### Real known control and source identity

- Permit the explicit `page-warning` selector in the experiment path used by the
  control, resolving only to the real `page_warning.yml`. Numeric IDs retain
  existing meanings. Support Warning's original string identity end-to-end;
  do not invent numeric aliases or allow arbitrary filenames/unsafe paths.
- Adapt the common source-identity boundary and its consumers consistently:
  Experiment selection/page construction, InputSource, retained source evidence,
  checkpoint coordinate validation and Analysis ObservationReader. The named
  identity exception is exactly `warning`; all other coordinate fields retain
  integer contracts. Preserve ordered occurrence semantics, including duplicates.
- Run Warning -> Atbash -> Latin through the explicit steps and saved evidence
  path in software tests, with literal expected original/intermediate/final
  artifacts and source mappings. Assert a real plaintext match; wrong operation
  order/configuration must not be accepted as the same attempt identity.
- Preserve page-56 exceptional totient control, page-57 Latin/hash controls and
  existing numeric/continuous-input behavior. Do not generalize every named
  Liber Primus page or add a generic source catalog in this increment.

### Checkpoints, validation and analysis

- Capture original and every declared intermediate/final stage with independent
  frozen bytes, ordered symbols, lexemes, output spans, operation parameters and
  parent linkage. Fingerprints retain ordered input identity and exact step order.
  Source occurrence/rune index stay original; processing ordinal follows output.
- Replace CheckpointEvidence's index-zipped original/current lineage assumption
  with identity-aware, operation-aware validation. Every source token occurs
  exactly once with its original kind/coordinates. Non-runes stay unchanged in
  their slots; Atbash/totient preserve previous order; reversal must apply the
  exact declared rune permutation from the immediately preceding checkpoint.
  Mere set equality is insufficient: reject an arbitrary permutation, duplicate,
  missing token, wrong occurrence or swapped provenance even if artifact checksums
  are recomputed. Validate Atbash symbol values against its preceding checkpoint.
- Keep OrderedSourceEvidence's original aggregate/source order/coverage checks
  strict and applied to the original checkpoint only. They must not be relaxed
  to accept reordered source snapshots. Source boundaries/checksums remain original
  evidence; output spans are calculated from transformed order, not source offsets.
- Verify Latin output mapping and original-rune provenance by moved source identity
  and occurrence. Multi-character GP Latin expansion stays a single rune origin;
  rendering/omission spans must remain accurate when source coordinates descend.
- Saved original, Atbash, reversal, totient and final stages remain selectable by
  explicit step ID using existing GP-symbol and expanded-Latin analyses. Analysis
  validates saved evidence then reads it; it does not transform input or mutate
  artifacts. It works after live sources change or disappear. Preserve existing
  final linkage, tamper rejection, exclusions/counts and IC interpretation.

### Focused independent verification

- Use Warning as the Atbash golden plaintext control; its double-Atbash involution
  is supplementary, not the sole oracle. Literal checkpoint fixtures include
  representative indices and source positions, independently computed as above.
- Add literal reversal controls for empty/singleton operation input, uneven lines,
  punctuation/hex/unknown tokens, CRLF, multiple occurrences and repeated pages.
  Reversal twice restores exact bytes, token identity/order and coordinates.
  The experiment's existing nonempty-GP input requirement remains unchanged.
- Use a tiny independently derived two-page reversal/totient fixture whose outputs
  differ for reversal-then-totient and totient-then-reversal. Include a cross-page
  move, distinct first/last runes and an expanded Latin rune. Assert literal
  expected outputs/mappings rather than only comparing two implementation runs.
- Atbash and rune reversal commute mathematically because Atbash substitutes each
  symbol independently. Do not demand distinct plaintext outputs for those two
  orders; retain distinct step histories/fingerprints while asserting the correct
  same output. Use totient for genuinely order-sensitive controls.
- Run targeted operation, schema, chain, source identity, checkpoint/evidence and
  saved-analysis specs, then the normal suite/lint required by project workflow.
  Tests use fully qualified RSpec subjects, no let/let!, literal independent
  expectations and focused assertions under existing conventions. Record actual
  unexpected failures in flaky-specs.md; do not predeclare failures or invent tests
  merely mirroring implementation structure.

## Approach

Likely changes: `lib/primus/experiment/steps.rb` for bounded operation contracts;
`chain.rb` for explicit operation dispatch that cannot treat every non-totient
step as Latin; small noun-named transformation objects (for example Atbash and
RuneReversal) exposing `call(transcription)`; reuse the existing Document Atbash
arithmetic where suitable without passing through a lossy Document round-trip.
Keep Transcription a carrier and existing reversal semantics unchanged.

Use a focused source-identity collaborator only if needed to avoid copying the
numeric/Warning conversion across `experiment.rb`, `input_source.rb` and evidence
readers. Keep it narrow. Update `checkpoint_evidence.rb` lineage verification,
`ordered_source_evidence.rb` named-identity handling and
`analysis/observation_reader.rb` page identity validation. Check Checkpoint and
Latin's existing span/occurrence mapping with tests before changing them.

Add one Warning control definition/expected artifact, its independently documented
fixture oracle, focused specs, and README examples of explicit steps and the chosen
reversal semantics. Do not add page-55/54-55 research variants in this change.
No migration is required solely to preserve disposable pre-v1 runs; do not delete
existing evidence. Avoid unrelated code cleanup or new analyzers.

## Edge cases

Repeated source pages have distinct occurrences; moved runes may cross original
page and line boundaries without changing source metadata. Empty/singleton streams,
trailing whitespace, missing final newline, CRLF, punctuation pairs and hexadecimal
text retain exact intermediate bytes. Named Warning must not collide with page 0.
Reject malformed parameters and mismatched saved order before analysis. Partial
failed chains retain existing honest failed-step behavior and do not gain a false
final checkpoint. No output digest comparison is newly added to intermediate stages.

## Out of scope

Research trials, new key ciphers, brute force/search, automatic variant matrices,
new analyzers, hash reassessment, page-order swapping, per-page/per-line reversal
variants, altered existing reversal APIs, position windows, general source catalogs,
legacy migration/deletion, push or PR. This planner changes only this plan and
creates its required local WIP commit; no test-writer delegation before review.

## Open questions

The material decision is whether mirroring means the proposed **GP-runes only,
non-runes fixed, whole composed input** contract or reversal of all lexical tokens.
The former is the bounded recommendation, not a silently adopted interpretation.
Once agreed, use this plan for implementation; if the latter is chosen, revise
boundary, punctuation and provenance expectations before delegating tests.
