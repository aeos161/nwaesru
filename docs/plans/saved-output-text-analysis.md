# Saved-output symbol frequencies and index of coincidence

## Current milestone — 2026-10-18

Explicit transformation checkpoints are merged on local `main` at `abc54e1`,
after saved-output analysis (`daddc5a`) and reusable totient/page-56 controls
(`d98c722`). The next bounded milestone is
[saved-checkpoint symbol analysis](checkpoint-symbol-analysis.md): select original,
a declared step ID, or final; verify retained evidence; compute the existing
GP-rune/expanded-Latin statistics without rerunning transformations.

Further analyzers and other separately authorized research capabilities follow
through fresh plans. **Position windows are deferred to the VERY END of the
broader roadmap**, not the next increment or a prerequisite. Older current/next
and pending-review statements below are dated history. No page-55 trial, run
deletion or migration is authorized by this planning update.


## Review refactor — 2026-10-10 (current work)

### Goal

Separate verified analysis input from file loading, and represent an analysis
execution with a LogEntry rather than a raw record hash. Rename the retained
record validator explicitly while preserving the implemented CLI, measurements,
artifact schema and integrity behavior.

This section supersedes earlier implementation-shape proposals below. The
original feature criteria remain the behavioral contract; the earlier baseline
and handoff notes are historical. Inspected HEAD is `4a8d54d`, with a clean
checkout on `codex/saved-output-text-analysis`. The user approved this revision
to the in-flight work: keep that branch and its implementation. This is the
requested refactor itself, not an unmerged prerequisite to a new feature.
No further preparatory refactor is indicated. No data cleanup is necessary.

### Acceptance criteria

- Replace `SavedObservation` with `ObservationReader` and `Observation`.
  Reader owns path resolution, file reads, StrictData parsing and all existing
  record/artifact/profile/provenance validation. Its `to_observation` query
  returns a verified Observation only after every check passes. No partially
  verified input escapes on failure. Use `ObservationReader::Error` at this
  boundary and update its callers/rescue clauses.
- Observation owns the captured, verified values used by analysis. It performs
  no file reads, record validation or cipher execution. Its direct API serves
  existing callers: `symbols(representation)`, `alphabet(representation)`,
  `profile(representation)`, observation identity and directory, plus an
  `evidence` snapshot containing the already captured record digest, output/
  provenance artifact metadata, representations and output policy required
  for persistence. Runner no longer understands observation-record nesting or
  computes its digest from exposed raw bytes. Do not expose `record` or
  `record_bytes` as the ordinary analysis API.
- Snapshot ownership matters: modifying caller-owned structures or files
  after successful reading cannot change that Observation's symbols, alphabet,
  profiles or evidence. Copy owned structures before deeply freezing them;
  do not freeze a caller's mutable input as a side effect. Reuse the captured
  bytes for validation and identity; the split must introduce no reread gap.
- Preserve the exact current acceptance/rejection boundary: lexical and real
  paths (including macOS temporary-root aliases), symlink containment, artifact
  size/digest checks, finished observation identity, output policy, both
  manifests, canonical expansion map, source coordinates/identity uniqueness,
  ordinals, decoded rune and Latin agreement, and sample sizes. Do not add a
  new schema migration or strengthen unrelated validation as part of moving it.
- Rename `RetainedRecord`/`retained_record.rb` to
  `RecordValidator`/`record_validator.rb`. Preserve its `validate!` responsibility
  and error behavior, with the renamed error constant. Store still validates
  parsed retained data, path identity and definition digest before constructing
  a LogEntry. LogEntry does not read files or replace RecordValidator.
- Add `Analysis::LogEntry` for one execution: observation identity, analysis
  run identity, status, ordered measurements, retained evidence/execution
  metadata and errors. `Runner#run` remains a nil-returning command;
  `Runner#log_entry` replaces `Runner#record`. `Store#review` returns LogEntries
  for running, completed and error records. Both live and reviewed entries
  provide the same meaningful query API; a caller does not need JSON keys.
