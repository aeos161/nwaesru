# Page 57 experiment harness

## Implementation status — 2026-10-01

The page-57 harness is implemented in `45cab84`, now present on local
`main`; `origin/main` was still `e24b2d7` at inspection. Prior completion
reported 351 examples, zero failures, 12 pending and a matching CLI result
with 95 rune provenance entries. This documentation pass did not rerun tests.
The original planning record below is retained as history: its red-phase,
missing-production-code, dependency-installation and 75-example rewrite
instructions are superseded by the implementation. ActiveModel 7.1.6 and
Shoulda Matchers 5.3.0 are already in the resolved bundle.

Delivery update on 2026-10-03: page 56 is implemented at `946431c`, and
local main `e996a6e` also includes the ID-based CLI. The actionable third
milestone is now the [page-57 SHA-512 control](page-57-hash-control.md),
replacing artificial synthetic input. Historical scope/gates below describe
this completed first milestone and do not require it to be repeated.

## Goal

Define “transform from runes to Latin characters” as a saved research
experiment outside RSpec; validate its inputs/configuration, run it, save
its output, and compare it with independently known page-57 Latin text.
Make planned experiments and prior attempts reviewable so repeats are
intentional. RSpec verifies this harness; it is not the experiment store.

**Current implementation scope: page 57 only.** This supersedes
[the two-page adapter plan](reproduce-pages-57-56.md). Page 56 is a separate
follow-on; the page-57 SHA-512 control follows page 56, then page 55 research.
This document plans work only; no implementation or experiments were run.

## Baseline and design decisions

Reconciled the approved domain discussion against clean
`feature/reproduce-pages-57-56` at `9311be1` on 2026-09-29. The 75 current
harness examples are an unfinished red phase (last reported full suite:
343 examples, 75 expected failures, 12 pending; not rerun in this docs pass),
not an approved API: no production `Primus::Experiment` exists yet.
Lossless input and transcription reversals are already merged. Keep this
branch; change plans only in this pass, with no test-writer invocation.

Use existing Builder, Page, Translator, Printer, source metadata, Psych,
and Thor. No new cipher or prerequisite refactor is justified. Five-line
methods are a heuristic, not a hard cap; defer broad cleanup. Do not build
a registry, database, chain engine, search system, or algorithm adapters.

### Saved definition and oracle

Proposed tracked definition: `experiments/definitions/page-57-latin.yml`.
A YAML mapping safe-loaded as data, with no Ruby evaluation, aliases,
custom tags, or duplicate keys. Schema version 1 has these required fields:

| Field | First supported value / meaning |
| --- | --- |
| `schema_version` | Integer `1` |
| `id` | `page-57-latin`, stable readable identity |
| `title` | `Transform page 57 from runes to Latin characters` |
| `purpose` | Why this experiment is planned; plain text |
| `input.page_number` | Integer `57`, repository filename numbering |
| `input.path` | `data/encoded/liber_primus/page_57.yml` |
| `input.sha256` | Actual lowercase SHA-256 of exact encoded YAML bytes |
| `operation` | `runes_to_latin`, the only operation supported now |
| `output.policy` | `gp-latin-compatibility-v1` |
| `expectation.kind` | `plaintext` |
| `expectation.path` | `experiments/expected/page-57-latin.txt` |
| `expectation.sha256` | Actual SHA-256 of exact independent oracle bytes |
| `expectation.provenance` | Existing decoded YAML path and documented extraction policy |

These names are recommended implementation choices, not a general future
DSL. Fill real digests when implementing; placeholder checksums are invalid.
Only the page-57 source/path combination and the stated options are supported
initially. Reject unknown fields/values instead of ignoring them. Paths are
repository-relative, resolve within the repository, and cannot refer to the
output directory. Do not add an editable `passed` or `run` flag to definitions:
Git versions planned definitions, run records describe attempts.

