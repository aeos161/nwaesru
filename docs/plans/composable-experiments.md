# Composable experiments

## Goal

Compose an input, a reusable transformation recipe, and independent checks
without creating a new scenario definition for every combination. Produce and
retain exact output bytes once, then assess those bytes with several checks or
append new assessments later without executing the recipe again.

This is a plan for human review, not authorization to begin implementation.
No cryptanalytic exploration or test-writer handoff accompanies this plan.

## Baseline and design assessment

Inspected baseline: clean `main` and local `origin/main` both at
`cadf7c5e93770a33220f070523e767c82f1ee91b`, containing the original BLAKE-512
integration. No remote refresh was needed or performed. Planning branch:
`codex/composable-experiments`, created from that baseline.

Current coupling is concrete:

- `Primus::Experiment::RECIPES` binds scenario ID, page number, source path,
  and operation. `HASH_ALGORITHMS` also selects expectation kind by scenario
  ID. Parameter validation singles out the page-56 scenario. Direct model
  construction assumes loader-owned `definition_data` exists.
- `Runner` builds/translates/derives once but assesses a singular expectation.
  Hash runtime selection is keyed to scenario ID. Its version-1 fingerprint
  combines the whole definition, source/oracle digests, Git HEAD, Ruby, and
  selected backend identity; deduplication is within an experiment ID.
- `Evaluator` already separates assessment from the frozen-byte `Observation`.
  `Assessment` and `LogEntry` expose one assessment. `Store` saves exact output,
  provenance and source/expectation/definition snapshots, with artifact digests,
  but reading an observation currently does not verify those digests.
- CLI IDs currently select filenames; review reads saved configuration for
  recorded runs. Five presets cover page-57 plaintext and three hash controls,
  plus page-56 totient plaintext.

These boundaries support incremental extension. No separate behavior-preserving
prerequisite refactor is necessary: separating scenario identity is the feature
itself. Do not manufacture a cleanup project to enforce method-length numbers.
Use the existing thin transcription/Document transformation chain.

## Vocabulary and configuration

Keep `Primus::Experiment` as the ActiveModel configuration aggregate. A preset
ID names a saved composition; an input ID names source selection; a recipe ID
names transformation behavior; a run ID names an execution attempt; an
observation reference identifies the saved output of that attempt; a check ID
names one requested assessment within a composition; an assessment ID names an
immutable assessment attempt. Do not overload any of these as another domain.
Initially observation identity is the pair `(experiment_id, run_id)`; a second
random observation identifier is unnecessary.

Add version-2 configuration with input, recipe (ID and validated parameters),
output policy, and an ordered checks collection. Each check contains an explicit
strategy (`plaintext` or `hash`), optional hash algorithm, and its expectation
plus provenance. Expectations are data, not transformation operations. Use small
owned input/recipe/check values where they remove branching; no extensible
registry or plugin framework. Hash choices remain `sha512`, `blake2b512`, and
`blake512`, each with an explicit 64-byte output length and backend identity.

Initially reusable recipes are `latin` and `totient-latin`, corresponding to
existing operations. Page-56 control parameters remain exact; reusable totient
execution validates modulus 29, positive prime starting value and nonnegative,
unique, in-range skip ordinals rather than inferring parameters from page ID.
Inputs resolve repository page artifacts independently of recipe/check choices;
retain original artifact bytes, page metadata and selected body provenance.
Whole-page selection is the first slice. Explicit section selection, if exposed,
must use a declared source-coordinate range and preserve original offsets; do
not silently implement arbitrary text slicing or a second transcription parser.
Section selection can follow the whole-page feature after review.

Both YAML and CLI hydrate the same model and validations. Preserve all five
version-1 preset files and their entrypoints unchanged; adapt their semantic
configuration to a single check at the model boundary while retaining original
raw configuration/bytes and the version-1 identity path. Add one version-2 example
preset demonstrating composition rather than generating a Cartesian set.

## Proposed CLI contract

Examples are proposed interface contracts, not commands to run during planning:

```
bin/primus experiments run --input page-57 --recipe latin --hash blake512 --hash blake2b512 --hash sha512 --expect-digest HEX
bin/primus experiments run --input page-57 --recipe latin --expect-text experiments/expected/page-57-latin.txt
bin/primus experiments run --input page-57 --recipe latin --hash sha512 --expect-digest sha512=HEX --hash blake512 --expect-digest blake512=HEX
bin/primus experiments assess EXPERIMENT_ID RUN_ID --hash blake512 --expect-digest HEX
bin/primus experiments run page-57-latin-sha512
bin/primus experiments review EXPERIMENT_ID RUN_ID
```