- LogEntry owns lifecycle transitions and their associated values: running
  starts with no measurements, completion retains ordered Results and a finish
  time, failure retains execution errors and a finish time. Keep ID format and
  current persistence ordering/atomic writes. Once finalized, exposed values
  cannot be mutated by callers. A failure to save is still raised; the exposed
  entry must not imply that an unsaved completion is retained successfully.
- Reuse the existing `Analysis::Result` for each scientific measurement and add
  only the direct readers its consumers require: declaration/representation,
  alphabet/sample/distinct counts, frequencies and IC. Keep execution status
  and errors on LogEntry. Stored result-envelope metadata (analyzer/version,
  stage, profile and exclusions) is retained without introducing a second
  generic measurement wrapper. JSON serialization may use hashes at the Store
  boundary; Runner, review and CLI consume owned objects, not their `to_h`.
- Give LogEntry direct identity/status/errors/measurements queries and the
  metadata needed by the existing CLI, with a meaningful observation-identity
  comparison for review. Keep frequency bins and IC as immutable leaf data;
  do not invent a class per scalar or a chain of forwarding objects. No raw
  record-shaped `data` escape hatch merely renames the existing coupling.
- Persist exactly the existing JSON keys, result order, definition snapshots,
  timestamps/status semantics and artifact paths. `to_h` at the persistence
  boundary recreates the existing payload, including retained metadata, without
  recalculation. Review still works without source artifacts or today's
  definitions/backends. Preserve CLI command syntax, successful display and
  failure exit behavior; internal class-name changes are not a reason to change
  user-facing errors or couple tests to their wording.
- `strict_data.rb` remains byte-for-byte unchanged. Move the existing ID regex
  constants out of the removed class to the existing `Primus::Analysis`
  namespace (`ID`, `RUN_ID`), updating Reader, Store, RecordValidator and CLI.
  Do not create an identity service for two format constants. Remove obsolete
  requires/references; no SavedObservation/RetainedRecord compatibility aliases.

### Approach

| Files | Scoped change |
| --- | --- |
| `lib/primus/analysis/observation_reader.rb`, `observation.rb` | Move the current SavedObservation I/O and verification into Reader; verified input and symbol projection into Observation. Remove `saved_observation.rb`. |
| `lib/primus/analysis/log_entry.rb`, `result.rb` | Execution ownership and direct scientific readers; existing wire serialization preserved. |
| `lib/primus/analysis/record_validator.rb` | Rename the current validator without broadening its job. Remove `retained_record.rb`. |
| `lib/primus/analysis/runner.rb`, `store.rb` | Coordinate through Observation/LogEntry; Store validates before restoring an entry and serializes only at its file boundary. |
| `lib/primus/commands/analyses.rb`, `lib/primus/analysis.rb`, `lib/primus.rb` | Use Reader and LogEntry queries; relocate ID constants and update load order. |

Retain the implementation's clear ownership: Store handles files and directory
reservation; LogEntry handles one attempt's data/state; Runner coordinates.
A small signature change to Store's internal reserve/finish calls is permitted
to accept LogEntry rather than a mutable hash. Set identity on the owned entry
before persisting its first record; preserve collision rejection and incomplete
attempt behavior. No new registry, serializer framework or catch-all service.
Respect Ruby method/class limits through meaningful methods, not forwarding
layers. StrictData and the statistical algorithm are outside this refactor.

### Test-first sequence

1. First run/retain green characterization coverage in
   `spec/features/analyze_saved_output_spec.rb` and
   `spec/lib/primus/analysis/symbol_statistics_spec.rb`. Add only missing
   boundary pins before changing implementation: exact persisted shape/result
   order, CLI output, source-independent review, rejection before reservation,
   and saved error/incomplete behavior. Do not treat these passing as a failure
   of TDD; do not rewrite expected behavior when extraction breaks it.
