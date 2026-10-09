# Saved-output rune frequencies and index of coincidence

## Goal

Analyze an existing saved experiment observation without rerunning its recipe:
retain rune frequencies and raw index of coincidence (IC) as an owned
AnalysisResult, linked to the exact saved final output and decoded-rune
provenance under a small explicit representation contract. Keep measurements independent of expectation assessments and make
them reviewable without today's experiment definition, input file or hash backend.

This is step 1 only, proposed for review before a test-writer handoff. No
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
  id: final-rune-statistics
  analyses:
    - id: rune-statistics
      analyzer: rune-statistics
      version: 1
      target:
        stage: final
        representation: gp-runes-v1
  ```

  Save the reusable definition at
  `experiments/analyses/final-rune-statistics.yml` during implementation.
  This first version accepts exactly one analysis entry and only the shown
  analyzer/version/target; absent, duplicate or unknown keys, aliases, invalid
  IDs, unsupported stages/representations and unexpected parameters fail
  validation. Use safe YAML loading and duplicate-key rejection. No implicit
  defaults that can change the meaning of a historical analysis.
- Proposed usage (not an existing command):

  ```sh
  bin/primus analyses run EXPERIMENT_ID RUN_ID \
    --definition experiments/analyses/final-rune-statistics.yml
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

### Explicit final-rune capture and verified reading

- Add a minimal versioned representation manifest when a new observation is
  saved. Reuse existing `provenance.json`; do not add a duplicate rune stream.
  Store it under `observation.representations.gp-runes-v1`, containing
  `schema_version: 1`, `stage: final`, `artifact: provenance.json`,
  `symbol_field: decoded_rune`, the ordered 29-rune alphabet, sample size,
  and the SHA-256 of both `output.txt` and `provenance.json`. The existing
  artifact entries continue to own paths, byte counts and checksums. The
  manifest binds this exact final rune representation to its output bytes.
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
  declared versioned GP alphabet. Parse provenance as an array of entries with
  ordinal exactly `0...N`; each decoded rune is one declared GP symbol. Check
  sample size, required source-coordinate fields and uniqueness of original
  source identities. Missing/duplicate/out-of-order rows, invalid symbols and
  malformed JSON fail explicitly; duplicate JSON keys must not silently win.
- Measure precisely the ordered `decoded_rune` entries. Exclude punctuation,
  whitespace and non-GP literals; `th` or `ing` counts as one GP rune.
  Original `rune` and coordinates retain provenance, not a second measurement
  input. The consumer does not re-parse a source body, execute a recipe,
  reconstruct output, or infer runes by tokenizing rendered Latin.
- Load and hash the same bytes that are measured. Producer integration tests
  establish semantic correspondence; the reader verifies the declared saved
  contract and byte identity. This is local evidence consistency, not a proof
  against coordinated malicious edits of every artifact and its manifest.

### Measurements and owned result

- A single `RuneStatistics` analyzer produces one owned immutable
  `AnalysisResult` containing both measurements from one histogram. This is
  a cohesive unigram summary, not two independent passes or a plugin registry.
  It is neither an Assessment nor model validation.
- Return all 29 GP symbols in canonical GP index order, with index, rune,
  integer count and relative frequency `count / N`; record sample size `N`
  and the number of distinct observed symbols. Counts sum to `N`; for `N>0`
  proportions sum to one within documented display precision.
- Raw IC is `sum(count * (count - 1)) / (N * (N - 1))`. Store its exact
  integer numerator and denominator and a numeric value for `N >= 2`,
  explicitly labeled `normalization: none`. This counts ordered matching
  pairs among all ordered pairs of distinct sample positions. Do not multiply
  by 29 or compare to a 26-letter English benchmark.
- For `N=0`, retain 29 zero counts, zero distinct symbols and null proportions
  (relative frequency is undefined). For `N<2`, IC has
  `status: insufficient_sample`, numerator/denominator `0/0`, and null value.
  For `N=1`, its observed frequency is one and other frequencies zero.
  Successful execution with an undefined statistic is still successful;
  never serialize NaN/Infinity or report an invented IC of zero.
