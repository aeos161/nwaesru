# Multiple experiment checks

## Delivery status (2026-10-08)

Implemented and merged at `45d4380` on local main. The baseline, planned
handoff and restrictions below describe that completed increment. Next is
[reusable totient Latin and complete page-56 validation](reusable-totient-latin.md).
Saved-output reassessment and general preset overrides remain deferred; this
focused next plan supersedes their earlier relative ordering.

## Goal

Deliver increment 2 of composable experiments: execute a whole-page Latin
recipe once, retain its exact output, and independently compare every selected
hash and optional plaintext expectation against that same observation. Expose
all results through run and historical review, separating execution completion
from whether any check matched.

This is a plan for human review. Stop after its WIP commit; do not invoke the
test-writer or implement source/tests until the user reviews it.

## Baseline and design assessment

On 2026-10-07, clean local `main`, `origin/main`, and a live remote main lookup
all resolved to `67113c5dfcc53ce97932b94b4c77b1ec9983d1a5` (Show experiment IDs
and copyable review commands). Its ancestor `f2b6cf8` contains the single-check
composition implementation. Work uses `codex/multiple-experiment-checks` in
`/Users/chriswoodford/Workspaces/chriswoodford/nwaesru`.

Increment 1 is implemented: whole-page inputs, Latin recipe, one v2 plaintext
or hash check, canonical configuration, separate execution identity and
persist-before-assess behavior. CLI discoverability is also implemented.
The original roadmap's baseline is historical, not today's starting point.

Concrete remaining couplings are `checks.first` in Experiment validation/file
loading, Runner expectation/runtime selection, Store's oracle fields and CLI
display; Composition builds one check; LogEntry/Assessment are singular.
Runner already owns execution orchestration, Evaluator owns one comparison,
and Store owns persistence. Extending these boundaries with a focused check
value and collection assessor implements the feature itself. No separate
prerequisite refactor is justified. Do not broaden this into cleanup of the
large legacy model/runner/store or split methods merely to satisfy a number.

The user reports a green main suite. `flaky-specs.md` records an earlier
US-ASCII environment failure and a UTF-8 retry with 538 examples, 0 failures,
12 pending. No tests were run in this documentation-only planning step; this
is not a new baseline test claim.

## Acceptance criteria

### Configuration and exact CLI contract

Both `run` and `validate` accept these forms (HEX placeholders stand for literal
128-character lowercase hexadecimal strings; these are interface examples):

```shell
bin/primus experiments run --input page-57 --recipe latin --hash blake512 --hash blake2b512 --hash sha512 --expect-digest HEX
bin/primus experiments run --input page-57 --recipe latin --hash sha512 --hash blake512 --expect-digest sha512=SHA_HEX --expect-digest blake512=BLAKE_HEX
bin/primus experiments run --input page-57 --recipe latin --hash sha512 --expect-digest HEX --expect-text experiments/expected/page-57-latin.txt
```

- `--hash` and `--expect-digest` genuinely accumulate repeated scalar values;
  support both `--hash sha512` and `--hash=sha512` (likewise digest). Thor 1.2.1
  `Parser::Options#assign_result!` supports `repeatable: true` for scalar options;
  use that facility, already used by `bin/primus decode`, not an argv pre-parser,
  array-valued option, comma syntax, or dependency upgrade. Normalize direct
  Composition callers' existing scalar values at its boundary too.
- A single bare digest is a shared 64-byte target for every selected hash.
  Qualified values map by algorithm, independently of flag adjacency/order.
  Every selected algorithm must have exactly one qualified expectation when
  that mode is used. Shared and qualified equivalent inputs produce identical
  canonical checks when their resolved per-check expectations are equal.
- Support exactly `sha512`, `blake2b512`, `blake512`; display them distinctly as
  SHA-512, BLAKE2b-512, BLAKE-512. Each has a 64-byte digest; persist that length
  in assessment evidence. Do not add SHA-256 assessment support.