2. Add genuinely red API behavior at full namespace paths:
   `spec/lib/primus/analysis/observation_reader_spec.rb`,
   `observation_spec.rb`, `log_entry_spec.rb`, `record_validator_spec.rb`,
   `runner_spec.rb` and `store_spec.rb` in that same directory, only where each
   owns behavior. Exercise Reader via actual tiny retained files; assert
   verified symbols/evidence and error type, not object class. Exercise
   Observation snapshot independence without duplicating all Reader rejection
   cases. Keep validation rejection coverage at one boundary rather than copy
   every CLI case into another unit suite.
3. Pin Runner's nil command return and LogEntry's useful identity/status/
   measurement/error queries. Pin retained restoration through Store review,
   including running/error entries and no source-artifact dependency. Cover
   mutation protection and exact wire preservation at the owning boundary;
   do not unit-test a thin serialization wrapper. An absent new constant or
   method is the expected red reason; incidental setup errors are not.
4. Update CLI integration to use the new objects while keeping existing
   success/failure assertions green. In touched examples, separate independent
   behaviors instead of combining exit status, error text and artifacts into
   one array assertion. Prefer error type or exit failure and a separate
   meaningful no-result assertion; do not pin prose regexes to make a renamed
   error boundary pass. Use one behavior/expectation, literal expected values,
   clear setup/exercise/verify, no `let` or heavy `before`, and frozen time when
   asserting timestamps. Do not reorganize unrelated specs.
5. Run focused new/object and lifecycle specs, then existing producer/experiment
   regressions and full suite; run scoped RuboCop. Record actual failures or
   observed flakiness with evidence, not inherited test totals. Review the diff
   to confirm StrictData unchanged, no old class references, no source-record
   digging in Runner/CLI, and no persisted-schema or numerical changes. This
   planning pass runs no tests and makes no implementation claims.

### Edge cases

Preserve both representation orders and insufficient-sample Results, completed
observations whose earlier hash check failed, absent/corrupt retained files,
source files disappearing after capture, and execution/persistence failures.
During read or write failure do not return a partially verified Observation or
label an incomplete record completed. Do not introduce a reader dependency
into historical LogEntry restoration. Keep internal renamed error types inside
the existing CLI error handling; do not swallow failures while wrapping them.

### Out of scope and open questions

No additional analyses, integrity-rule expansion, StrictData changes, file-format
migration, data deletion, new CLI features, generic value-object hierarchy,
legacy aliases, broad spec cleanup or dependency changes. No blocking questions:
the user chose ObservationReader/Observation, LogEntry and RecordValidator.
This plan update authorizes no downstream delegation by the planner.

## Original feature goal (historical planning)

Analyze an existing saved experiment observation without rerunning its recipe:
retain separate GP-rune and expanded-Latin frequency/IC AnalysisResults, linked
to the exact saved final output and decoded-rune provenance under a small
explicit representation contract. Keep measurements independent of expectation
assessments and reviewable without today's definition, input or hash backend.

This is step 1 only, approved for test-writer handoff after this update.
Until formal v1, current experiment formats, drafts and runs are disposable:
we may migrate or recreate them rather than build legacy compatibility. No
current files or runs are deleted or migrated by this planning update. No
page-55 analysis or new experiment execution is part of this planning task.

## Inspected baseline and design boundary

- Local `main` is `d98c722` (reusable totient/page-56 controls); cached
  `origin/main` is `45d4380`. Planning began on
  `codex/page-55-initial-experiments` at `8f4ebe6`. Use local main as the
  implementation baseline, not the older remote-tracking ref. The plan branch
  `codex/saved-output-text-analysis` starts at `8f4ebe6` to preserve the dirty
  checkout; that parent adds planning documents only, with the same code as
  local main. Git safely refused checkout from main because the roadmap
  would have been overwritten; no files were stashed or reset.
