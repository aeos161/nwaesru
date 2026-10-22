# Continuous ordered page input

## Goal

After applying the completed checkpoint/IC harness to the two page-55 baselines,
extend the same two baselines to pages 54 then 55 as one full continuous piece.
This software increment supplies ordered whole-page input with intact source
identity and checkpoint evidence; it adds no cipher operations or search windows.

## Baseline and prerequisite assessment

Inspected clean local main and cached origin/main at
`3a440b2af82eb22ac34f6b64c50e34949e1f2774` on 2026-10-22. No fetch, tests or
experiment execution occurred in this planner pass. Branch from that actual
baseline: `codex/continuous-page-input`.

Checkpoints, saved original/intermediate/final analysis and IC interpretation
are now implemented. The earlier initial-experiment and roadmap descriptions
of these as future work are historical. Current v2 input still accepts exactly
one `page-N`; Runner builds one SourceScan, Store retains one source and Latin
provenance slices every rune from the first source body.

No standalone prerequisite refactor is justified. SourceScan already accepts
occurrence, Transcription.compose retains ordered pages and boundaries, and
Totient applies one stream across all transcription tokens. Introduce a focused
owned input collection at the loading boundary, and adapt its direct consumers.
This is required feature behavior, not a generic cleanup. Keep Transcription a
thin carrier. Do not enlarge Experiment or Runner with another parallel set of
single/multiple-source branches, nor transport mutable deep hashes through the
domain. Preserve command/query separation and existing owned evidence objects.

## Required research order

1. Finish the source/target audit below, then run and analyze page 55 using the
   existing harness. No new source capability is needed for this first stage.
2. Implement and verify this ordered-input feature; audit page 54; then run the
   direct Latin and default totient baselines on **54 followed by 55 as one
   continuous piece**. Do not substitute separate page runs or reset at 55.
3. Only after those results, invoke planner fresh for bounded reversal/Atbash
   and other operation support, with independently specified layered controls.
4. Position windows remain at the VERY END, after broader full-input work.

### Audit and page-55 execution gate

The existing definitions still say their image audit is pending. Local image
inspection or agreement among transcriptions is not a completed image audit.
Compare all page-55 runes, punctuation and four physical lines against 55.jpg,
recording image path/source and checksum, body checksum, 76-rune count, boundary
choices and any ambiguous glyph coordinates. Audit 54.jpg similarly before the
combined research run. Never silently correct an ambiguous transcription.

The target is the 128 lowercase hexadecimal characters in the initial plan,
joined from five groups in the page-56 decoded text. Existing encoded/decoded
YAML and research text agree; this does not verify the image. The repository
image set inspected by the parent has 54.jpg and 55.jpg but no 56.jpg. Locate an
authentic page-56 scan from the documented research source/linked archive, retain
its source URL and file checksum, and compare its five hexadecimal groups directly
with the frozen target. Record a legible-image audit or the precise missing or
ambiguous group. If no adequate scan can be retrieved, the target-audit gate
remains open and research execution remains blocked; software controls can proceed.
Do not silently waive the gate or describe transcription agreement as verification.

Inspect existing history before rerunning. Runs `20261008T193759-01fa878ed097`
(Latin) and `20261008T194016-49ab658b0fcb` (totient) predate checkpoints; retain
both. Replacement is justified specifically to capture original/intermediate/
final evidence with current code and recorded audits. Use the existing explicit
rerun/reason facility where applicable, and cite both predecessor IDs in the
research record even if their older fingerprints differ. Never delete old runs
or pretend a rerun is a first observation.

Keep the two existing IDs, three algorithms, frozen target and compatibility
Latin policy. Totient is subtraction of p-1 modulo 29, prime_start 2,
skip_sequence []; do not import page 56's exceptional skip or invent skip 55.
Analyze original and final for direct Latin; original, totient and final for
totient-Latin, each in GP symbols and expanded Latin, using saved checkpoints.
A totient-stage analysis definition is needed alongside existing original/final
ones. Retain raw IC and current interpretation, counts, exclusions, artifact
identity and hash outcomes separately. This is five analysis invocations/ten
representation results per input unit, two derivations and six final hash checks.
Do not add checkpoint hash comparisons implicitly. Retain the initial plan's
60-second/10-MiB per-attempt operator caps; no automatic retries or parameter scan.

## Acceptance criteria

### Ordered input contract

- Preserve existing v1 controls and v2 `{id: page-N, sha256: ...}` definitions.
  Add one v2 alternative: `input: {pages: [{id: page-54, sha256: ...},
  {id: page-55, sha256: ...}]}`. The ordered list contains at least two validated
  whole-page entries. Reject mixed single/list fields, empty/one-entry lists,
  malformed IDs/checksums, unknown keys, missing files and unsafe paths.
- Named definitions suffice for this increment. Keep current single-page CLI
  composition unchanged; do not introduce a fake page-54-55 page ID or combine
  YAML bodies into a synthetic source file. No user-facing reset switch is added.
- Load each source once into owned input/source objects, verifying YAML bytes,
  UTF-8, body and declared checksum under current rules. Each member retains its
  real page number, ordered occurrence, source path, YAML bytes/checksum and exact
  body bytes/checksum. Repeated page IDs are valid distinct occurrences; changing
  member order, membership or any member bytes changes experiment identity.