Prepare the expected `.txt` once from the existing independent
`data/decoded/liber_primus/page_57.yml` body using its existing `rstrip`
comparison convention. Review the complete fixture, preserve its spelling
(including `lice`, `unnelng`, `diuinity`) and physical wraps, and document its
source digest. Never generate or update the oracle from the transformation
under test. Validation reads exact expected bytes; it does not trim both
sides opportunistically. A changed oracle is a changed experiment.

### Three different checks

1. **Configuration validity:** schema/types/required fields, supported
   operation/policy/page, valid paths, readable UTF-8 input YAML with String
   body, and readable UTF-8 expected text. Reject an empty/no-rune page-57
   body, malformed YAML, unsupported tags/aliases, and invalid digests.
2. **Input integrity:** compare actual source and expected-fixture SHA-256
   with declared digests before transformation. This establishes identity,
   not truth of the transcription or correctness of the plaintext.
3. **Output correctness:** compare the saved Latin artifact byte-for-byte
   with the saved expected text. Distinguish match, mismatch, and not checked.

SHA-256 here identifies files; it is not the later research hash oracle.
A configuration/integrity failure must never appear as a plaintext mismatch.

### Exact output and provenance

`gp-latin-compatibility-v1` means UTF-8 bytes of the existing parsed Document
rendered through Printer with `:letter`, maintained line breaks, existing
GP canonical lower-case expansions and compatibility delimiter rendering,
and Printer's final `rstrip`. No BOM or added terminal LF. This is an
explicit normalized display artifact, not original source serialization.
Do not use CLI `puts` to write it. Pin exact whole output in a regression;
future changes to this policy require an explicit version change.

Load the source once; verify and save the same bytes actually consumed.
Use Page's existing source loader, construct the selected LiberPrimus Page
with original body/artifact/path metadata, and build with runic strategy and
`track_delimiters: false`. Pass the resulting Document to a fresh Translator.
Keep original Transcription and translated Document distinct. Do not re-lex
rendered/transformed output or reconstruct original source from a Document.

Retain all original SourceLocation fields on every derived GP symbol. Save
a small ordered provenance artifact with processing ordinal, rune/Latin
value and original page/occurrence, byte/character spans, line/column and
rune index. Original lexical stream and source body remain unchanged.
Source offsets address extracted body bytes, not YAML artifact bytes.
Multi-character GP transliterations still correspond to one source rune.
No reversal or cipher arithmetic occurs in this milestone.

## Acceptance criteria

- A researcher can add/review a saved definition without adding an RSpec
  example; the provided page-57 definition and oracle are tracked files.
- A documented callable API and thin command entry point offer validate,
  run, and review. Validation never transforms the page. A run always
  validates before execution and uses the same validated byte snapshots.
  Standalone validation is read-only; invalid run attempts are recorded when
  the output directory is writable.
- Unsupported options, bad YAML/UTF-8/body, missing/unreadable files and
  wrong source/oracle checksums produce actionable stage-specific failures;
  no transform occurs after precondition validation failure.
- Page 57 produces the full known Latin bytes and a `match` comparison.
  Deliberately different valid oracle bytes produce `mismatch`, retaining
  both expected and actual artifacts and a useful first differing byte
  offset/length summary. Never overwrite the oracle automatically.
- Each executed attempt has its own directory and machine-readable record.
  Successful, mismatching, invalid and errored attempts are distinguishable;
  an interrupted attempt is visibly incomplete, never an apparent pass.
- Review shows definition identity/purpose, validity/integrity checks,
  code/input identity, prior related attempts, comparison result and artifact
  paths. It works after the source or definition has changed using snapshots.
- Repeating unchanged execution inputs/code is identified before executing;
  ordinary run exposes the existing attempt through `runner.log_entry`
  without new execution; its command return remains nil.
  An explicit rerun creates a new attempt with a nonempty reason and links
  the prior attempt. Existing results/artifacts are never overwritten.