- Preserve the existing uncommitted `page-54-55-research.md` additions and
  both untracked page-55 definition drafts. This plan does not approve their
  provenance, change those files, or include them in its commit.
- The two user-created saved observations are
  `page-55-latin-target-baseline/20261008T193759-01fa878ed097` and
  `page-55-totient-latin-target-baseline/20261008T194016-49ab658b0fcb`.
  Read-only inspection verified the recorded size and SHA-256 of their output,
  provenance and source-body snapshots, with paths inside their run directories.
  Each has 76 ordered provenance entries with `decoded_rune`. No frequency or
  IC calculation was performed. These are candidates, not established plaintext.
- `Runner#provenance_for` already records original `rune`, final
  `decoded_rune`, canonical `latin`, output `ordinal`, and original source
  coordinates. The original and decoded rune are different concepts.
- `Store#saved_observation` currently trusts artifact paths and silently
  substitutes empty provenance if absent. It is insufficient for analysis.
  New analysis uses a stricter, separate reader and must not call this
  permissive path first. Current runs are disposable test data; there is no
  requirement to build a compatibility reader for them.
- `Primus.index_of_coincidence` currently divides the pair denominator by
  alphabet size, returning normalized IC (29 times raw IC for GP unigrams).
  Its API and `GematriaPrimus#expected_index_of_coincidence` remain unchanged;
  neither defines this new measurement contract.

No prerequisite refactor is required. New analysis collaborators can own the
new responsibilities with a small producer integration for an explicit final
rune manifest; no broad changes to Experiment, Runner or command classes. The analysis store is a separate Store
responsibility, not an extension of assessment state. Existing plans do not
identify an unmerged prerequisite for this bounded feature.

## Acceptance criteria

### Definition and command boundary

- Add a standalone analysis-definition format and `analyses` CLI group. An
  explicit saved experiment ID and run ID are mandatory; never choose the
  latest run implicitly. `--output-path` selects the existing run root.
- The proposed first supported definition is:

  ```yaml
  schema_version: 1
  id: final-symbol-statistics
  analyses:
    - id: rune-statistics
      analyzer: symbol-statistics
      version: 1
      target:
        stage: final
        representation: gp-runes-v1
    - id: latin-letter-statistics
      analyzer: symbol-statistics
      version: 1
      target:
        stage: final
        representation: gp-expanded-latin-v1
  ```

  Save the reusable definition at
  `experiments/analyses/final-symbol-statistics.yml` during implementation.
  This first version accepts one or two entries: either supported
  representation alone or both, with unique declaration IDs and at most one
  entry per representation. Only the shown analyzer/version and final stage
  are supported; absent, duplicate or unknown keys, aliases, invalid
  IDs, unsupported stages/representations and unexpected parameters fail
  validation. Use safe YAML loading and duplicate-key rejection. No implicit
  defaults that can change the meaning of a historical analysis.
- Proposed usage (not an existing command):

  ```sh
  bin/primus analyses run EXPERIMENT_ID RUN_ID \
    --definition experiments/analyses/final-symbol-statistics.yml
  bin/primus analyses review EXPERIMENT_ID RUN_ID
  bin/primus analyses review EXPERIMENT_ID RUN_ID ANALYSIS_RUN_ID
  ```

  The definition path is required for execution, not review. It is independent
  of the experiment recipe/preset and is snapshotted. There is one declaration
  method; do not add per-statistic CLI flags, preset overrides or implicit
  reuse of fields from today's experiment YAML.
- `final` is a logical label for the existing output/provenance pair; it does
  not claim a newly captured stage artifact exists. Future experiment YAML
  should describe individually ordered transformations in `steps`, followed
  by a separate `analyses` list referencing stages. This increment implements
  only the analysis-list subset above, in its own file. No working `steps`
  syntax, generic stage selector or migration of existing recipes is promised.