- Build SourceScan for each occurrence, then compose once. Keep source-relative
  line/column/byte/rune coordinates, real page identity and occurrence untouched.
  Processing GP ordinal is global across the composed input. Totient's prime
  and rune state continue over the boundary; punctuation consumes neither. An
  explicitly configured skip is global, bounds-checked against total GP count;
  the research baselines still use an empty skip list.
- Source-body and original rune output bytes are the exact ordered concatenation
  of member bodies, inserting no separator and trimming no member. Boundaries
  remain explicit metadata even when a member lacks a final newline. Retain each
  member's half-open byte range in that aggregate, occurrence and source identity;
  these ranges must reconstruct the original aggregate exactly.
- Latin uses the existing compatibility parser once over the composed
  transcription and final compatibility rendering once. Do not separately render
  pages then concatenate, inject a page newline or strip each body's trailing
  whitespace. Pin the existing parser's boundary rendering with literal controls.
  Final rune provenance must slice the source body selected by occurrence, not
  the first page's body or aggregate offsets.

### Retained evidence and analysis

- Store per-member immutable input YAML/body artifacts plus the ordered source
  manifest and explicit aggregate body artifact. Use occurrence-safe artifact
  names. Never claim a combined object has one original YAML path/page number.
  Fingerprints bind ordered identities, byte/boundary policy and every checksum.
- Checkpoint records bind the same ordered manifest and boundaries, not an
  invented single-source digest. Extend CheckpointEvidence to verify all member
  snapshots, exact concatenation/ranges, identity and existing lineage/span/final
  linkage. An altered member, swapped order, wrong occurrence or corrupt boundary
  rejects analysis/review before measurements. Saved verification works with
  live source files absent or changed and uses retained artifacts only.
- Carry the collection through Store snapshots, run records, overlap protection,
  review and Analysis ObservationReader as needed. Output directories overlapping
  any source/expectation reject. Queries expose owned source objects; serialization
  belongs at the artifact boundary. Do not add a migration service for disposable
  pre-v1 runs, and do not delete existing evidence in this increment.
- Analyze combined original/totient/final stages as above, retaining both symbol
  representations and current IC judgments. Analysis never reruns transformations
  and checksums continue identifying exact saved evidence.

### Independent verification

- Before research execution, freeze a tiny two-source GP fixture with literal
  expected original, totient and final outputs, source positions and digest
  oracles calculated independently of production helpers. Include distinct
  first/second-page runes, punctuation, a multi-character Latin expansion and a
  boundary without a final newline. Document the arithmetic and prime consumption.
- The second page's first rune must demonstrate the continued prime differs from
  a fresh prime-2 reset. Assert the continuous expected output and separately
  demonstrate the reset control differs. A test merely comparing implementation
  to itself is insufficient. Repeat with an intervening attempt to catch state
  leakage. Preserve duplicate-page occurrences and boundary bytes in a focused
  provenance control; test global skip bounds without adopting skips in research.
- Retain existing single-page page-56 exceptional skip/pause and page-57 direct
  Latin/three-hash regressions, checkpoint evidence tamper checks and analysis
  review behavior. Use fully namespaced RSpec, no let/let!, independent literal
  expectations and one behavior/expectation per example under project conventions.
  Record actually observed unexpected failures in flaky-specs.md.

## Approach

Add a narrow Experiment input collection/source value object for validation,
ordered identity, snapshots and transcription construction. Integrate it through
Experiment's v2 loading, rune count and fingerprint inputs; Runner asks it for
the composed transcription. Preserve the single-page adapter and old byte
contracts. Totient's existing full-stream implementation needs no new reset
machinery. Correct Latin's first-body assumption by occurrence-based source lookup.

Update Store and CheckpointEvidence at their existing artifact/evidence boundary;
reuse verified evidence in Analysis rather than cloning validators or using Store
review to load unrelated assessments. Keep aggregation, source spans and artifact
serialization in focused collaborators instead of moving those duties into
Transcription. Extend README with the list definition and continuous semantics.
Add two named combined baseline definitions only once checksums/audits are ready;
record exact IDs, run IDs and research outcomes separately from software controls.

## Edge cases

Missing newline, CRLF, trailing spaces, punctuation at a boundary, repeated pages,
changed source/checksum, unsafe or overlapping paths, invalid members, failed
checkpoint writes and corrupt siblings must retain current honest error behavior.
No missing algorithm becomes a mismatch. Hashes compare final exact bytes under
SHA-512, BLAKE2b-512 and original BLAKE-512; all comparisons run after a mismatch.
A byte match requires independent recomputation before interpretation. Negative
results exclude only the tested bytes/algorithm combinations.

## Out of scope

Page 54 alone, per-page-reset research variants, reversed page order, windows,
new ciphers/reversals/Atbash, key extraction, brute force, normalization search,
checkpoint hashing, migration/deletion, general preset overrides, push or PR.
This planner pass changes only plans and creates its required local WIP commit.

## Open questions

The page-56 hash's referent, algorithm and byte serialization remain unconfirmed;
full-page candidate hashing is a hypothesis, not a known plaintext expectation.
Image audit availability/ambiguity is a concrete research gate. Neither uncertainty
requires broadening this software change. Next action is completing audits and
page-55 baseline evidence; the test-writer/implementer handoff for this feature
follows that first research stage, without further capability planning if this
plan's baseline remains applicable.