- A changed definition/oracle/source/code is not silently treated as the same
  execution; review still groups attempts by stable experiment ID. Mismatches
  and failures participate in prior-run lookup, not just successes.
- Exact source YAML and extracted body are saved independently of normalized
  Latin output; complete GP-symbol provenance remains correct. Multiple calls
  create fresh visitor/document state and do not mutate earlier results.
- Storage failures report failure to persist, never report a durable success.
  No claim is made that an error record exists if the store was unwritable.

## Approach

### Domain objects and command/query boundary

These approved decisions supersede the older Definition/Runner hash API:

| Domain object | Responsibility and proposed file |
| --- | --- |
| `Primus::Experiment` | A class including `ActiveModel::Model`; hydrates saved YAML, retains definition identity/snapshots, and owns precondition validation and `errors`. `lib/primus/experiment.rb`. |
| `Primus::Experiment::Runner` | Receives `experiment:` and `output_path:`. Calls `experiment.valid?` before execution, coordinates this single operation and persistence, and owns readers `observation`, `assessment`, `log_entry`. `lib/primus/experiment/runner.rb`. |
| `Primus::Experiment::Observation` | Actual produced bytes and provenance/artifacts of an executed experiment; never a validation status or returned result hash. `lib/primus/experiment/observation.rb`. |
| `Primus::Experiment::Assessment` | Evaluation of an Observation against the declared expectation: match/mismatch and supporting lengths/first difference. `lib/primus/experiment/assessment.rb`. |
| `Primus::Experiment::Evaluator` | Stateless query `assess(observation:, expectation:)` returns an Assessment without executing, persisting, or mutating its inputs. Plaintext only now. `lib/primus/experiment/evaluator.rb`. |
| `Primus::Experiment::LogEntry` | One attempt's identity/status metadata, validation failures, execution errors and optional Observation/Assessment references. `lib/primus/experiment/log_entry.rb`. |
| `Primus::Experiment::Store` | Filesystem snapshots/serialization and read-only history lookup/review under `output_path:`. `lib/primus/experiment/store.rb`. |

A Ruby class can contain nested classes: make Experiment the real model and
keep its collaborators nested. No parallel Definition model, namespace-only
Experiment module, external precondition validator or validation-result
wrapper is needed. Add explicit requires in `lib/primus.rb`. Keep filesystem
orchestration out of Transcription and cipher visitors. JSON hashes belong
at the persistence boundary; they are not the callable run contract.

Recommended lifecycle (API illustration only, not implementation):

```ruby
experiment = Primus::Experiment.load(path: definition_path)
experiment.valid?                         # read-only validation, boolean
experiment.errors.full_messages          # model-owned reasons
runner = Primus::Experiment::Runner.new(
  experiment: experiment, output_path: output_path
)
runner.run                               # command: nil on normal completion
runner.observation                       # produced Observation, or nil
runner.assessment                        # Assessment when evaluated, or nil
runner.log_entry                        # attempt or prior-attempt reference
```

`run(rerun: true, reason: "Check repeatability")` also returns nil and requires
a nonblank reason. Reusing a runner clears its current readers first; earlier
objects and files remain unchanged. Invalid Experiment means no transform,
no Observation and no Assessment, with reasons on `experiment.errors`.
Mismatch is a valid experiment with an Observation and mismatching Assessment;
it must not add model validation errors. Output-path safety (including overlap with inputs/oracles), creation/writability
and persistence failures are operational failures, not scientific mismatches.
Operational failures raise a meaningful typed exception after best-effort
recording; they never return a fabricated success object. An Observation may
survive an error after output production, but its existence does not assert
that persistence or assessment completed. Assessment is nil if not performed.

On a prior-run hit, `log_entry` references that saved attempt; no new
Observation is produced, so `runner.observation`/`assessment` remain nil.
The Store's review query exposes the earlier saved observation/assessment.
A thin command uses the record to explain reused history and exit status.
This distinguishes fresh execution from prior evidence without result hashes.