Use `--input` instead of a second interpretation of positional ID: old positional
IDs remain presets. `assess` clearly names new checks on existing bytes; `review`
remains read-only. Add corresponding composition options to `validate`.

A bare digest is one shared unknown-algorithm target applied to all selected
hashes; algorithm-qualified digests are distinct known-answer expectations.
Reject mixing shared and qualified forms, duplicate algorithm declarations,
missing/extra expectations, conflicting options and unsupported algorithms.
`--expect-text` adds a byte-for-byte plaintext check; it can accompany hash
checks but does not silently derive their expected digests from the output.
Require expectation provenance in YAML; CLI accepts `--expect-provenance`, with
an honest default of user-supplied CLI expectation (not independently verified).

Preset plus composition overrides opts into v2. Supplied input/recipe replaces
that component; any check/expectation option replaces the entire checks set,
never partially inherits an old oracle. Omitted components retain preset values.
An overridden input is reloaded and snapshotted; an old declared source checksum
must not be silently reused for a different source. Without a preset, input and
recipe are required, policy defaults explicitly to the existing compatibility
policy, and a deterministic `ad-hoc-<configuration digest>` experiment ID gives
history a stable namespace. Print that ID and run ID. Persist actual normalized
choices, defaults and overrides, plus preset origin/raw bytes if present.

Repeated flags must genuinely accumulate with Thor, not silently retain only
the last occurrence. Keep file input explicit (`--expect-text`); a digest is
always literal hexadecimal, never interpreted as a path. Validate repository
containment and symlink resolution for all read/write paths; reject output overlap
with every source and oracle. No shell expansion or implicit normalization of
expected plaintext, output newlines, case, BOM, or whitespace.

## Acceptance criteria

- The same page and recipe can be used with plaintext or any combination of the
  three supported hash checks without a new hardcoded scenario ID or YAML file.
- CLI and equivalent YAML produce equal canonical semantic configuration.
  Standard model validators and custom cross-field rules reject invalid input,
  recipe, parameters, policy, checks and expectations before transformation.
- Validation is offline: it checks configuration/source/oracle integrity and
  digest syntax/length without requiring hash backend availability. A 64-byte
  target cannot be compared to a 32-byte algorithm; unsupported SHA-256 remains
  unsupported, not a request to implement it. Persist lengths in bytes and
  validate exactly twice that many hex characters; retain lowercase convention.
- A valid fresh run executes the recipe once and saves exact output/provenance
  before assessment. Every check reads that same immutable byte sequence.
- A mismatch is a normal completed comparison, not an exception or early exit.
  Each later check still executes. A backend unavailable/error result is recorded
  against that check and does not discard the observation or other results.
- Known-answer checks can compare independent plaintext bytes or separate
  algorithm-specific digests. Unknown-algorithm research can compare all selected
  compatible hashes with one target. No confidence score or inferred ranking is
  invented; each result states what was compared.
- `assess` verifies the referenced saved output and provenance, uses its saved
  policy, then appends new assessment attempts without source files, original
  preset, transformation code execution, or original hash backend availability.
  Changed/deleted source or oracle files from the original run do not block it.
- Missing/corrupt output/provenance or absent verification metadata fails closed
  for reassessment with a concrete integrity error; historical review remains
  readable and reports the problem. No fallback rebuild or invented provenance.
- Review shows each check's strategy, expected and observed result, policy,
  expectation provenance, backend/runtime identity, timestamp and errors, using
  only saved records. Editing today's preset cannot relabel yesterday's results.
- All five v1 preset commands, expected bytes/digests, old saved single-assessment
  records and old deduplication behavior remain supported without rewriting them.
- `Runner#run` and the assessment command remain commands returning nil with
  owned Observation/Assessment/LogEntry state. Do not replace these with hashes
  or add layers of forwarding methods to simulate encapsulation.

## Approach

### Identity, persistence and reuse

