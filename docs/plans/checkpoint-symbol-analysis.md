# Saved-checkpoint symbol analysis

## Goal

Analyze original input, a declared transformation step, or final output from a
retained run without executing transformations again. Keep existing GP-rune and
canonical expanded-Latin frequencies/raw IC, with verified checkpoint identity
and artifact checksums attached to every retained analysis.

## Baseline and prerequisite assessment

Inspected clean local `main` at `abc54e1` on 2026-10-18, after the merged
transformation-checkpoint implementation. Start `codex/checkpoint-symbol-analysis`
from that commit, not an older cached baseline. The preceding reported suite was
775 examples, zero failures, 12 pending; no tests run during this docs-only pass.

No prerequisite refactor is needed. Analysis already separates ObservationReader,
owned Observation, Runner, LogEntry and RecordValidator. Experiment's
CheckpointEvidence already validates checkpoint artifacts and lineage, but its
`verify!` discards captured bytes/rows. Adding owned verified readers there is a
feature requirement, not a separate architectural cleanup. Reuse that verification
boundary; do not clone its validation into Analysis or route through Store review
(which also loads unrelated assessments).

## Acceptance criteria

### Selection and existing behavior

- Keep the existing analyses run/review command family, explicit experiment/run
  IDs and analysis YAML shape. Extend each `target.stage` from `final` to
  `original`, `final`, or a safe declared step ID. Do not introduce numeric
  ordinals, checkpoint UUID selectors, filesystem paths or a second CLI selector.
- Keep one or two declarations, unique IDs and unique representations. All
  declarations in one definition must name the same stage. One invocation owns
  one selected Observation; separate invocations compare checkpoints. Reject
  mixed stages clearly, including `final` plus its terminal step ID in one file.
- Definition validates selector syntax; reading resolves membership against the
  saved run configuration. Reject missing, unknown, unsafe or uncaptured stages
  before reserving an analysis run. IDs of repeated operations remain distinct.
- `original` selects the capture before any transformation: exact source-body
  bytes and their saved GP symbols, not YAML text, a reloaded source file, or a
  Latin view. `final` resolves through `final_checkpoint_id` to the actual
  terminal Latin step; selecting that declared ID produces equal measurements
  and artifact identity. Retain both requested selector and resolved identity.
- Only finished runs are eligible. A finished error attempt with valid completed
  earlier checkpoints may analyze those retained checkpoints; never fabricate an
  uncaptured stage or final. Assessment failure after terminal capture does not
  prevent final analysis. Running/unfinished runs reject. No hash backend or
  unrelated assessment file is needed.
- Existing definitions targeting final produce unchanged frequencies, counts,
  raw IC, exclusions and output/provenance checksums. Root final projection must
  still be verified and agree with the terminal capture. Missing checkpoint
  metadata may require recreating disposable pre-v1 runs; do not build a legacy
  reader or silently infer checkpoints from output text.

### Verified evidence and measurement

- Read the run record once with StrictData, validate run identity/completion,
  resolve the selector, and verify checkpoint evidence before returning an
  Observation. Preserve the existing full retained-chain verifier: all retained
  checkpoint artifacts and lineage must pass, including original/source-body
  binding and final linkage. Corrupt siblings therefore reject this increment;
  selective verification is not an additional feature.
- Extend CheckpointEvidence to retain deeply owned verified snapshots, expose a
  direct selected-checkpoint query by step ID, and make `verify!` return nil.
  A snapshot exposes identity, operation/parameters, policy, output bytes,
  symbols, lexemes and artifact metadata. It is not a fake live Checkpoint and
  does not need a Transcription. No partial verified snapshot escapes on error.
- ObservationReader consumes those already captured rows/bytes/metadata, without
  reopening them after validation. Checkpoint JSON uses strict duplicate-key and
  UTF-8 handling. Verify known GP runes, canonical expansion agreement, integer
  source coordinates, unique source identities, contiguous symbol ordinals and
  declared operation/policy/representation alongside existing lexical mappings.
  Reject malformed data through the documented reader error boundary.