- The user explicitly allows migration of editable experiment drafts and
  considers all current runs disposable test data that may be deleted and
  recreated when implementation warrants it. Neither current draft syntax nor
  existing saved-run schemas impose permanent compatibility requirements.
  No migration or deletion is performed by this planning task. The forward
  design still keeps completed observations and appended analyses immutable
  during normal operation; test-data cleanup is separate from analysis.

### Explicit final-symbol capture and verified reading

- Add a minimal versioned representation manifest when a new observation is
  saved. Reuse existing `provenance.json`; do not add a duplicate rune stream.
  Store it under `observation.representations.gp-runes-v1`, containing
  `schema_version: 1`, `stage: final`, `artifact: provenance.json`,
  `symbol_field: decoded_rune`, the ordered 29-rune alphabet, sample size,
  and the SHA-256 of both `output.txt` and `provenance.json`. Declare the
  second profile at `observation.representations.gp-expanded-latin-v1` with
  the same final provenance source and digests, alphabet `a` through `z`,
  expanded sample size and an exact snapshot of the canonical GP-rune-to-Latin
  expansion map. Both profiles are emitted for each new observation. Existing
  artifact entries own paths, byte counts and checksums; no second stream or
  stage artifact is needed. The manifests bind both representations to the
  same final output/provenance pair.
- The producer derives this manifest from the same final Observation that
  supplies output and provenance, with checksums of the bytes actually saved.
  Add one small capture collaborator/integration to existing persistence,
  not a generic stage pipeline. Producer tests establish correct decoded rune,
  original source mapping, GP-only selection and Latin expansion behavior.
- Existing runs without this manifest are unsupported by the new analysis
  reader, with an actionable message to recreate the test run using the new
  capture contract. Do not retrofit unverifiable claims into old records or
  promise to analyze every current run. Recreating desired baselines is a
  later execution action; no page-55 run is executed or deleted now.
- Resolve only the selected `(experiment_id, run_id)` record. Validate safe
  path components, record/manifest shape and version, matching identities,
  finalized observation and the supported representation. A previous hash
  mismatch or backend failure does not invalidate intact saved output;
  a currently running producer or missing observation is ineligible.
- Verify output and provenance against their saved byte counts/SHA-256 and
  manifest bindings before use. Require the observation output byte count to
  agree and validate UTF-8 where text is required. Resolve expected named
  artifacts inside the selected run's real directory, checking recorded paths
  and symlink containment. Missing files, escaping paths, malformed metadata
  or mismatches fail closed. No fallback to live input or current presets.
- Require the saved output policy `gp-latin-compatibility-v1` and exactly the
  declared versioned alphabets/expansion map. Parse provenance as an array of entries with
  ordinal exactly `0...N`; each decoded rune is one declared GP symbol. Check
  both sample sizes, required source-coordinate fields and uniqueness of original
  source identities. Missing/duplicate/out-of-order rows, invalid symbols and
  malformed JSON fail explicitly; duplicate JSON keys must not silently win.
- `gp-runes-v1` measures ordered `decoded_rune` entries: a digraph rune is
  one sample symbol. `gp-expanded-latin-v1` expands those same decoded runes
  using the captured canonical map, concatenates expansions and counts their
  individual lowercase ASCII letters. Validate each saved `latin` field
  against that map; reject contradictions rather than silently choosing one.
- Latin selection is specifically **letters expanded from decoded GP tokens**,
  not every ASCII letter in `output.txt`. Both profiles exclude whitespace,
  punctuation and non-GP passthrough literals by construction, including the
  page-56 hexadecimal block. Literal-output-letter analysis is deferred and
  must have a different representation name if added later.
- Inspection of `data/gematria_primus.yml` confirms canonical expansions
  `th`, `eo`, `ng`, `oe`, `ae`, `io`, `ea`; alternatives such as `ing`, `ia`,
  `v`, `k` and `z` are not selected. Preserve canonical `u`, `c`, `s`, `ng`
  and `io`; no English normalization, alternative spelling substitution or
  extra case conversion is applied. The Latin alphabet has all 26 `a`–`z`
  bins, including letters the canonical map cannot produce.