### Hydration, validation and commands

`Experiment.load(path:)` safely parses YAML and constructs the model through
ActiveModel attribute assignment. Prefer its supplied initializer and a
factory; do not override initialization just to duplicate attribute handling.
Unknown/unsupported fields in a parseable mapping become model errors, not
ignored options or accidental unknown-writer exceptions. Required fields,
paths, input/oracle readability, source-body shape/encoding and digests are
model preconditions. Keep useful stage/type diagnostics for persisted failures
and command reporting without fixing English prose as a model contract. Use
ActiveModel errors directly; do not introduce an error-query facade for tests.
`valid?` refreshes errors rather than accumulating duplicate messages. Capture
input/oracle bytes once per validation pass; run uses exactly the snapshots
from its own successful `valid?` call, never a second file read. Standalone
validation may precede a run; the run must revalidate potentially changed files.

Malformed definition YAML, duplicate keys, forbidden tags/aliases, invalid
encoding or a nonmapping root prevent hydration and raise a clear definition
load error; an unreadable definition raises an identifiable I/O load error.
No Experiment is falsely claimed valid when none could be hydrated. The
command reports these distinctly from an existing model's validation errors.
Malformed source YAML is a configuration error on the hydrated Experiment;
missing source/oracle files are errors there with file/I/O detail.

Validate-only hydrates an Experiment, calls `valid?`, and reports its errors.
It never invokes Runner, transforms, writes records or builds a success object.
Add `Primus::Commands::Experiments` in `lib/primus/commands/experiments.rb`,
register in `bin/primus`, and document `experiments validate <definition>`,
`run <definition> --output-path <directory>` and `review <id>` with optional
run ID. Review queries Store snapshots without re-execution/revalidation of
current research files. Run accepts `--rerun --reason ...`. All public storage
arguments use `output_path`, replacing `store_path`.
Invalid/error/mismatch exits nonzero; match or reuse of a prior matching
attempt exits zero. Reused failures/incomplete attempts stay nonzero.

### Failed attempts are not observations

Retain the prior durable-history requirement with a separate LogEntry for
one attempt. Store owns history; Runner does not become an ExperimentLog. An invalid Experiment can have an `invalid` attempt record and
available definition/input snapshots while its Observation/Assessment are nil.
The record serializes errors from the model, never a second validation model.
If hydration itself fails, the command asks Store to retain a failed load
attempt with available raw bytes/path and unknown identity fields left null;
use a reserved failed-load directory when no trustworthy experiment ID exists.
This is a small explicit tradeoff: one attempt-record role preserves reviewable
failures without inventing scientific output. Validate-only remains read-only.
If output storage is unavailable, report the failure honestly without claiming
a durable record. Interrupted attempts keep `running`; no completed assessment
is inferred. Never manufacture an Observation for invalid/error bookkeeping.

### Flat durable record store

Default `experiments/runs/<experiment-id>/<unique-run-id>/`, locally retained
and ignored by Git; definitions and oracles are tracked. Permit an explicit
`output_path` directory for tests and user retention. No database/index is needed:
scan records for one experiment. Review can list definitions with no attempts
as planned and show existing attempts; don't create a separate mutable ledger.

Per attempt save `definition.yml`, `input.yml`, `source-body.txt`,
`expected.txt`, `output.txt` when produced, `provenance.json`, and `record.json`.
All byte artifacts have recorded byte length and SHA-256. Definition bytes
and relevant observed files are retained even for invalid attempts where
available; unavailable fields remain null with errors, never invented values.
Standalone validation prints checks without creating a run. A failed run
validation retains its errors and available snapshots. Review reports unreadable
records/missing artifacts clearly; comprehensive archive-integrity checking
and automated recovery are deferred.

