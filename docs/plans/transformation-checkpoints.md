# Explicit transformation steps and immutable checkpoints

## Completion and next milestone — 2026-10-18

Implemented on local main at `abc54e1`. The next bounded plan is
[saved-checkpoint symbol analysis](checkpoint-symbol-analysis.md), using the
retained original and declared step captures. Further analyzers follow in
separate plans. Position windows are deferred to the very end of the broader
roadmap; this does not authorize page-55 chain trials.

## Goal

Execute a finite, explicitly ordered transformation chain from YAML and retain
original input plus every step's exact output, symbols, parameters and source
mapping. Prove the chain against independently specified layered synthetic
answers before any page-55 chain trials.

## Baseline and prerequisite assessment

Inspected clean local `main` at `daddc5a` (saved-output symbol analysis), based
on `d98c722` (reusable totient and page-56 controls), on 2026-10-14. This plan
starts on `codex/transformation-checkpoints` from that completed implementation.
The reported preceding suite result is 709 examples, zero failures, 12 pending;
no tests were run for this documentation-only planning pass.

No prerequisite refactor is required. Runner already has a single
`produce_observation` seam; transformation execution can be a composed owner
behind it. Existing Runner/Store/Experiment classes are large, but this change
does not need more stage branches inside them. Put chain execution, step
validation and checkpoint ownership in cohesive objects, rather than expanding
`derive` or adding responsibilities to Transcription. This is feature-specific
composition, not a general cleanup of existing orchestration or schemas.

## Acceptance criteria

### Definition and execution

- Replace editable experiment YAML `recipe` with ordered, nonempty `steps`.
  Each entry has a unique safe `id`, `operation`, and `parameters` mapping.
  The bounded vocabulary is `totient` followed by terminal `latin`; permit
  zero or more totient steps and exactly one final Latin step. This supports
  current direct-Latin and totient-Latin behavior plus repeated independent
  totient layers. Reject unknown operations/fields, duplicate IDs/keys,
  aliases, missing/invalid parameters, and Latin before the final position.
- Totient parameters are explicit: `modulus: 29`, prime integer `prime_start`,
  unique in-range nonnegative `skip_sequence`; normalize skip ordering for
  identity. Latin has `parameters: {}`. No shared key, implicit continuation,
  direction option or inherited per-layer state. Reserve `original` and
  `final` from user step IDs. Existing whole-page input validation remains.
- Keep the current experiment definition schema marker rather than inventing
  a compatibility branch solely for disposable pre-v1 definitions. Update
  repository definitions and corresponding fixtures together. Old draft
  recipe YAML may fail with a clear instruction to use steps; there is no
  migration service. Existing CLI recipe shortcuts remain useful conveniences:
  `latin` expands to a terminal Latin step; `totient-latin` expands to totient
  plus Latin, including existing parameter defaults and validation. Canonical
  persisted configuration and execution identity contain explicit steps.
- An owned Chain executes each Transformation against the previous result,
  capturing the original before execution and each result before proceeding.
  Use composition and the existing `call(transcription)` convention for rune
  transformations, not a superclass/registry framework or Transcription
  methods. The terminal Latin step owns compatibility interpretation/rendering;
  it is deliberately not a Latin-to-rune round trip or a reusable cipher input.
  Chain/Runner commands return nil and expose result/checkpoint readers.
- Each totient step starts a fresh prime enumerator and rune counter. Skips
  refer to zero-based current GP rune ordinal in that step's input, count as
  positions but consume no prime; punctuation/whitespace consume neither.
  Layer A, unrelated run B, then layer A again produces identical answers.
- Keep source lexical tokens through rune steps: replace only rune lexemes,
  preserving every other lexeme, order, boundary and SourceLocation field.
  Never rebuild intermediate inputs from original page bodies or render and
  re-lex them. Transcription remains thin, and its existing reversal APIs and
  shared-read-only object guarantees do not change.
- Existing page-57 Latin bytes, page-56 bytes and all four page-56 checks stay
  unchanged. In page 56, ordinal 56 remains unchanged and ordinal 57 uses the
  unconsumed next prime (269). Final symbol manifests, canonical GP expansion
  analysis and assessment match/mismatch/error semantics remain unchanged.

The corresponding synthetic chain declaration is:

```yaml
steps:
  - id: first
    operation: totient
    parameters: {modulus: 29, prime_start: 2, skip_sequence: [1]}
  - id: second
    operation: totient
    parameters: {modulus: 29, prime_start: 3, skip_sequence: [2]}
  - id: letters
    operation: latin
    parameters: {}
```

### Checkpoint evidence

