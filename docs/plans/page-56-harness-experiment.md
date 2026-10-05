# Page 56 through the implemented experiment harness

## Delivery update — 2026-10-03

Implemented at `946431c`, present on local main `e996a6e`. The plan below is
retained as the implementation record. The current third milestone is the
[page-57 SHA-512 control](page-57-hash-control.md), replacing synthetic input.
No page-56 implementation or merge gate is reinstated by historical wording.

## Goal

Define, validate, run, save and review the known page-56 totient decoding
against independent plaintext, using the page-57 harness. Add only the
configuration, execution and provenance behavior this second recipe needs.
The research definition and oracle live outside RSpec; RSpec verifies the
software that executes them.

## Verified baseline and status

Reconciled on 2026-10-01 against `45cab84` (Add a reproducible page 57
experiment harness). At inspection the worktree was clean, local `main`
contained that commit, and `origin/main` remained at `e24b2d7`; local main
was one commit ahead. The old page-57 branch was absent. Page 57 is therefore
integrated locally: the former “wait for page 57 to merge before planning”
gate is satisfied here. This plan branches from `45cab84`, not the stale
remote-tracking ref. No remote publication or merge is inferred or performed.
If implementation starts elsewhere, verify that it contains `45cab84` first.

This is a documentation-only reconciliation. No implementation, fixtures,
tests or dependencies are changed; no next agent is invoked. Previously
reported page-57 verification was 351 examples, zero failures, 12 pending,
and a matching CLI run with 95 rune provenance entries. Those are prior
completion results, not tests rerun by this planning pass.

The actual baseline already has all seven domain classes, the Thor
validate/run/review commands, tracked page-57 definition/oracle, snapshots,
file identities, repeat detection, failed-attempt persistence and history.
Ruby 2.7.4 is configured; `primus.gemspec` and `Gemfile.lock` already carry
ActiveModel 7.1.6 and Shoulda Matchers 5.3.0. Do not repeat the dependency
installation or the obsolete 75-red-example migration in the page-57 plan.
The inspected spec helper does not include Shoulda matchers; use a narrow
ActiveModel matcher include only if new standard-validation examples need it.

## Acceptance criteria

- The tracked definition `experiments/definitions/page-56-totient-latin.yml`
  and independently prepared `experiments/expected/page-56-totient-latin.txt`
  validate through the existing model and CLI. Validate remains read-only.
- Existing schema-1 page-57 definitions remain valid without edits. Exactly
  the two supported page/id/path/operation combinations below are accepted;
  mismatched combinations and unsupported parameters are model errors.
  Malformed definitions remain load failures. No cipher runs when a
  precondition fails, and a writable store retains the invalid attempt.
- Page 56 uses successive prime-minus-one subtraction modulo 29, starting
  with prime 2. It skips zero-based GP processing ordinal 56 without consuming
  a prime. That symbol remains `f`; ordinal 57 decodes to `e` using prime 269.
  Non-GP characters, including every hexadecimal-block character, consume
  neither a prime nor a GP processing ordinal.
- The whole output equals the independent expected bytes under
  `gp-latin-compatibility-v1`. Retain line wraps, blank lines, punctuation,
  canonical GP spelling and the unchanged hexadecimal block. A different
  valid oracle produces a mismatching Assessment, not model invalidity.
- Every decoded GP symbol retains the original SourceLocation. Saved
  provenance distinguishes original input rune from decoded rune and Latin
  expansion. Its ordinal counts only GP symbols; a two-letter expansion is
  one symbol. Hexadecimal characters do not appear as GP provenance entries.
- Execution uses the snapshots from its own validation pass, including
  source YAML/body and oracle. Those saved originals remain exact; normalized
  output is not a replacement for them. Definition parameters are retained
  in configuration and participate in existing fingerprint computation.
- Each actual execution creates fresh Builder, Translator, TotientShift,
  prime stream and counter/skip state. An explicit page-56 rerun and a
  page-56/page-57/page-56 sequence yield the same page-56 bytes. Force the
  second page-56 execution with an explicit rerun reason (ordinary reuse
  intentionally creates no new Observation). Earlier Observation bytes and
  provenance remain unchanged.
- Existing ordinary-repeat lookup, intentional rerun reason/prior link,
  status vocabulary, nil command return, reader reset, review and error
  behavior apply to page 56. Review of a saved attempt uses its snapshots,
  not current research files. New page-56 and old page-57 histories remain
  distinct and readable; no record migration or second history manager.

## Approach

### Small additive definition extension

Keep schema version 1 and the existing scalar `operation`. Add one optional
root field, `parameters`, required only for the new recipe. This preserves
old definitions and avoids changing operation into a stage list or tagged
object. An older binary will correctly reject the new recipe; backward
compatibility means the new binary accepts existing page-57 definitions.