Version-1 record contains run/experiment ID, action, start/end UTC times,
definition snapshot digest, resolved configuration, source and oracle paths
and declared/actual digests, runtime version, Git HEAD, clean-code check,
execution fingerprint, previous matching run IDs, rerun
reason, configuration/integrity check details, status, comparison, errors,
and artifact manifest. Serialize optional `observation` and `assessment`
sections; `comparison` is only the serialized assessment summary (or
`not_checked` when Assessment is absent), not a separate domain result.
Status vocabulary: `running`, `invalid`,
`matched`, `mismatched`, `error`; comparison: `match`, `mismatch`, `not_checked`. Preserve stage/error type/message. Reserve
the directory and initial record before execution and atomically replace the
record on completion. An interrupted `running` record requires deliberate
rerun; do not silently claim completion or resume.

For deterministic prior-run identity use a versioned SHA-256 fingerprint of
sorted-key JSON containing parsed definition data, actual source/oracle
digests, Git HEAD and Ruby version. Record the raw definition digest too;
YAML-only formatting does not defeat repeat detection. Require tracked
executable/dependency files (`lib/`, `bin/`, `Gemfile`, `Gemfile.lock`, `primus.gemspec`,
`.tool-versions`) to match HEAD, and reject additional untracked executable
files there. Definitions/oracles may be edited because their exact bytes
are snapshotted. This clean-code requirement is a proposed first-milestone
tradeoff: support for dirty-code research runs would need a later explicit
code snapshot/fingerprint policy. No auto-commit is performed by the harness.
HEAD identifies repository code, not the whole host environment; capture
runtime version and state this reproducibility limitation in documentation.
A different HEAD conservatively creates a new run identity even when only
unrelated files changed. No semantic-equivalence claim is made.

The initial workflow is a single local invocation at a time. Use unique run
directories and atomic record completion without overwrites; simultaneous
prior-run lookup/deduplication is not promised. Concurrency locking and
recovery machinery are deferred. An interrupted record remains incomplete
and requires a deliberate rerun; do not silently discard history.

### Verification handoff

Use configured Ruby 2.7.4 (`.tool-versions`); prior planning found it at
`/Users/chriswoodford/.asdf/installs/ruby/2.7.4`. Recheck runtime/bundle baseline;
default shell Ruby was 2.6.10. Do not upgrade dependencies to repair the shell.

### Dependency decision