- Reject duplicate selected algorithms, duplicate qualified keys (even equal),
  multiple bare digests, mixed modes, missing/extra expectations, digest without
  hash, unsupported algorithms, malformed qualifiers/hex, uppercase hex and
  wrong lengths. Do not silently drop earlier flags or accept an empty value.
- `--expect-text` optionally adds one independent plaintext check; plaintext-only
  remains valid. Never derive any expected hash from that file or actual output.
  Repeated `--expect-text` is invalid, even with the same path; use repeatable
  scalar capture and cardinality validation to detect it. The existing single
  `--expect-provenance` applies to all CLI checks, preserving its current default.
- V2 YAML accepts an ordered nonempty checks array, with unique valid IDs, at
  most one hash check per supported algorithm and at most one plaintext check.
  Validate every entry, strategy-specific fields, provenance and plaintext
  checksum/path; retain duplicate-key and unknown-field rejection. A malformed
  later check must invalidate the entire composition before transformation.
- CLI hash order is declaration order, with plaintext appended last regardless
  of its flag position. IDs are `check-1`, `check-2`, etc., deterministically
  assigned in that order. A one-check CLI retains its existing `check-1` and
  canonical shape/ad-hoc ID. YAML retains explicit IDs/order; equivalent YAML
  using those IDs produces equal canonical configuration. Reordering checks is
  an intentional configuration/namespace change; IDs are stable within saved
  configuration, not globally unique checks. Runtime/backend availability must
  never influence configuration IDs. Preserve hash-key canonicalization used by
  existing identity paths; do not sort away check order.
- Validation remains offline and does not probe backends. Validate all source
  and oracle paths/checksums and reject output overlap with any of them,
  including symlink-resolved containment/overlap. Preserve current source,
  plaintext UTF-8 and exact-byte policy; no trimming or newline normalization.
- Continue rejecting positional preset plus composition options. Preset override,
  reusable totient parameters and section selection belong to later increments.

### Execution, persistence and identity

- Valid multi-check execution builds one Observation. Persist output bytes,
  provenance and artifact metadata successfully before probing/evaluating any
  check. Every assessment consumes that same frozen Observation; never rebuild
  the recipe or write a second output copy per check.
- Process every check in configured order. A mismatch is a completed comparison.
  Backend unavailability, runtime-probe failure or digest failure records an
  error for that check and allows later checks, including plaintext, to execute.
  Preserve error class/message and stage; do not invent an observed digest or
  call an unavailable comparison a mismatch. Rescue assessment-scoped failures
  at the check boundary; never swallow interrupts or persistence failures.
- Each check has a unique assessment attempt ID distinct from its check ID and
  run ID, observation reference `(experiment_id, run_id)`, saved check config,
  policy, expectation evidence/provenance, start/end timestamps, code/runtime,
  backend descriptor, status and comparison/error detail. Runtime probes are
  per algorithm; retain original BLAKE source/native/gem descriptor fields.
  SHA-512 and plaintext also identify their relevant Ruby/runtime implementation.
- Assessment identity uses saved output SHA-256, policy, normalized check and
  expectation content/provenance, assessment code/Ruby identity and that check's
  backend identity. Retain BLAKE's stable descriptor allowlist; exclude transient
  error-message wording from identity while retaining it as evidence. For a
  failed probe record available descriptor fields and stable error class, never
  pretend a backend was available. No identity is used to skip work in this slice.
- Keep schema version 2, adding an explicit `assessment_records` collection for
  new multi-check run records. It holds ordered relative references to uniquely
  named `assessments/<assessment_id>/record.json` files under the run directory.
  Each assessment record has its own schema version 2 and observation reference;
  any plaintext snapshot belongs in that assessment directory. Hash expectation
  literals are saved in its record. Keep output/provenance only at run level.
- Reserve running assessment records and atomically finalize each once; completed
  assessment records and artifacts are immutable. Finalize the run once after
  all results. Persist observation metadata at `record_observation`, not only at
  finalization, so interruption after output persistence still exposes evidence.
  Incomplete attempts remain visibly running; never mark unstarted checks as
  completed. A failed output/assessment write aborts further work and reports an
  infrastructure failure, preserving whatever evidence actually exists.