- Original `rune` and coordinates retain provenance, not a second measurement
  input. The consumer does not re-parse source text, execute a recipe,
  reconstruct output or infer GP runes by tokenizing rendered Latin.
- Load and hash the same bytes that are measured. Producer integration tests
  establish semantic correspondence; the reader verifies the declared saved
  contract and byte identity. This is local evidence consistency, not a proof
  against coordinated malicious edits of every artifact and its manifest.

### Measurements and owned result

- A single `SymbolStatistics` analyzer operates on either declared symbol
  sequence/alphabet and produces one owned immutable AnalysisResult per
  declaration. Each result contains frequencies and raw IC from its own
  histogram, labeled with declaration ID, representation and alphabet size.
  Two requested representations produce two separate results in declaration
  order, not a blended histogram. No arbitrary alphabet/plugin framework is
  needed. AnalysisResult is neither an Assessment nor model validation.
- Return every symbol in its declared alphabet order (29 GP runes or 26
  lowercase ASCII letters), with index, symbol, integer count and relative
  frequency `count / N`. Record each representation's own sample size `N`
  and distinct observed count. Counts sum to that `N`; for `N>0` proportions
  sum to one within documented display precision.
- Raw IC is `sum(count * (count - 1)) / (N * (N - 1))`. Store its exact
  integer numerator and denominator and a numeric value for `N >= 2`,
  explicitly labeled `normalization: none`. This counts ordered matching
  pairs among all ordered pairs of distinct sample positions. Do not multiply
  by either alphabet size or compare either result to an English benchmark.
- For `N=0`, retain all declared alphabet bins with zero counts, zero distinct
  symbols and null proportions
  (relative frequency is undefined). For `N<2`, IC has
  `status: insufficient_sample`, numerator/denominator `0/0`, and null value.
  For `N=1`, its observed frequency is one and other frequencies zero.
  Successful execution with an undefined statistic is still successful;
  never serialize NaN/Infinity or report an invented IC of zero.
- No threshold, match/mismatch, pass/fail, likelihood, ranking, inferred
  language, key length or plaintext claim is attached to the statistic.
  Analytical execution success and historical expectation outcomes stay
  distinct in output and storage. A larger rune or Latin IC is not labeled
  better, and the two sample spaces are never treated as interchangeable.

### Persistence and historical review

- Append a new unique analysis run under the selected observation:
  `analyses/ANALYSIS_RUN_ID/record.json`, with the definition snapshot beside
  it. Do not rewrite the observation's `record.json`, artifacts, assessment
  records, completion summary, matching outcome or prior analyses. Discover
  analysis records by bounded directory lookup, not a mutable parent index.
- Persist analysis schema/version, ID, exact definition digest/configuration,
  an ordered results array with declaration ID on each entry, each analyzer
  name/version, stage/representation, exclusion rules, alphabet cardinality/map,
  and owned result. Retain observation pair, output/provenance digests and byte
  lengths, manifests, saved policy, source run-record digest, execution
  timestamps, code revision and code-clean flag, and Ruby version. Record
  `status: completed` for a successful measurement; errors are execution
  errors, never scientific mismatches.
- Validate config and evidence before reserving an analysis directory. A
  rejection at that boundary creates no result. Once reserved, a run starts
  as `running` and is atomically finalized as `completed` or `error`; completed
  records are immutable. Interrupted runs remain visibly incomplete. A write
  failure must not be reported as saved success; do not overwrite an existing
  ID. Two invocations create distinct additive records, with no cache/reuse.