- A successful chain stores N+1 checkpoints: `original` and one per step.
  Each has a run-scoped ID, ordinal, parent ID (nil only for original), fully
  resolved operation/parameters, representation and serialization policy,
  exact output artifact metadata (path, byte length, SHA-256), ordered symbols
  with original source coordinates, and links to input/source identity.
  A record's `final_checkpoint_id` identifies the terminal Latin step.
- Original output bytes equal captured source-body bytes, including trailing
  whitespace. Rune checkpoint output is exact current lexical concatenation,
  under a named `gp-runes-lossless-v1` policy. Terminal bytes alone use existing
  `gp-latin-compatibility-v1` parsing/rendering (including its trimming and
  delimiter behavior). Do not describe a compatibility view as lossless input.
  Preserve raw input YAML and source-body snapshots independently.
- Symbol evidence records ordered current GP runes and canonical Latin
  expansions plus current ordinal and every original SourceLocation field.
  The terminal Latin checkpoint retains the underlying GP symbols; expansions
  such as `th` are one GP token, two Latin letters. Output spans, where supplied,
  are explicitly byte spans in that checkpoint's output, separate from source
  spans; delimiters/trimming cannot silently make those spans false. Retain
  sufficient ordered lexical evidence for non-rune bytes and their mappings,
  not only the GP subset used by final analyses. The terminal mapping accounts
  explicitly for retained, rendered and omitted input tokens under compatibility.
- Snapshot ownership is deep: copy nested arrays, strings, parameters and
  coordinate values before freezing. Mutating caller input or later results
  cannot change an earlier checkpoint; capture must not freeze caller objects.
  Later steps/checks cannot overwrite checkpoint artifacts. Immutability is
  application behavior plus checksum verification, not filesystem permissions.
- Store checkpoints under `checkpoints/<step-id>/` with their own output and
  symbols/provenance evidence. Publish their metadata only after their files
  are complete, using the existing atomic-record pattern. Repeated step
  operations remain separate records even when bytes match. Identity includes
  ordered steps, canonical parameters and policies, not just final text.
- Keep current root `output.txt`, `provenance.json` and final representation
  contract as the final observation interface; derive them from the same
  terminal capture, with matching checksums, rather than rerunning anything.
  This small final projection preserves existing readers and analyses without
  opening stage selection. New checkpoint metadata is additive to run records.
- A failed step records its ID/index, exception and failed attempt status;
  retain every previously completed checkpoint. Do not create a successful
  checkpoint for that failure, execute later steps or assess a partial result
  as final. Failure after final capture during assessment preserves the valid
  final observation and existing assessment-error behavior. Invalid definitions
  execute no steps. No final observation escapes a failed chain.
- Review exposes ordered checkpoint identities, operations, parents and
  artifact references without re-executing transformations. Validate selected
  checkpoint records/artifacts before presenting them as verified evidence:
  unique ordered IDs, exact preceding parent, final linkage, metadata/hash/
  byte counts, representation and source mappings, and paths contained within
  the selected run (including symlinks). Missing, truncated, contradictory or
  altered checkpoint evidence raises a clear read error; do not silently repair.

## Independent layered control and test-writer handoff

Prepare a small fixture/oracle note before feature tests. This arithmetic is
specified directly from the published GP index order, not from Runner,
Transformation, TotientShift, Parser or Printer output. No production helper
may generate the expected values. The test writer independently checks this
hand calculation and freezes literal fixture bytes and SHA-256 values with a
separate general-purpose digest tool; checksums alone do not prove arithmetic.

Use one synthetic page with source body `ᚳᚻ ᛇᛒ\n` (LF at end):

| Capture | Operation | GP indices | Exact output |
| --- | --- | --- | --- |
| original | capture | 5, 8, 12, 17 | `ᚳᚻ ᛇᛒ\n` |
| first | totient, start 2, skip [1] | 4, 8, 10, 13 | `ᚱᚻ ᛁᛈ\n` |
| second | totient, start 3, skip [2] | 2, 4, 10, 7 | `ᚦᚱ ᛁᚹ\n` |
| letters | Latin compatibility | 2, 4, 10, 7 | `thr iw` |

First consumed primes are 2, 3, 5: subtract 1, skip, 2, 4 modulo 29.
Second independently starts at 3 and consumes 3, 5, 7: subtract 2, 4, skip,
6. These distinguish independent initialization from continued state and
skip-without-consumption from skip-with-consumption. None is a page-55 claim.
Original rune byte spans are [0,3), [3,6), [7,10), [10,13); character spans
are [0,1), [1,2), [3,4), [4,5). All four source rune indices stay 0..3.
Final rendered rune expansion spans are [0,2), [2,3), [4,5), [5,6);
the original LF [13,14) is retained in rune checkpoints and omitted only by
terminal compatibility rendering. Check every source-coordinate field against
literal fixture values, not only a checksum or to_s comparison.