- No threshold, match/mismatch, pass/fail, likelihood, ranking, inferred
  language, key length or plaintext claim is attached to the statistic.
  Analytical execution success and historical expectation outcomes stay
  distinct in output and storage.

### Persistence and historical review

- Append a new unique analysis run under the selected observation:
  `analyses/ANALYSIS_RUN_ID/record.json`, with the definition snapshot beside
  it. Do not rewrite the observation's `record.json`, artifacts, assessment
  records, completion summary, matching outcome or prior analyses. Discover
  analysis records by bounded directory lookup, not a mutable parent index.
- Persist analysis schema/version, ID, exact definition digest/configuration,
  analyzer name/version, stage/representation, exclusion rules, observation
  pair, output/provenance digests and byte lengths, representation manifest, saved policy,
  source run-record digest, alphabet/representation identity, result, execution
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
  sample size, the 29-symbol frequency table, raw IC (or insufficient sample)
  and a copyable review command. Review shows the same retained scientific
  fields plus execution/provenance identity. Nonzero status means command or
  persistence failure, not an uninteresting IC or historical hash mismatch.

## Approach

Likely files; names express responsibilities, not a mandate for extra layers:

| Area | Change |
| --- | --- |
| `lib/primus/analysis/definition.rb` | Safe loading and validation of the standalone analyses list; no dependency on Experiment file validation. |
| `lib/primus/experiment/final_rune_manifest.rb`, small `store.rb` integration | Declare the final GP representation from the Observation and saved artifact checksums. No recipe or intermediate-stage changes. |
| `lib/primus/analysis/saved_observation.rb` | Verify the explicit representation manifest and saved artifacts; no legacy compatibility adapter. |
| `lib/primus/analysis/rune_statistics.rb`, `result.rb` | Histogram/raw IC query and owned immutable scientific result, including the insufficient-sample state. |
| `lib/primus/analysis/runner.rb`, `store.rb` | Execute against verified evidence; append/finalize analysis records and query historical results. No dependency on Experiment::Runner or Evaluator. |
| `lib/primus/commands/analyses.rb`, `bin/primus`, `lib/primus.rb` | Thin CLI and registration/requires; own formatting in a presenter if it would otherwise mix with orchestration. |
| `experiments/analyses/final-rune-statistics.yml`, `README.md` | Supported declaration, distinction from checks, commands and precise symbol/IC contract. |

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

### Test-first handoff after plan review

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
   GP rune counted once. The empty-source fixture is a supported synthetic
   saved record, even though normal experiment validation requires GP input.
4. Add narrowly focused page-56/page-57 saved-output integration regressions
   generated in temporary stores through existing controls with the new capture
   manifest. Pin producer output/provenance against literal expected examples,
   including original versus decoded rune, preserved source mapping, Latin
   expansion, GP-only sample size and exclusion of the hexadecimal block. Do not use guessed plaintext statistics or English
   thresholds as expected results; do not touch local page-55 runs.
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
intermediate stage capture (the final-rune manifest is in scope),
original-input analysis, stage/window selection,
synthetic layered controls, additional analyzers, n-grams, normalized IC,
reference-language models, significance testing, rankings, automated search,
hash reassessment, cross-ID cache reuse, preset overrides, new hash algorithms,
input-image audit, source/transcription fixes, dependency changes, page-55
analysis execution, and deletion/migration of current test data during planning.

Later sequence: step 2 captures explicit transformation stages with an
independently specified layered synthetic control; step 3 selects retained
stages for analysis; step 4 adds further analyzers. Re-plan each against the
then-current implementation. The separated `analyses` declaration and explicit
`final` representation provide continuity without implementing those steps now.

## Open questions

No blocking requirement ambiguity remains. The tradeoff is explicit: a small
producer capture change replaces backward-compatibility/reconstruction work,
and current test observations must be recreated before the new reader accepts
them. No data cleanup has happened. Proposed review choices are one
combined rune-statistics result and the separate `analyses run/review` command
family, which keeps measurement ownership clear and avoids expanding the
existing experiment command. If a nested experiments command is preferred,
settle that spelling before test-writer handoff; it does not change the domain
contract. Broader transformation syntax and analysis windows intentionally need
later design, not provisional working syntax here.