| Field | Page 57, unchanged | Page 56, new |
| --- | --- | --- |
| `id` | `page-57-latin` | `page-56-totient-latin` |
| `input.page_number` | Integer `57` | Integer `56` |
| `input.path` | `data/encoded/liber_primus/page_57.yml` | `data/encoded/liber_primus/page_56.yml` |
| `operation` | `runes_to_latin` | `totient_shift_to_latin` |
| `parameters` | Absent | Mapping with exactly the three entries below |
| `parameters.modulus` | Not accepted | Integer `29` |
| `parameters.prime_start` | Not accepted | Integer `2` |
| `parameters.skip_sequence` | Not accepted | Array containing exactly Integer `56` |

Both retain required title/purpose, `output.policy:
gp-latin-compatibility-v1`, `expectation.kind: plaintext`, repository-relative
safe paths, lowercase SHA-256 checksums and nonblank expectation provenance.
Use real file digests when preparing fixtures, never placeholders. Page 56
has a readable title/purpose naming the known prime-totient recipe.

The operation name fixes subtraction of prime minus one, canonical GP
alphabet order, no prime consumption on a skipped GP symbol, and fresh state
per single-page execution. Document these semantics alongside the saved
parameters; do not add editable direction/reset/alphabet flags with no
supported alternative. The explicit values are deliberately constrained
recipe metadata, not a promise of arbitrary moduli, prime offsets or skips.

In `lib/primus/experiment.rb`, replace the single `ID`/`SOURCE` and hardcoded
57/operation checks with two explicit supported combinations. Extend
`ROOT_KEYS`, hydration attributes and nested unknown-key validation for
`parameters`. Validate the combination as a whole: independently allowing
56/57 and both operations would incorrectly admit cross-wired recipes.
Reject absent/nonmapping page-56 parameters, missing/extra keys, strings or
floats standing in for integers, other skip arrays and any parameters field
on page 57 (including empty or null). Ruby numeric equality alone is not a
sufficient type check. Keep existing file validation, model-owned errors,
stage/type reporting and snapshot refresh; make the source-body diagnostic
accurate for either page rather than saying all bodies contain page-57 runes.

Prefer a small explicit supported-recipe mapping and focused private
validation helpers. This localized extension does not justify a preparatory
refactor or registry. The existing large methods/classes are not a mandate
for broad cleanup, and the five-line guideline remains a heuristic.

### Execution and domain ownership

Keep `Experiment.load(path:)`, `valid?` and `errors`; keep
`Runner.new(experiment:, output_path:)`, `run(rerun: false, reason: nil)`
returning nil, and readers `observation`, `assessment`, `log_entry`.
Observation owns actual bytes/provenance, Evaluator produces Assessment,
LogEntry describes one attempt, and Store owns history. Do not add result
hashes, a Definition wrapper, validation-result objects or forwarding readers
such as Runner output/comparison/run-id methods.

The required changes in `lib/primus/experiment/runner.rb` are localized to
observation production and provenance. Replace the hardcoded
`Page.new(number: 57, ...)` with the validated page identity. Preserve exact
source_body, input artifact bytes and source_path when constructing Page;
retain runic Builder with `track_delimiters: false` and a fresh Translator.
Translator first maps runic tokens into GP tokens with indexes; page 56
then accepts a newly configured TotientShift before `to_s(:letter)`.
Page 57 renders translated tokens directly. Representation preparation is
not an extra cipher layer in reports.

Use the validated modulus, prime start and skip sequence when creating the
visitor; set its existing skip_sequence API and start at counter zero. Never
cache a visitor or enumerator on Experiment/Runner, reuse one across attempts,
or re-lex Latin output to feed the cipher. Existing TotientShift/Decoder
already have the required behavior and retain source locations; no algorithm
rewrite or CipherFactory generalization is needed. Keep recipe dispatch
small and explicit. Add a meaningful ownership method only when it removes
real knowledge from a caller, not a family of delegated hash-field readers
or new objects introduced only to shorten chains in specs.

### Provenance: original symbols versus derived symbols

Current Runner provenance selects every token responding to `rune` and then
numbers that list. Translator's fallback GP token for an ordinary hex letter
or digit also responds to `rune` despite having no GP index. Copying that
selection to page 56 would insert the hexadecimal block into GP ordinals.
Also, after TotientShift, `token.rune` is the decoded rune, not the original
lexeme at its preserved source location. Page 57 concealed this difference
because it performs no arithmetic.