Keep the existing public whole-page input selector bounded. Exercise the same
Experiment/Runner path with a temporary repository fixture at a valid page-ID
path and explicit input checksum; do not add arbitrary files, inline-source
YAML or a production synthetic-input API just for this test.

Next test-writer work, in order:

1. Freeze/check the oracle note and literal intermediates independently.
2. Add definition/CLI expansion cases, parameter validation and canonical
   identity tests (different ordering/parameters changes identity).
3. Add chain isolation, source mapping, full nested snapshot ownership and
   failure-after-first-step cases, then persistence/review corruption cases.
4. Drive the synthetic control end to end and assert all four artifacts and
   linkage, including a repeated run with another run between repetitions.
5. Run existing page-56/page-57 controls, CLI compositions, saved final-output
   analyses and path/integrity regressions. Run the focused suite and then the
   full suite; do not rewrite expected plaintext to make the new chain pass.

## Approach

- `lib/primus/experiment.rb` and `experiment/composition.rb`: delegate step
  parsing/validation to an owned `Steps`/`Step` model; retain existing input,
  checks and file-validation behavior. Canonical data conversion happens at
  YAML/JSON boundaries; callers use direct readers, not nested hash traversal.
- Add `experiment/chain.rb` and `experiment/checkpoint.rb` for execution and
  owned evidence. Keep the operation set explicit and small. Totient and Latin
  transformation objects own their parameters/behavior. Reuse existing GP
  lookup and totient semantics; avoid a second divergent arithmetic engine.
  A narrow adapter may use the current visitor on an interpreted view and map
  results back by source identity into fresh lexical tokens. It must preserve
  exact non-rune input and be tested independently of final rendering.
- `experiment/runner.rb`: replace `derive`/inline production with the composed
  chain and checkpoint publication; leave evaluation lifecycle intact.
  `experiment/store.rb` and `log_entry.rb`: delegate checkpoint persistence/
  reading to a focused owned object if needed; expose useful readers without
  making LogEntry or Runner navigate checkpoint record internals.
- `experiment/observation.rb`: ensure deep ownership at capture rather than
  relying on its current shallow provenance freeze. Keep final-symbol manifest
  and Analysis::ObservationReader contract intact; add regression coverage.
- `commands/experiments.rb`: show checkpoint summary through domain readers;
  keep current command family and recipe conveniences. Update relevant README
  examples, editable definitions and fixtures during implementation. Analyses
  remain in `experiments/analyses/*.yml`, separate from transformation steps.
- Keep new objects cohesive and within the project's class/method/parameter
  guidance; do not add one class per scalar, forwarding chains, a migration
  layer or a generalized operation/plugin framework.

## Edge cases

- Punctuation, mixed CRLF/LF, trailing whitespace, GP digraphs and unknown
  non-rune characters survive rune steps; compatibility output remains its
  separately named view. Empty/no-GP source retains existing rejection.
- Skip ordinal zero/last/all runes; all skipped consumes no primes; unordered
  skip input canonicalizes, but duplicate/out-of-range/negative skips reject.
- Two identical operations or byte-identical checkpoints still have different
  IDs/parents. Changing a step ID changes recorded identity intentionally.
- Write failure after earlier checkpoint publication leaves readable earlier
  evidence and an incomplete/error attempt, never a false successful final.
- Readers do not trust serialized absolute paths or inconsistent checksum
  declarations; capture/read use the same bytes to avoid reread gaps.

## Out of scope

Stage-targeted analyses/windows, original-input analysis, new analyzers,
checkpoint hash assessments, resuming chains, cross-run reuse, more algorithms,
new cipher families, structural reversals in experiment chains, multi-page
reset/continuation semantics, branching/search, page-55 chain trials and proof
of decipherment. Existing standalone reversals are unaffected. No run deletion,
backfill, pre-v1 migration/backward-compatibility infrastructure, push or PR.

## Open questions

No blocking decision is required for this bounded increment. The intentional
scope choice is independent repeated totient layers plus terminal Latin;
reversal/Atbash/keyed chains require later operation-specific plans and controls.
This plan supersedes older claims that step syntax/checkpoints still await a
planning choice, but does not authorize actual page-55 trials. After review,
hand this plan and the independent oracle preparation to test-writer; do not
implement or run research experiments as part of this planning pass.