- Both representations derive only from the selected captured GP symbol rows.
  Rune symbols count once; Latin symbols are canonical GP expansions split into
  letters. Never scan output.txt for Latin letters or reconstruct rune streams
  from rendered text. Passthrough ASCII words, digits and punctuation contribute
  no symbols. Rune and Latin analysis alphabets remain 29 and 26 respectively.
- Reuse SymbolStatistics unchanged: full ordered bins including zeros, sample
  size, distinct count, relative frequencies and raw IC = sum(n*(n-1))/(N*(N-1)).
  For N below two preserve insufficient_sample/nil value semantics. No language
  scores, ranking, significance claim or implication that higher IC is progress.
- Observation owns immutable symbols/profiles and evidence with no file I/O.
  Later file/caller mutation cannot change its statistics or identity. Copy
  nested owned values without freezing caller objects; no extra reread gap.
- Retain experiment/run identity, captured run-record SHA-256, requested stage,
  resolved checkpoint UUID, step ID, ordinal, parent ID, operation/parameters,
  representation/policy, source identity, and output/symbols/lexemes metadata
  (path, byte length, SHA-256). Bind profiles and each result envelope to this
  selected evidence. Keep final root provenance evidence for existing final
  behavior; do not mislabel symbols.json as provenance.json.
- Review reads stored measurements and evidence without rerunning transformations
  or analysis. RecordValidator rejects contradictory stage/checkpoint/profile
  identities and malformed artifact metadata. Show requested selector, resolved
  step/UUID, representation, selected checksums and results; remove hardcoded
  `final` labels. An edited definition cannot relabel historical results.
- New analysis attempts append under the existing run analyses directory. They
  do not modify run artifacts or older analyses. Invalid inputs create no
  completed analysis; persistence failures retain existing error/incomplete
  behavior. Equal checkpoint bytes never collapse distinct checkpoint identity.

## Independent control and test-writer handoff

Extend the existing literal oracle note in
`spec/fixtures/experiments/transformation_checkpoints_oracle.md` before writing
feature expectations. Verify arithmetic and counts independently of production
Runner, Parser, Printer, Gematria lookup and SymbolStatistics. The existing
four-rune fixture has these nonzero bins (all omitted bins are zero):

| Capture | Rune bins (each count 1) | Expanded Latin bins (each count 1) | Rune N / IC | Latin N / IC |
| --- | --- | --- | --- | --- |
| original | ᚳ ᚻ ᛇ ᛒ | c h e o b | 4 / 0/12 | 5 / 0/20 |
| first | ᚱ ᚻ ᛁ ᛈ | r h i p | 4 / 0/12 | 4 / 0/12 |
| second | ᚦ ᚱ ᛁ ᚹ | t h r i w | 4 / 0/12 | 5 / 0/20 |
| letters / final | ᚦ ᚱ ᛁ ᚹ | t h r i w | 4 / 0/12 | 5 / 0/20 |

Relative frequencies are 1/N. Preserve its literal exact outputs, independent
SHA-256s and source coordinates. Add a companion nonzero-IC layered control:
source `ᚦᚪᚦ`, first totient start 2/skip [1], second start 3/skip [2], terminal
Latin. Hand indices are (2,24,2) -> (1,24,0) -> (28,20,0); rune strings are
`ᚦᚪᚦ` -> `ᚢᚪᚠ` -> `ᛠᛚᚠ`, terminal `ealf`. Original rune counts TH=2,A=1
have N=3, distinct=2, numerator=2, denominator=6, IC=1/3. Original expanded
`thath` has t=2,h=2,a=1, N=5, distinct=3, numerator=4, denominator=20,
IC=1/5. First `uaf` has N=3 and IC=0/6 in both representations. Second/final
has three unique runes (IC=0/6) and `ealf` four unique letters (IC=0/12).
Freeze independently checked literal bytes/digests during test writing.

Test in order:

1. Definition selection and run resolution, including mixed-stage rejection,
   unknown steps, original, terminal ID/final alias, and partial finished runs.
2. Verified captured readers and ownership; corruption, containment and strict
   parsing; no artifact rereads or live-source dependency.
3. End-to-end both controls through saved checkpoints and analyses. After
   creating the run, make transformation calls fail if invoked during analysis.
   Compare literal statistics and identity for every stage; final equals terminal
   ID numerically but preserves requested selector. Add passthrough ASCII to a
   control and prove it does not enter expanded-Latin counts.