Ruby 2.7.4 was verified locally. Gemfile delegates to `primus.gemspec`;
neither the lockfile nor that runtime's installed gem set contains ActiveModel
or ActiveSupport. Implementer must add a runtime `activemodel` dependency in
`primus.gemspec`, require `active_model`, and resolve a Ruby-2.7-compatible
lockfile. Recommended bounded candidate: `~> 7.1.6` (excludes 7.2).
Official [ActiveModel 7.1.6 metadata](https://rubygems.org/gems/activemodel/versions/7.1.6)
requires Ruby >=2.7 and ActiveSupport exactly 7.1.6;
[ActiveSupport metadata](https://rubygems.org/gems/activesupport/versions/7.1.6)
also allows Ruby >=2.7. This verifies top-level compatibility only, not a
resolved transitive bundle. Confirm transitive constraints and Bundler 2.1.4
compatibility during implementation; avoid unrelated upgrades. No gems were
installed or dependency files edited during planning. Use only ActiveModel,
not Rails/ActiveRecord or a database. The official
[Model API](https://api.rubyonrails.org/v7.1/classes/ActiveModel/Model.html) and
[validation API](https://api.rubyonrails.org/v7.1/classes/ActiveModel/Validations.html)
support attribute initialization and model-owned `valid?`/`errors`.

Shoulda is absent from `primus.gemspec`, `Gemfile.lock`, spec configuration
and the configured Ruby's installed gems. Plan a development-only
`shoulda-matchers ~> 5.3.0` dependency and narrowly include its ActiveModel
matchers in the Experiment validation examples; no Rails/ActiveRecord setup.
[5.3.0 gem metadata](https://rubygems.org/gems/shoulda-matchers/versions/5.3.0)
allows Ruby >=2.6; [6.0.0 metadata](https://rubygems.org/gems/shoulda-matchers/versions/6.0.0)
requires >=3.0.5, so do not select current/latest blindly. This is a candidate,
not a verified Shoulda/ActiveModel 7.1 runtime combination: verify the resolved
bundle and the actual presence/inclusion/format matchers under Ruby 2.7.4
before relying on them. Record any incompatibility rather than upgrading Ruby
or replacing custom integrity behavior with a fictional matcher. Dependency,
lockfile and test-helper changes belong to the subsequently authorized work;
no installation or dependency edits occur here.

### Test style and ownership decisions

The user rejects bundling independent assertions to satisfy one `expect`.
For custom integrity rules, the example “rejects an input whose digest does
not match” checks `expect(experiment).not_to be_valid`; it does not pair a
boolean with `errors.full_messages.join` and a prose regex. Use `be_valid`
for validity and predicate matchers for other boolean behavior. Keep standard
presence/inclusion/format checks as supported Shoulda matchers; do not invent
a digest/path-integrity matcher or duplicate the standard matcher's cases.
A focused valid fixture guards against every custom case passing because all
models are invalid. Avoid retesting ActiveModel's own error accumulation.
If custom snapshot refresh could regress, test changed input being rejected
on the next validation/run instead of error-array mechanics.

Useful diagnostics remain required. Hydration and operational errors retain
meaningful typed failures; tests assert that failure category without coupling
to incidental English. Stage/type belongs in the saved failure schema and
command behavior where it informs a user. Do not require extra structured
reason methods solely to make tests convenient. A message assertion is warranted
only for an intentional external reporting contract, not every invalid input.

The following is a responsibility correction, not a dot-count exercise:

| Existing reach-through | Smallest responsible interface / test home |
| --- | --- |
| `runner.observation.output_bytes` | Observation owns `output_bytes`; exercise produced bytes on that result in one integration scenario. Runner tests cover execution/readers' lifecycle. Do not add `Runner#output_bytes`. |
| `runner.assessment.comparison` and `first_difference_byte` | Evaluator returns Assessment; compare its cohesive comparison/difference/length attributes directly there. Do not add forwarding comparison/difference methods to Runner. |
| `runner.run_record.run_id`, `.status`, `.previous_run_ids`, `.rerun_reason` | Rename reader to `log_entry`; LogEntry owns one attempt's identity and rerun metadata. Store owns prior lookup and returns the selected LogEntry for review. Runner only exposes the current/reused entry. |
| `prior.assessment.comparison` alongside `prior.status` | Review verifies saved attempt status/identity/artifacts at the Store or CLI boundary. Detailed byte comparison belongs to Assessment/Evaluator. A historical assessment may remain associated with an entry; no result-traversal facade is needed for duplicated assertions. |
| `experiment.errors.details.values.flatten.map` | Remove generic framework-structure checks. Assert custom rejection on Experiment; retain stage/type checks only once in the persisted failure contract. |

Binding an Observation or Assessment to a local variable makes its ownership
clear but alone does not fix misplaced behavior. Move the assertion to the
responsible boundary and remove duplication first. Retain the approved readers;
do not create forwarding methods, wrappers, aliases, or new classes to shorten
specs. `record.json`, `run_id`, `previous_run_ids`, schema version and durable
status vocabulary stay unchanged: the Ruby naming correction does not require
a gratuitous file-format migration. LogEntry is not a ledger/history manager.

Arrays are appropriate for a real ordered sequence (all provenance coordinates
or linked prior IDs); named attributes/hashes make one cohesive result/schema
clearer than positional tuples. Split command return, model validity, output,
status and filesystem counts when they are independent behaviors. Do not split
every field of a byte-difference summary or artifact identity into a separate
example. Never hide independent checks in `have_attributes` instead of arrays.

### Required next test-writer reconciliation (not invoked now)

These are the actual eight files at `9311be1`, totaling 75 examples. The earlier
24-example migration list is obsolete: hydrated Experiment, `output_path:`,
nil-return command and Observation/Assessment are already in the red specs.
Class specs mirror the full namespace; scenario specs remain in `spec/features/`.
No source, tests, fixtures or dependencies change in this planning pass.

| Existing path / count | Concrete next changes |
| --- | --- |
| `spec/lib/primus/experiment_spec.rb` — 17 | Split “hydrates a saved definition that validates as page 57” into hydration identity and valid-fixture behavior. Replace all seven validity-plus-message tuples under `#valid?` with supported standard matchers or focused custom `be_valid` examples. Rename oracle integrity, missing expected-file and unknown-field descriptions to the rejection they verify. Delete the two stage-metadata traversal examples in favor of saved-failure coverage. Remove “refreshes errors rather than accumulating them” as framework coverage; preserve real input revalidation coverage in the identity scenarios. Hydration examples assert meaningful load failure categories without regex prose coupling. |
| `spec/lib/primus/experiment/runner_spec.rb` — 12 | Rename every `run_record` reference to `log_entry`. “creates a separate attempt when the oracle changes” checks distinct attempt identity; comparison already belongs to Evaluator. Split “recognizes a prior mismatch without executing again” into reuse and no-new-execution behavior, avoiding status/output/count tuple. “keeps an earlier Observation unchanged when rerun” checks unchanged earlier bytes; remove the object-identity boolean unless identity itself becomes a required contract. Preserve all-symbol and digraph provenance; `actual` sequence already proves length, so remove redundant `[actual.size, actual]`. Keep artifact identity and saved schema tests at the persistence boundary, using named fields. Split count from “persists a completed machine-readable run record”. Remove message regex from reason/output-path errors in favor of the intended failure category. |
| `spec/lib/primus/experiment/evaluator_spec.rb` — 3 | Keep exact match and trailing-byte comparison summaries as cohesive Assessment assertions with named fields. Split “reports the first differing byte without changing the output” into the mismatch summary and nonmutation behavior. No Runner-based forwarding API. |
| `spec/lib/primus/experiment/store_spec.rb` — 3 | Review yields LogEntry. In interrupted/error examples assert the saved status; verify absent scientific result once in the relevant saved schema contract instead of duplicating tuple checks. Corrupt-record behavior asserts a meaningful storage failure category, not JSON-library prose. |
| `spec/features/run_page_57_experiment_spec.rb` — 7 | Rename `run_record`. “validates ... without creating an attempt” separates validity from no writes (CLI no-write scenario is authoritative). “returns nil ... and exposes domain results” becomes a focused nil-command contract; exact output and comparison belong to separate scenario/result assertions. “runs the tracked ...” needs the known-output/match outcome, not redundant attempt status. Prior reuse separates current-reader absence from same historical identity/no new attempt. Explicit rerun verifies cohesive entry reason/link metadata separately from new-attempt creation. Review after oracle change verifies historical status/evidence without drilling into comparison again. Preserve the paired exact source-YAML/body snapshots as one lossless persistence contract. |
| `spec/features/reject_page_57_experiment_spec.rb` — 6 | Rename `run_record`. Replace “puts the integrity reason on the Experiment model” with “rejects an input whose digest does not match” and a single negative validity predicate, preferably in Experiment spec rather than duplicating it here. Split invalid command return, durable invalid entry, and absence of scientific output. Reuse tests focus on no new execution. “produces an Observation and a mismatching Assessment” must not combine errors/status/comparison/offset/output prefix; keep mismatch integration and delegate detailed results to their owners. Preserve invalid saved-schema and independent expected/actual artifact checks. |
| `spec/features/page_57_experiment_identity_spec.rb` — 18 | All dirty/untracked/source-YAML/body/encoding/missing-file/revalidation rejection tuples separate failed exit from suppressed output and incidental diagnostics. Keep changed source/HEAD/definition and formatting-only identity cases. Execution-error/interruption/reused-error tuples separate exit behavior from durable state. “requires an explicit reason to retry an interrupted attempt” currently only counts a reason-bearing second record: describe its actual intentional-rerun history behavior; blank-reason rejection is covered in Runner. Snapshot-consistency example checks saved original bytes without bundling exit/status. Saved JSON traversal remains legitimate here. |
| `spec/lib/primus/commands/experiments_spec.rb` — 9 | Separate exit status, meaningful reporting and written records throughout validate/run/review; use `be_success`/negative predicate rather than literal booleans. Keep one focused reporting contract for model-vs-load failure and one for missing artifacts; assert useful stage/path/category, not incidental prose or every validation message. Rename no domain APIs beyond actual occurrences. |

Do not automatically add Observation/Assessment/LogEntry reader or serializer
unit specs. Add a full-path domain spec only if nontrivial behavior remains
uncovered at its owning boundary. Avoid adding factories, generic matchers or
an error taxonomy solely to support this rewrite. The five-line guideline is
a heuristic, not grounds to fragment readable setup or design new abstractions.

Prior tests are proposed coverage, not implementation evidence. Keep the narrow
page-57 harness and original acceptance criteria. Reassess unproven gaps after
rewriting: actual execution suppression, current-reader reset, validated byte
snapshot consistency, output-path/unwritable and partial-write failures,
source/definition I/O safety, all provenance and historical artifact retention.
Do not preserve duplicated or awkward tests merely to maintain a count of 75.

Use temporary output directories. A later authorized test-writing pass should
confirm intentional red failures, then implementation should run focused harness,
Builder/Translator/provenance and known-solution regressions, full suite and
required lint. This docs-only pass does not rerun or claim new test results.

## Edge cases

Empty YAML/body; wrong page/path; bad UTF-8; unknown fields; stale oracle;
CRLF/final whitespace/digraphs; duplicate execution requests; incomplete
records; missing artifact; read/write failures; dirty code. Saved records
report the comparison made at execution time; they do not attest that a user
has never subsequently edited the archive. Comparisons never use
source-rendering shortcuts.

## Out of scope

Page 56 implementation; hash expectations/adapters; arbitrary stage lists;
new cipher algorithms; Atbash/Vigenere fixes; generic plugin/serializer
registry; search/scoring/database; automatic equivalence between differently
specified experiments; source image audit; changes to source-coordinate
semantics; broad cleanup; publishing/pushing; test-writer invocation now.

## Open questions

The recommended exact-byte policy deliberately retains current compatibility
output, not modernized English. Changing that research preference requires
an explicit alternative policy/oracle. Local run directories are proposed
as durable local history, not automatic shared archival: whether selected
runs should later be committed/exported or backed up is a user retention
decision. This milestone preserves them and explains their location; it
never auto-deletes or auto-commits research results. YAML/file names remain implementation choices; the approved Experiment,
Observation and Assessment roles and command/query contract are settled; no broader framework is implied.
LogEntry is the approved single-attempt name. A reserved failed-load
directory remains a recommended persistence choice to preserve the earlier failure-history requirement; it does not
change the approved nil-Observation behavior. Prior reuse exposing only the
prior LogEntry is the recommended distinction between current and historical
output. The dependency candidate still needs a compatible resolved bundle.
The clean-code prerequisite is an explicit minimality proposal, not an
existing user requirement; accommodating dirty-code runs is a separate
tradeoff if needed before implementation.

## Next milestones

[Page 56](page-56-harness-experiment.md) is implemented. The separate
[page-57 SHA-512 control](page-57-hash-control.md) is the next bounded work
record; its criteria do not expand this completed plaintext milestone.