- Historical review reads retained definition and result only, validates
  analysis schema/IDs/observation linkage and path containment, and reports
  stored values without recalculation. Missing or malformed retained records
  are explicit errors, never silently omitted. Review does not need the
  current analysis definition, experiment preset, original source file,
  oracle or hash backend, and can display the retained result if the source
  observation artifacts later disappear. Label saved measurement evidence;
  review is not a fresh assertion that source artifacts are still intact.
- CLI execution prints observation/analysis IDs, stage, representation,
  then each declaration ID, representation, alphabet size, sample size,
  complete frequency table and raw IC (or insufficient sample), followed by
  a copyable review command. Review shows the same retained scientific
  fields plus execution/provenance identity. Nonzero status means command or
  persistence failure, not an uninteresting IC or historical hash mismatch.

## Approach

Likely files; names express responsibilities, not a mandate for extra layers:

| Area | Change |
| --- | --- |
| `lib/primus/analysis/definition.rb` | Safe loading and validation of the standalone analyses list; no dependency on Experiment file validation. |
| `lib/primus/experiment/final_symbol_manifest.rb`, small `store.rb` integration | Declare both final symbol representations from the Observation and saved artifact checksums. No recipe or intermediate-stage changes. |
| `lib/primus/analysis/observation_reader.rb`, `observation.rb` | Verify retained evidence, then expose an owned analysis input; see the current review-refactor section. |
| `lib/primus/analysis/symbol_statistics.rb`, `result.rb` | Histogram/raw IC query and owned immutable scientific result, including the insufficient-sample state. |
| `lib/primus/analysis/runner.rb`, `store.rb` | Execute against verified evidence; append/finalize analysis records and query historical results. No dependency on Experiment::Runner or Evaluator. |
| `lib/primus/commands/analyses.rb`, `bin/primus`, `lib/primus.rb` | Thin CLI and registration/requires; own formatting in a presenter if it would otherwise mix with orchestration. |
| `experiments/analyses/final-symbol-statistics.yml`, `README.md` | Supported declaration, distinction from checks, commands and precise symbol/IC contract. |

Use ActiveModel for the new definition if consistent with the existing
configuration boundary; do not introduce Rails dependencies or gems. A pure
analyzer query such as `to_result` returns an AnalysisResult. The coordinating
`Runner#run` is a nil-returning command exposing its retained run/result through
readers, matching the established command/query preference. Store write
commands and history queries remain explicit. Deep-freeze owned result data,
not merely the top-level array. Keep original observations untouched.

The existing long Experiment/Store/Experiments classes are not an invitation
to bolt in more responsibilities or conduct a broad refactor. New classes
follow Ruby clean-code/Sandi Metz limits; use small domain boundaries rather
than a generic registry or delegation-only object graph. Leave the legacy IC
API intact. Keep the recipe format unchanged for this step; future draft/run
migration is allowed rather than a compatibility obligation.

### Test-first handoff

1. Start with a CLI feature using a small, independently specified saved run
   in a temporary root: analyze, append, review after removal/change of current
   definitions and live input. Assert literal scientific output and no change
   to original file bytes. This new command is genuinely red initially.
2. Work inward on definition validation and verified reading. Exercise bad
   digest/length/path, symlink escape, absent/unsupported manifest, malformed
   JSON, duplicate keys/ordinals/source identities, missing decoded runes,
   unknown symbols and manifest/artifact disagreement. Change checksum metadata
   as well in a semantic-corruption fixture so hash validation cannot mask a
   missing representation check. Use small independent fixtures, not copies of
   the production serializer as expected values.
3. Pin arithmetic with literal samples: `ᚠᚠᚢᚢ` has counts 2/2, numerator 4,
   denominator 12 and IC 1/3; all identical has IC 1; all distinct has IC 0.
   Cover zero/one symbols, explicit zero bins, proportions, and a multi-letter
   GP rune counted once. For the same saved `ᚦᚪᚦ` sequence (TH A TH), rune
   counts are TH=2/A=1, N=3 and IC=2/6=1/3; expanded `thath` has t=2/h=2/a=1,
   N=5 and IC=4/20=1/5. Assert both exact ratios, distinct counts, proportions,
   and all 29/26 bins using literal expectations. Include canonical `ᛝ` ->
   `ng`, not alternate `ing`, and retain zero Latin bins such as `v` and `z`.
   The empty-source fixture is a supported synthetic
   saved record, even though normal experiment validation requires GP input.