4. Retained record/review, altered definitions, repeat analysis append behavior,
   and existing final page-56/page-57 analysis regressions. Keep generic empty
   and singleton statistics tests without adding a synthetic production input API.
5. Focused changed specs then full suite, with no research trials or changed
   expected plaintext to obtain passing tests.

## Approach

- `lib/primus/analysis/definition.rb`: validate bounded selectors and expose a
  direct stage reader for the shared target, keeping raw YAML at this boundary.
- `experiment/checkpoint_evidence.rb`: keep artifact verification authoritative
  and expose owned captured checkpoint evidence after successful verification.
  Use a small noun-named evidence value only if it earns responsibility; avoid
  per-scalar objects or gratuitous forwarding. Update Store's existing call only
  as required by the verifier's nil-returning command contract.
- `analysis/observation_reader.rb`: replace final-only input assumptions with
  checkpoint selection through that verifier; retain final projection validation
  for final/terminal targets. Build both profiles from verified captured symbols.
  Keep normalization at serialization boundaries, not raw nested traversal in
  Runner or CLI. Shared checks belong to their existing verifier, not a second
  reader-specific copy. Preserve current safe lexical/realpath resolution.
- `analysis/observation.rb`: expose selected identity directly and retain owned
  evidence/profile state. Runner keeps its one-observation contract and nil-returning
  `run`; selection must not become branching orchestration there.
- `analysis/log_entry.rb`, `record_validator.rb`, `commands/analyses.rb`: persist,
  validate and display selected identity instead of hardcoded final envelopes.
  Result remains a measurement; selected checkpoint context belongs to the owned
  LogEntry/Observation, not forwarding methods on every measurement.
- Update relevant analysis definition, reader, observation, runner, log-entry,
  validator, store and command specs, checkpoint-evidence coverage and fixture
  oracle; README and a bounded original/intermediate definition example during
  implementation. No Source/Transcription, transformation or analyzer changes.
- Keep pre-v1 formats simple; update fixtures together, with no migration/backfill
  service. Follow existing class/method/parameter limits through focused ownership,
  not a general framework. No Rails dependency or ActiveRecord machinery is needed.

## Edge cases

- Traversal, absolute/unsafe selectors, escaped symlinks, record-path aliases,
  missing/truncated artifacts, wrong byte counts/digests, duplicate JSON keys,
  invalid UTF-8, duplicated/missing checkpoint IDs, incorrect parents/ordinals,
  altered operation/parameters and conflicting final root projection all reject.
- Correctly recomputed artifact digests do not excuse contradictory symbol/lexeme
  mappings, unknown runes, expansion maps, source identity or sample counts.
  Checksums identify captured evidence; they do not authenticate an adversary's
  fully rewritten history or prove transformation arithmetic.
- CRLF, trailing whitespace, omitted final delimiters and digraph expansions
  affect artifact bytes independently of symbol counts. Original capture remains
  distinct even when its bytes equal a later checkpoint's bytes.
- Source file removed or changed after capture must not trigger a reload or
  transformation rerun. Invalid source-body snapshot still rejects.
- Finished chain failure with retained original/earlier steps is analyzable;
  nonexistent later checkpoint and final are not. Unrelated assessment corruption
  does not block checkpoint analysis, while checkpoint corruption does.

## Out of scope

Position windows and subranges, multiple checkpoints in one analysis invocation,
new analyzers, normalized IC, ranking/search, new transformations, reassessment,
hash checks on checkpoints, cross-run reuse, actual page-55 trials, source audits,
dependency changes, deleting runs, migration machinery, push or PR.

## Open questions and roadmap

No blocking question. The bounded choices are one shared stage per definition,
full retained-chain verification, and allowing captured checkpoints of finished
failed attempts. Revisit only on concrete evidence, not speculative abstractions.

After this milestone, plan further analyzers and other separately authorized
research capabilities against the then-current code. Position windows are deferred
to the VERY END of the broader roadmap, after those capabilities; they are not
this milestone, its immediate successor, or a prerequisite for analysis/research.
The existing independent chain control is complete; this plan adds independent
checkpoint measurement proof. It authorizes no page-55 trial or downstream agent
handoff during planning.