Introduce explicitly versioned v2 identities. Recipe execution identity includes
source artifact digest/selection, recipe and parameters, output policy, execution
code Git HEAD and Ruby identity. Exclude title, preset filename, checks,
expectations and hash backends. Assessment identity includes the verified output
SHA-256, saved policy, normalized check and expectation content/provenance,
assessment code/runtime and relevant backend identity. Preserve original BLAKE
native/source/gem identity fields and the existing exclusion of transient error
message wording from identity. Probe each backend independently.

A v2 `run` searches valid completed observations by execution identity, including
across preset/ad-hoc namespaces. A hit explicitly reports reuse and references
the original observation; it never claims a new transformation occurred. Changed
checks reuse that observation and get their own assessment identity. Exact repeat
checks may return the prior assessment with an explicit reuse indication.
Invalid/error/running attempts are not successful output cache entries.
`--rerun --reason` forces a fresh transformation and links prior attempt IDs.
For `assess`, the same option forces a fresh assessment attempt only; document
that distinction. Repeated explicit assessments otherwise deduplicate by identity.

Keep v1 fingerprint construction and per-ID lookup untouched for unmodified v1
requests. No old record receives a guessed v2 execution identity, and v2 automatic
reuse initially considers v2 observations only. Explicit `assess` may reference a
v1 observation if saved artifact checksums and policy/provenance suffice. It adds
a v2 assessment record with a legacy observation reference, not a migrated run.

Extend `Store`, rather than introducing a second storage backend. New run records
use schema version 2 with a saved canonical configuration and observation
reference. Store assessments as separate uniquely named records under an
assessment history directory, each referencing the immutable observation and
capturing check configuration, expectation snapshots, runtime, status and errors.
No later check calls `finish` on an old run or overwrites its artifacts. Once a
run/assessment record is finalized it is immutable; running-to-final transition
retains the existing atomic-record technique. Unique attempt directories prevent
concurrent overwrites; best-effort dedup may permit simultaneous equivalent
attempts, which remain separately visible rather than pretending exactly-once
execution. Persist interrupted/running entries and never reuse them as successes.

Reassessment reads artifacts through a verified Store boundary: resolve paths
inside the recorded run directory, reject symlink escapes, compare byte count and
SHA-256 with recorded metadata, parse saved provenance safely and retain its
association with output/policy. A failed verification appends a failed assessment
attempt where safely possible and does not alter the original run. Assessment
expectation snapshots are separate from original oracle snapshots. Avoid copying
output files into every assessment.

Preserve per-check `match`, `mismatch`, or `error/not_checked` semantics. For new
multi-check records use a completion summary (completed or error, with match,
mismatch and error counts); a mixture of matches/mismatches is useful evidence,
not one misleading scientific verdict. CLI exits unsuccessfully on any mismatch
or error for consistency with controls, but prints all results first; distinguish
invalid configuration, execution failure and check failure in saved stages and
messages. Legacy single-check status strings remain unchanged.

### Likely files

- `lib/primus/experiment.rb`: shared model construction and validation; replace
  scenario-keyed rules for v2 with explicit input/recipe/check values. Retain v1
  loader safety, duplicate/unknown-key rejection and compatibility adapter.
- `lib/primus/experiment/input.rb`, `recipe.rb`, `check.rb` (if justified): focused
  owned configuration/behavior values, using ActiveModel conventions where useful.
  Extract only the responsibilities needed for this feature.
- `lib/primus/experiment/runner.rb`: run orchestration, observation reuse and
  persisted output before checks. Move existing recipe execution into the focused
  recipe collaborator instead of adding another scenario case statement.
- `lib/primus/experiment/evaluator.rb`, `assessment.rb`, and a focused
  `assessor.rb`: one-check evaluation, collection orchestration and assessment of
  persisted observations; runtime selection follows algorithm, never preset ID.
- `lib/primus/experiment/store.rb`, `log_entry.rb`, `observation.rb`: v2 record
  serialization, explicit observation references, verification and additive
  histories; backwards-compatible v1 reads. Keep values owned and bytes frozen.
- `lib/primus/commands/experiments.rb`: composition parsing, thin command calls,
  new `assess`, complete multi-check display and backwards-compatible review.
- `experiments/definitions/`: one v2 demonstration; original controls unchanged.
  `README.md`: composition, expectation modes, reuse/rerun and assessment history.