- New multi-check run `status` is `completed` when all checks compared, including
  mismatches, or `error` when any check errored. Save `completion_summary` with
  integer `match`, `mismatch`, `error` counts; their sum equals requested checks
  for a fully processed run. Separately save `matching_outcome: matched` when
  at least one check matches, otherwise `no_match` for a fully processed run.
  This is the scientific outcome: one match is sufficient, regardless of how
  many other checks mismatch. It never changes execution status or erases an
  error. A match alongside a backend error is `status: error` and
  `matching_outcome: matched`. All mismatches are `status: completed` and
  `matching_outcome: no_match`. For interrupted/non-assessed runs with no known
  match, leave `matching_outcome` null rather than claim a completed negative
  finding; retain `matched` if a match was already recorded. An all-error run
  has `no_match` with truthful error counts, not evidence that all algorithms
  were successfully compared. Do not introduce an ambiguous `success` field.
  Use `comparison: not_applicable` at run level;
  per-check comparison is `match`, `mismatch`, or `not_checked` for an error.
  Invalid configuration and execution failure remain distinct run stages/statuses,
  with no fabricated completed assessments.
- Preserve v1 fingerprints, lookup, statuses, bytes, controls and histories. Keep
  the existing v2 execution identity independent of checks/backends, without
  treating it as a cache key in this increment. No cross-ID or v2 deduplication,
  no lookup of multi-check runs through Store's v1 `prior` path. Fresh v2 `run`
  remains fresh, including when checks/expectations change. Preserve existing
  `--rerun --reason` validation without promising new reuse/lineage semantics.
- Retain singular read/write shape and status/display behavior for one-check
  runs in this slice, including old v2 records. Multi-check uses the new
  collection shape; readers explicitly distinguish it by `assessment_records`,
  never guess from schema version 2 alone. Do not relabel old checks, rewrite
  records or synthesize persisted assessment IDs for old singleton history.
  This narrow compatibility path avoids a migration; increment 3 can read both.
- Runner#run remains a command returning nil. Add owned plural assessments for
  multi-check results; keep the singular assessment API for singleton/legacy
  consumers. Do not expose the first result as the whole multi-check verdict.

### Run output and historical review

- Multi-check first line is `<run_id>: <completed|error> (matches: N, mismatches:
  N, errors: N)`. Keep the existing experiment ID, run ID and shell-escaped
  copyable `review:` lines, once and in their existing order after that summary.
  Print `matching outcome: <matched|no_match>` after the discoverability lines,
  followed by every check's ID, assessment ID, strategy/algorithm and result.
  Existing singleton first-line/status/discoverability output stays unchanged.
- For new multi-check runs, exit 0 when execution and every comparison completed,
  including an all-mismatch run. Exit nonzero for invalid configuration,
  transformation/persistence failure or any check error. A scientific match
  does not conceal an execution error: match plus backend error still exits
  nonzero while displaying `matching outcome: matched`. Print all available
  results and retained identity before exiting. All-mismatch, mixed results,
  partial backend errors and all-error runs remain reviewable. Pre-record
  failures do not print invented identities.
- Preserve existing v1 and singleton v2 exit behavior for compatibility:
  singleton mismatch still exits nonzero. The new execution-only exit rule
  applies to multi-check runs; document this boundary explicitly in the CLI
  guide rather than silently changing controls or old single-check behavior.
- Review displays each saved check's expected/observed digest or plaintext
  length/first-difference result, policy, provenance, runtime/backend identity,
  timestamps and errors, plus completion counts and the separate matching
  outcome. Use saved records and snapshots,
  without source/preset/oracle reload or backend probing. Changed/deleted current
  definitions or unavailable current backends cannot change historical results.
- Missing/corrupt referenced assessment records yield a concrete Store read
  error; never silently omit a check and show partial success. Reject unsupported
  record schemas and escaping references. Keep legacy missing-artifact reporting.
  Full saved-output integrity verification for reassessment remains increment 3.

## Approach