4. Add narrowly focused page-56/page-57 saved-output integration regressions
   generated in temporary stores through existing controls with the new capture
   manifest. Pin producer output/provenance against literal expected examples,
   including original versus decoded rune, preserved source mapping, Latin
   expansion, both sample sizes and exclusion of hexadecimal passthrough from
   both profiles. Cover each representation alone, both together, declaration
   order and duplicate/unsupported declaration rejection. Do not use guessed
   plaintext statistics or English thresholds; do not touch local page-55 runs.
5. Cover append-only history, replay independence, historical hash-error output
   eligibility, concurrent unique IDs, incomplete/error records, and failure to
   persist. Test observable behavior at one appropriate level. Use literal
   expectations, explicit setup/exercise/verify, no `let` or heavy `before`,
   and no unit specs for thin serializers. Ensure temporary stores stay isolated.
6. Run focused specs, existing experiment/provenance regressions, appropriate
   full suite and RuboCop under the repository's expected Ruby/UTF-8 setup.
   Report actual results; record any encountered flakiness with exact evidence
   in `flaky-specs.md`. No tests were run for this documentation-only plan.

## Edge cases

- A completed observation may have no matching expectation, or a check may
  have errored after output was saved. Eligibility depends on verified output,
  not scientific success; an absent output or unfinished producer fails.
- Current test runs lacking the manifest can be discarded and recreated after
  implementation; no compatibility or migration adapter is required. Analysis
  never mutates an old record to invent evidence.
- No original-input stage or windows are included. Future selection must name
  its coordinate system explicitly; e.g. original GP ordinals `[0,55)` means
  0 through 54, not 55 characters of Latin. Do not apply a skip-55 hypothesis
  automatically or change transformation skip parameters.
- An analysis definition or alphabet edited after execution cannot relabel
  stored results. Reading saved results uses their recorded method/profile.
- An unavailable hash backend or unrelated corrupt assessment cannot block
  analysis of otherwise verified final evidence. Read only relevant run fields.
- File reads and measurements use one captured byte snapshot per artifact;
  failure while writing leaves an incomplete/error attempt, not a partial
  completed result. This is local append-only evidence, not a database service.

## Out of scope

New transformation YAML execution, recipe migration, arbitrary chains,
intermediate stage capture (the two final representation manifests are in scope),
original-input analysis, stage/window selection,
synthetic layered controls, additional analyzers, n-grams, normalized IC,
reference-language models, significance testing, rankings, automated search,
hash reassessment, cross-ID cache reuse, preset overrides, new hash algorithms,
input-image audit, source/transcription fixes, dependency changes, page-55
analysis execution, and deletion/migration of current test data during planning.

Later sequence: step 2 captures explicit transformation stages with an
independently specified layered synthetic control; step 3 selects retained
stages for analysis; step 4 adds further analyzers. Position windows come at the
very end of the broader roadmap, after the other deferred capabilities. Re-plan each against the
then-current implementation. The separated `analyses` declaration and explicit
`final` representation provide continuity without implementing those steps now.

## Open questions

No blocking requirement ambiguity remains. The tradeoff is explicit: a small
producer capture change replaces backward-compatibility/reconstruction work,
and current test observations must be recreated before the new reader accepts
them. No data cleanup has happened. Use separate rune and expanded-Latin
results through the `analyses run/review` command family. The Latin selection
choice is explicit: canonical GP expansions only, not literal output letters.
The user has requested the test-writer handoff after this plan update. Broader
transformation syntax and analysis windows need later design.