- Corresponding fully namespaced specs under `spec/lib/primus/experiment/` and
  `spec/lib/primus/commands/experiments_spec.rb`, plus model validation specs.
  Consolidate added behavior under appropriate classes/methods rather than
  proliferating algorithm-specific wrapper specs.

## Scoped implementation increments and test-writer handoff

After human review, deliver these vertical slices in order:

1. Pin existing v1 CLI/control/history behavior with necessary green
   characterization coverage, then add v2 whole-page + `latin` + one plaintext
   or hash check through validate/run/review. Shared model construction and
   canonical saved config must work from both CLI and YAML; existing v1 controls
   remain green. Establish v2 record shape and separate execution identity here.
2. Add repeated hashes, shared/qualified expectations and one-observation
   multi-check execution. Exercise mismatch followed by match, unavailable
   backend followed by successful backend, and all failure results. Persist
   output before assessment and expose independent assessments in review.
3. Add verified saved-output `assess`, immutable appended records and explicit
   observation reuse/dedup/rerun. Prove it works after deleting original input and
   preset, preserves old result bytes, rejects tampered artifacts and handles
   legacy v1 observations without rewriting them. Pin missing/partial records.
4. Complete reusable totient recipe/parameter validation and preset override
   boundaries; add the v2 example and user documentation. Run all relevant
   regression coverage and report any baseline failures separately.

Start each new behavior with a CLI boundary example, then work inward only where
an independent contract needs unit coverage. Meaningful examples include exact
output bytes under the established policy, saved literal expected/observed
digests, configuration conflicts, impossible digest lengths, source/policy changes
invalidating output reuse, expectation/backend changes invalidating only
assessment reuse, forced rerun lineage, and historical review without backends.
Do not generate expectations with the implementation being tested.

Use one outer `describe Primus::Fully::QualifiedClass`, method-named nested
blocks (including testing constants through the behavior they constrain), no
`let`, one behavior and one expectation per example, and explicit phase spacing.
Do not bundle unrelated outcomes into tuple expectations or assert unrelated
error prose. Shoulda covers supported standard validations; custom cross-field
rules are model `valid?` behaviors, not ActiveModel internal tests. Preserve the
nil command contract explicitly where relevant. Five-line methods are a heuristic,
not a reason for forwarding bloat. No tests are authored in this planning step.

At implementation start verify targeted experiment/CLI specs on the baseline,
then run those and touched-code lint after each meaningful slice. Run the full
suite once for final regression accounting. Two previously reported failures in
`Primus::LiberPrimus.page`/`.chapter` must be verified and reported separately,
never hidden or silently fixed as part of this feature. This planning step did
not execute tests and makes no fresh green-baseline claim.

## Edge cases

- Empty exact output and empty expected text are valid bytes if the recipe can
  produce them; empty digest or absent check collection is invalid.
- Duplicate YAML keys, unknown fields, malformed UTF-8 inputs, wrong source
  checksums, unsafe paths, malformed algorithm-qualified values and repeated
  conflicting flags must not become silent defaults.
- Input selection/provenance coordinates, output policy, recipe parameters and
  executable-code identity are scientific provenance, not display-only labels.
- Backend probing failure must not prevent other checks; transformation failure
  prevents every check and records why no observation exists.
- Disk-write failure is infrastructure failure: do not claim saved evidence or
  continue assessing an output whose required persistence failed.
- Unsupported/future record schema gives a clear read error, not guessed fields.
  Missing artifact metadata is reviewable history but ineligible for reassessment.
- A moved run directory should use contained relative artifact references for v2;
  legacy absolute paths are read compatibly and only reassessed when verified.

## Out of scope

New algorithms (including SHA-256 assessment), cryptanalytic search, ranking,
language scoring, brute-force recipe generation, network lookup, arbitrary user
code/plugins, alternate byte-normalization policies, automatic v1 history
migration, deletion of controls, and rewrites of transcription/Document APIs.
No changes to the standalone BLAKE-512 gem, dependency version, packaging or its
deferred Phase 5 CI/platform/release work. No push or implementation in this step.

## Open questions for review

The plan proposes explicit `--input` and `assess`, replacement of the whole checks
set on override, lowercase hex, and first delivery limited to whole pages. These
are reviewable interface decisions, not hidden prerequisites. Confirm whether
section-range selection must ship in this first feature; doing so needs a precise
coordinate convention before writing those acceptance tests. The core design and
whole-page increments do not depend on that extension.