- `lib/primus/experiment.rb`: validate collections and load oracle data per check;
  preserve v1 dispatch and one-check compatibility accessors. A focused
  `lib/primus/experiment/check.rb` may own check validation/loaded expectation
  bytes and stable semantics, rather than multiplying `checks.first` branches.
  It must serve CLI and YAML identically, without a registry/framework.
- `lib/primus/experiment/composition.rb`: resolve repeated options into ordered
  canonical checks before deriving the existing ad-hoc configuration digest.
  Keep source/policy defaults and one-check shape unchanged.
- `lib/primus/experiment/runner.rb`: retain legacy/singleton execution path;
  orchestrate one persisted observation and collection assessment for multi-check.
  `lib/primus/experiment/assessor.rb` can own the per-check loop, runtime identity
  and error boundary. It is feature-specific, not a generic execution engine.
- `evaluator.rb` and `assessment.rb`: retain one-check comparison responsibilities;
  add owned assessment evidence/error representation as needed. Keep storage
  errors outside evaluator/backend error rescue. Avoid parallel evaluation.
- `store.rb` and `log_entry.rb`: versioned collection records/references,
  per-assessment snapshots, atomic finalization and compatibility readers. Add
  only the write-once boundaries required now; no append/reassess public command,
  verified-observation service or cache search yet. Resolve relative references
  inside the recorded run directory and reject symlink escapes on read/write.
- `lib/primus/commands/experiments.rb`: repeatable option declarations, thin
  validation/run/review display and aggregate exit decision. Reuse Shellwords
  discovery formatting. Remove the hash-plus-text rejection only for valid
  compositions, without enabling preset overrides.
- `README.md`: document repeated flags, both expectation modes, optional plaintext,
  per-check failures, execution-only multi-check exit codes, the any-match
  scientific outcome and copying the review command. Explain the retained
  singleton exit convention. Do not publish increment-3
  commands. Keep all five v1 definition files unchanged; the standalone v2
  demonstration preset remains increment 4.

### Test-writer handoff after review

Begin at `spec/lib/primus/commands/experiments_composable_spec.rb` with an actual
subprocess using repeated argv and independent known-answer fixtures. Cover shared
and qualified targets, optional plaintext, order, both flag spellings, rejected
ambiguities and a mismatch followed by match. Verify actual repeat accumulation,
not merely a mocked options array. Existing helpers clone committed code: follow
WIP commits so clones exercise the new revision, without disabling clean-code
checks or using an older commit by accident.

Add independent contracts only where necessary in
`spec/lib/primus/experiment_composable_spec.rb`,
`spec/lib/primus/experiment/runner_spec.rb`, `store_spec.rb`, `evaluator_spec.rb`
and corresponding focused Check/Assessor specs if those objects are introduced.
Use existing algorithm specs as regression coverage, not a multiplied matrix.
Prove one transformation/output artifact and persisted bytes before the first
check through observable state at an injected assessment boundary. Exercise a
runtime probe failure and a digest-time failure separately, each followed by a
successful check; then all failures. Persistence failures must stop assessment.

At the CLI/store boundary pin collection references/evidence, completion counts,
separate matching outcome, historical review without current inputs or backends,
and existing singleton/v1 history. Add separate examples for each observable
contract in these cases:

| Multi-check results | Execution status | Matching outcome | CLI exit |
| --- | --- | --- | --- |
| One match, remaining mismatches | completed | matched | 0 |
| Every check matches | completed | matched | 0 |
| Every check mismatches | completed | no_match | 0 |
| Match plus backend error | error | matched | nonzero |
| Mismatch plus backend error | error | no_match | nonzero |
| Every check errors | error | no_match | nonzero |

Prove all available results print before any nonzero exit, and pin invalid,
transformation and persistence failures separately. Retain regression examples
for singleton/v1 mismatch nonzero exits. A zero exit proves completed execution,
not a match; users inspect `matching outcome` and per-check evidence for the
scientific finding. No ranking or all-checks-must-match requirement is implied.
 Keep discoverability specs for
shell-sensitive output paths and returned record identity. Preserve literal
known-answer digests; never compute the expected digest with code under test.