Keep the existing provenance JSON array and old `ordinal`, `rune`, `latin`
fields plus all SourceLocation attributes. Define `rune` explicitly as the
original source rune and `latin` as the final derived canonical expansion.
Add `decoded_rune` for the final GP rune. This is additive for page 57:
`rune == decoded_rune` there, and old saved artifacts without the new field
remain readable by Store. Never rewrite historical records.

Select actual GP tokens with non-nil indexes and valid original rune
locations. Derive the original rune from the Builder's untouched
Transcription lexeme at that SourceLocation (or the validated original body
byte span), never from the decoded token. Pair original and derived symbols
by source identity, not rendered-string index. Offsets address body bytes,
not YAML bytes or Latin output bytes. A focused saved-provenance assertion
should distinguish the first source `ᚫ` from its decoded `ᚪ`/`a`, and the
skip boundary must still use original rune_index 56/57. Source snapshots
retain all non-GP lexemes even though the GP artifact excludes them.

No per-symbol execution trace or prime-consumption ledger is required.
The explicit recipe plus an independent boundary regression proves prime
269 is next; do not duplicate cipher arithmetic in the serializer.

### Independent oracle and exact-byte policy

Prepare the expected text once from
`data/decoded/liber_primus/page_56.yml` body using `rstrip`, matching page 57.
Record that decoded source's SHA-256 and extraction policy in
expectation.provenance. Cross-check the full text against the existing
`spec/fixtures/files/page56_latin.txt` and review the hexadecimal block.
Neither Runner nor TotientShift may generate or update this oracle. These
are local known-solution sources, not a new claim of image-transcription
verification or a newly solved page.

The policy is UTF-8, existing Printer `:letter` rendering with physical wraps
and compatibility delimiters, canonical lowercase GP expansions and final
`rstrip`: no BOM or terminal LF added. Preserve `euery`, `seec`, the split
words, blank lines and hexadecimal case. Internal source hyphens render as
compatibility spaces; exact source punctuation/whitespace stays available in
the separate body snapshot. Do not normalize both operands during comparison
or silently modernize English to make the result match. A trailing-byte
oracle difference must remain a mismatch. SHA-256 continues to identify
files; the page's hexadecimal passage is opaque text, not a hash expectation.

### Persistence, identity and CLI reuse

Reuse existing Store artifacts (`definition.yml`, `input.yml`,
`source-body.txt`, `expected.txt`, `output.txt`, `provenance.json`,
`record.json`) with recorded byte lengths and digests. Parsed definition,
actual source/oracle digests, HEAD, Ruby version and fingerprint version
already determine execution identity; the new parameters naturally enter
that calculation. Formatting-only YAML changes still reuse an attempt.
Do not change fingerprint/record versions or add a recipe-history table.

Preserve `running`, `invalid`, `matched`, `mismatched`, `error`; comparisons
remain `match`, `mismatch`, `not_checked`. Reuse exposes the historical
LogEntry while current Observation/Assessment remain nil. Invalid config
never creates scientific output. A TotientShift execution exception follows
the same best-effort error record path, and interruption remains `running`.
Persistence failure must not be reported as durable success. Existing
failed-load behavior, output overlap checks, single-process assumption and
missing-artifact reporting remain shared behavior, not a second page-specific
implementation. Do not imply review performs a comprehensive archive audit.

`lib/primus/commands/experiments.rb` should need no new command or option.
Later update README usage to validate/run the page-56 definition and review
`page-56-totient-latin`, including intentional rerun and output-path examples.
The two new tracked files, Experiment, Runner, focused specs/fixtures and
README are the expected implementation footprint. Evaluator, Assessment,
Observation, LogEntry, Store, TotientShift and dependencies should remain
unchanged unless a concrete page-56 failure demonstrates otherwise.

### Validation strategy and test reconciliation

Start the later TDD pass with the saved page-56 workflow, then work inward.
Existing page-57/decoder controls should stay green; new recipe acceptance
and correct saved shifted provenance are genuinely new red behavior.
Do not blindly duplicate all page-57 scenarios or recreate the old 75-example
rewrite. Retain shared regressions and add only these extension risks:

| Test home | Incremental behavior |
| --- | --- |
| `spec/lib/primus/experiment_spec.rb` | Valid page-56 fixture; exact two-recipe pairing; required/unknown/malformed parameters and scalar types; page 57 remains valid and rejects cipher parameters. Existing bad-page fixture is a cross-wired combination, not proof that all page-56 input is unsupported; rename its description accordingly. |
| `spec/lib/primus/experiment/runner_spec.rb` | Correct saved source/decoded rune mapping and GP-only ordinal sequence across the hex block; earlier provenance unchanged on a real rerun; fresh cipher state across page-56/page-57/page-56 execution. |
| `spec/features/run_page_56_experiment_spec.rb` | Tracked independent oracle match and exact known output as separate behaviors; retained original snapshots and page-56 review evidence. Keep the research definition outside spec fixtures. |
| Existing TotientShift and provenance specs | Retain unchanged `f` and next `e` controls. Add a small independent prime-stream pause/non-GP-consumption characterization only if existing coverage does not explicitly prove prime 269 remains next; no duplicate whole-page algorithm test. |
| Existing command specs | A focused page-56 validate/run/review path; invalid new recipe yields existing failed-attempt behavior, without copying every page-57 CLI failure. |
| Existing Evaluator/Store/identity scenarios | Run as shared regressions. Existing mismatch/byte-length/nonmutation, history, dirty/untracked-code, formatting/HEAD/source identity, revalidation and snapshot-consistency cases already cover generic behavior. Add only a page-56-specific gap, such as a new cipher failure escaping the shared error path. |

Keep one behavior per example; never hide unrelated validity, messages,
status, output and counts in tuples or have_attributes. Cohesive provenance
or assessment fields may be asserted together. Custom parameter/path/digest
rules use `expect(experiment).not_to be_valid`, backed by a focused valid
fixture. Use supported Shoulda matchers for standard presence/inclusion/
format validations; do not invent custom integrity matchers or couple model
examples to ActiveModel English error text. Typed operational failures and
one useful saved stage/type contract are sufficient. Keep class specs under
their full namespace hierarchy; feature scenarios remain in spec/features.
No speculative reader/serializer specs, FactoryBot introduction or wholesale
cleanup of existing assertion style.

Run with the configured Ruby 2.7.4 and resolved bundle, not the shell's
unrelated Ruby. The harness rejects dirty/untracked executable files under
lib/bin/dependency paths, and identity specs clone committed HEAD. During
implementation, establish a deliberate WIP code/test snapshot before genuine
end-to-end/clone validation; test failure due only to DirtyCode or missing
uncommitted files is not the intended feature red. For an isolated fixture
repository, commit only that fixture's intended changes. Do not weaken the
production gate or auto-commit unrelated user work to make tests pass.

After focused extension tests pass, run existing harness, Builder/Translator,
TotientShift/provenance and known-solution controls, then the full suite and
required lint for changed files. Report any pre-existing lint findings
separately. Finally use the CLI on a clean implemented snapshot with temporary
output storage to verify match, ordinary reuse, reason-bearing rerun and
review for page 56, followed by unchanged page 57. Record actual commands,
results and remaining pending examples; no such new results are claimed here.

## Edge cases

Wrong page/path/id/operation combinations; missing, null or unknown parameter
keys; numeric strings/floats; duplicate YAML keys; invalid UTF-8; missing or
stale files/digests; final newline mismatch; digraphs; hex letters mistaken
for GP symbols; original versus decoded rune identity; skip counted as a
byte/Latin offset; prime consumed at the skip; state leaked through reuse;
code changed between attempts; interrupted/error history and unwritable store.
Shared existing failure handling stays authoritative. Unrelated safety or
storage limitations discovered while reading are separate work, not grounds
to expand this milestone or claim an unimplemented hardening guarantee.

## Out of scope

General chain/stage DSL, arbitrary recipes or parameters, new ciphers,
hash expectations or interpreting the hex block, synthetic experiments,
page-55 search, cross-page continuation/resets, reversals, scoring, dependency
upgrades, generic adapters, source-image audit, broad refactoring, historical
record migration, concurrent execution, pushing, PR creation or merging.

## Open questions and tradeoffs

No unresolved research choice blocks this bounded implementation. The
recommended schema is an additive parameters mapping restricted to this
known recipe, and the recommended provenance addition is decoded_rune while
rune remains original. These are concrete reviewable choices; a request for
arbitrary parameter exploration or a renamed provenance schema would require
replanning that scope, not silently broadening this feature.

The oracle intentionally preserves repository compatibility spelling and
formatting. Changing that preference requires a separately named byte policy
and reviewed independent oracle. Archive export/backup and stronger runtime
or alphabet-data identity remain separate reproducibility decisions: the
current clean-code path list does not cover `data/gematria_primus.yml`, and
its bytes are not separately fingerprinted. This is an existing limitation,
not a page-56 hardening task or a claim of fully captured environment state.
This plan preserves the existing fingerprint policy and its limits.

## Next milestone

The [page-57 SHA-512 control](page-57-hash-control.md) is reconciled against
implemented page 56 and the ID-based CLI. It replaces the synthetic-input
proposal as the third milestone. No two-cipher project or chain engine is
required. This planning pass does not start implementation or execution.