Use one fully namespaced outer `RSpec.describe` per class spec, method-named
nested groups, no `let`, explicit phase spacing, one behavior and one expectation
per example. Do not pack unrelated outcomes into tuple/hash assertions or test
incidental error prose. Shoulda handles standard supported validations; custom
cross-field checks belong to model behavior. Preserve explicit nil command
contracts. Respect collaborators' ownership; avoid Demeter-violating navigation
and forwarding APIs created only to hide it. Five-line methods remain a design
heuristic, not a reason for forwarding bloat.

At implementation start and after meaningful changes, use configured Ruby 2.7.4
and UTF-8 (matching the documented successful environment):

```shell
PATH="$HOME/.asdf/shims:$PATH" RUBYOPT=-EUTF-8 bundle exec rspec spec/lib/primus/experiment_spec.rb spec/lib/primus/experiment_composable_spec.rb spec/lib/primus/experiment_hash_spec.rb spec/lib/primus/experiment_blake2b_spec.rb spec/lib/primus/experiment spec/lib/primus/commands/experiments_spec.rb spec/lib/primus/commands/experiments_composable_spec.rb spec/lib/primus/commands/experiments_hash_spec.rb spec/lib/primus/commands/experiments_blake2b_spec.rb spec/lib/primus/commands/experiments_blake512_spec.rb
PATH="$HOME/.asdf/shims:$PATH" RUBYOPT=-EUTF-8 bundle exec rubocop <touched-Ruby-files>
PATH="$HOME/.asdf/shims:$PATH" RUBYOPT=-EUTF-8 bundle exec rspec
```

Run the full suite once for final regression accounting. Log any actually
observed failure in root `flaky-specs.md` with command, runtime/encoding, revision,
working-tree state, spec/example, failure and reproduction/retry evidence.
Separate expected new-feature TDD reds from unrelated failures; do not label
unreproduced failures flaky or revive historical failures as current. Carry this
instruction into subsequent handoffs. No empty log entry or fresh suite is
required for this docs-only plan.

## Edge cases

Malformed second/later checks must not escape validation. Empty expectations,
conflicting duplicate flags and trailing/multiple qualifier separators cannot
be silently accepted. Plaintext-only empty-file expectations retain existing
semantics. Backend probe availability may change before evaluation; record the
actual failed attempt and continue. A disk error differs from a backend error.
Interrupted records may contain output plus only some assessment attempts; review
must not invent completion. Missing old artifact metadata is not grounds to
invent modern identities. Concurrent fresh runs retain separate run/assessment
paths, without an exactly-once or reuse promise.

## Out of scope

Increment 3 `assess`, appended assessments on old observations, verified output
reassessment, observation/assessment reuse or deduplication, migration and new
rerun lineage. Increment 4 reusable totient/parameters, preset overrides and
example preset. Also no new algorithms, cryptanalysis, scoring/ranking, arbitrary
recipes, alternate output normalization, gem/dependency changes, broad cleanup,
push or PR in this planning step.

## Open questions

None blocking planning. Reviewable decisions are ordered `check-N` CLI IDs,
plaintext last, one plaintext/one hash per algorithm, collection storage only
for multi-check runs, and the concrete completion summary above. The user has
approved separating execution completion from matching, with any single match
sufficient for a positive scientific outcome. These choices make
increment 2 implementable now while preserving current one-check behavior.

## Deferred follow-up: CLI error handling

Revisit experiment CLI errors after the current increment. Make invalid or
incomplete option combinations explain what is missing and how to correct the
command, including hash checks without digest expectations and the distinction
between plaintext and hash expectations. Preserve the separation between
configuration errors, execution/backend errors and ordinary mismatches.

This follow-up arose during manual CLI review on 2026-10-08. The user clarified
that chat formatting stripped the displayed line-continuation backslashes;
no exact error output was captured, so the underlying failure is not diagnosed.
Obtain a reproducible command and its actual stderr before choosing fixes, and
include copyable corrected examples where useful. Shell parsing errors that
occur before Primus starts cannot be handled by the application itself.
