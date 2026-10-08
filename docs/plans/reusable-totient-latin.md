# Reusable totient Latin and complete page 56 control

## Goal

Expose the existing prime-totient transformation as a page-independent v2
`totient-latin` recipe with validated CLI/YAML parameters. Complete a page-56
known-answer control against independent plaintext, SHA-512, BLAKE2b-512 and
original BLAKE-512 before planning page-55 experiments.

Planning only: stop after the documentation WIP commit. No source, tests,
cryptographic oracle execution, push or PR in this step.

## Verified baseline and delivery order

On 2026-10-08 clean local `main` and `origin/main` both resolve to
`45d4380ee3c670df64f76a555855a81e0dfcbdde` (multiple checks), following
`67113c5` (CLI discoverability) and `f2b6cf8` (single-check composition).
No remote refresh or new suite run is claimed. Branch:
`codex/reusable-totient-latin`.

This advances only the reusable-totient part of composable increment 4,
including the complete page-56 control, ahead of increment 3. Saved-output
reassessment/reuse and general preset overrides remain deferred. Existing
multi-check execution already supplies the required assessment/persistence
boundaries; no preparatory refactor is necessary. Do not manufacture one
from legacy class size or a strict five-line heuristic.

Actual ownership and behavior inspected:

- `Experiment` accepts only `{id: latin}` for v2. V1 binds page 56 to
  `totient_shift_to_latin` and exactly modulus 29, prime_start 2 and
  skip_sequence [56]. Keep that compatibility path unchanged.
- `Runner#derive` currently bypasses cipher processing for all v2 input.
  Its v1 path constructs `Prime.each.lazy.drop_while` below prime_start,
  creates a fresh `Document::TotientShift`, and supplies skip_sequence.
  Thus prime_start is a prime **value**, not a zero/one-based prime index.
- `TotientShift` subtracts `(p - 1)` modulo the alphabet size 29.
  `Decoder#process` increments its GP counter at a skipped symbol but
  does not call decode, so does not consume a prime. Non-GP tokens consume
  neither a GP ordinal nor a prime. No second cipher implementation is needed.
- Existing provenance selects indexed GP tokens, keeps original byte spans
  and source rune, and stores decoded_rune and final Latin expansion.
  The Builder/Translator/Decoder chain already preserves source locations.
- Read-only inspection confirms the tracked oracle is 255 bytes with no
  terminal LF and equals the existing page56_latin fixture after rstrip.
  The encoded body contains 85 runes; ordinal 56 is `ᚠ`, ordinal 57 `ᚫ`.
  Existing specs pin the resulting `f` and `e`, and GP ordinals 0...85.
  The documented next prime at ordinal 57 is 269. This inspection is not
  a fresh end-to-end or independent hash verification.

## Acceptance criteria

### Recipe, defaults and parameter boundary

- V2 `totient-latin` accepts any otherwise valid whole-page input and
  scenario ID. It must not infer page number, a skip, or an expected result
  from an ID. Prove with an arbitrary-ID fixture and a small non-page-56
  source; do not run page-55 research to prove page independence.
- Canonical v2 recipe is `id: totient-latin` with nested `parameters`:
  `modulus: 29`, `prime_start: 2`, `skip_sequence: []` by default. Missing
  parameter mapping or omitted individual keys receive these defaults;
  explicit null, malformed mappings and unknown keys are invalid. Persist
  all resolved defaults in canonical configuration before ad-hoc identity
  generation; preserve original supplied YAML bytes separately.
- `modulus` must be Integer 29. `prime_start` must be an Integer prime at
  least 2 and names the first prime consumed. Composite starting values,
  numeric strings, floats, booleans, zero and negatives are invalid; do not
  silently round a composite up even though the old iterator could do so.
- `skip_sequence` must be an array of unique nonnegative Integer ordinals
  strictly less than the actual selected input's GP-symbol count. Reject
  duplicates, negative/out-of-range entries, strings, floats, booleans and
  null. Empty is valid. Canonicalize the valid set into ascending order;
  do not remove duplicates to make invalid input valid.
- Ordinals are zero-based original GP rune ordinals in the selected whole
  page, not text-character, byte, Latin-expansion or prime indices. Use the
  existing transcription alphabet/token classification to establish count;
  do not build a second lexer or count the hexadecimal block as GP symbols.
  The current broad source regex is not sufficient to validate skip bounds.
- Current `latin` canonical shape stays `{id: latin}` and rejects parameters,
  including empty/null mappings. V1 parameters, fingerprints, expected output,
  controls, statuses and saved-history reading remain unchanged.
- Both `validate` and `run` accept repeatable scalar
  `--recipe-param KEY=JSON_VALUE`, using Thor's existing `repeatable: true`
  facility. Split once at `=`, parse the value with JSON, and let the same
  recipe/model validation used by YAML validate the resulting typed values.
  Reject malformed JSON, missing key/value, duplicate keys even when equal,
  unknown keys and parameters without a recipe. Direct Composition callers
  may pass scalar/array options just like existing repeated checks.
- Continue rejecting positional preset plus composition flags, including
  recipe-param alone; no override semantics are introduced. Support both
  `--recipe-param key=value` and `--recipe-param=key=value`. The new option
  belongs in composition-request detection so it cannot be silently ignored.
- YAML and equivalent CLI resolve to identical canonical semantic choices,
  including implicit versus explicit defaults and ordered checks. Parameter
  flag order cannot change ad-hoc identity. Preserve current latin IDs.
  Validation remains offline and rejects invalid parameters/source/oracles
  before transformation without probing hash backends.

Proposed CLI examples (digest placeholders are illustrative, not runnable
known answers; preparation below supplies the literal values):

```shell
bin/primus experiments validate --input page-56 --recipe totient-latin --recipe-param modulus=29 --recipe-param prime_start=2 --recipe-param 'skip_sequence=[56]' --expect-text experiments/expected/page-56-totient-latin.txt
bin/primus experiments run --input page-56 --recipe totient-latin --recipe-param 'skip_sequence=[56]' --hash sha512 --hash blake2b512 --hash blake512 --expect-digest sha512=SHA_HEX --expect-digest blake2b512=BLAKE2_HEX --expect-digest blake512=BLAKE_HEX --expect-text experiments/expected/page-56-totient-latin.txt --expect-provenance 'Independent page-56 oracle record'
```

The corresponding YAML recipe is:

```yaml
recipe:
  id: totient-latin
  parameters:
    modulus: 29
    prime_start: 2
    skip_sequence: [56]
```

Retain schema_version 2, input `{id: page-56, sha256: ...}`, the existing
output policy, and four existing-format check mappings. Use hash checks in
sha512/blake2b512/blake512 order followed by plaintext and IDs check-1 through
check-4 for CLI-equivalent comparison. Each hash expectation has its own
literal digest and provenance; plaintext has path, sha256 and provenance.

### Transformation, evidence and complete control

- Reuse Builder -> Translator -> fresh TotientShift -> existing Printer.
  The transformed GP index is `(source_index - (prime - 1)) % 29`.
  Fresh execution always starts its own prime stream and counter; no leaked
  state on repeated v2 attempts or interleaved v1/v2/latin execution.
- For the known page-56 settings, original GP ordinal 56 remains `f` without
  consuming a prime, and ordinal 57 becomes `e` using prime 269. Non-GP text,
  including every hexadecimal character, is unchanged by the cipher and
  consumes no ordinal or prime. Preserve source tokens and all source spans;
  the source rune must not be overwritten with the decoded rune.
- Output exactly matches the independently sourced 255-byte plaintext under
  `gp-latin-compatibility-v1`, with 85 GP provenance entries. Preserve wraps,
  blank lines, punctuation, canonical GP spelling (`euery`, `seec`) and
  unchanged hexadecimal case. Existing compatibility delimiters and final
  rstrip remain policy; no new normalization of output or expectations.
- Add a named v2 control `page-56-totient-latin-controls.yml` alongside the
  existing v1 file, selecting explicit [56] rather than relying on a default.
  Its one persisted Observation receives all four checks. Acceptance of
  **this known control** requires four matches, zero mismatches and zero
  errors, independently pinned expected and observed digests, and truthful
  saved review evidence. Exit zero or any-match alone is insufficient to
  certify the control.
- Do not change general multi-check semantics: any match makes
  matching_outcome matched, while completion/error status remains separate.
  Keep every result; a backend failure or mismatch must not suppress later
  checks. Reuse established failure/ordering coverage rather than duplicate
  an algorithm matrix. New control evidence labels SHA-512, BLAKE2b-512 and
  original BLAKE-512 distinctly; the page's embedded hex text is not any of
  these expected output hashes.
- V2 execution identity includes canonical parameters and genuine source
  selection (input ID/path/page identity as well as actual source digest),
  because equal bytes from different pages have different provenance.
  Checks, expectation provenance and backends remain excluded from execution
  identity. Existing per-check assessment identity stays independent. Do not
  add lookup, caching, deduplication, reassessment or historical migration.
  Keep version-1 fingerprint untouched and old v2 records readable; document
  the additive input-selection ingredient in new v2 execution fingerprints.

## Approach

`lib/primus/experiment.rb` owns recipe shape, canonical defaults and typed
validation across CLI/YAML, with input-dependent bounds after successful
source parsing. A small recipe collaborator is justified only if it owns
these rules coherently; no registry, public forwarding tree or generic parser
framework. Canonicalization must be deterministic/idempotent across repeated
validations and must not mutate callers' input or raw definition snapshots.

`lib/primus/experiment/composition.rb` collects the one new repeatable option
and constructs the same canonical recipe before computing its ad-hoc ID.
Reuse a shared recipe boundary rather than duplicate defaults in Composition
and Experiment. Preserve the ordering/IDs of existing check composition.
`lib/primus/commands/experiments.rb` declares and detects the option, keeps
thin orchestration and documents discoverability/review behavior.

`lib/primus/experiment/runner.rb` selects the validated v2 recipe rather than
bypassing all v2 derivation. Its current v1 totient setup should serve both
paths, retaining all arithmetic/skip behavior in Document::TotientShift and
Decoder. Extend the existing identity inputs narrowly. Count original GP
symbols through existing transcription/token infrastructure, with no extra
cipher execution in validation. Actual source snapshots drive execution.
No change to reversal APIs or reinterpretation of source coordinates.

Add the v2 definition under `experiments/definitions/` and retain the existing
expected plaintext. Put independently established literal digest evidence in
an appropriate research/oracle record and spec fixture during preparation.
README gains defaults, value semantics, skip convention, CLI/YAML examples
and the complete control command. Evaluator, hash implementations and Store
should require no feature changes unless a concrete failing contract proves
otherwise; do not widen this into legacy cleanup.

### First handoff prerequisite: independent oracle preparation

Before invoking test-writer, the root/preparation step must supply a vetted
literal fixture packet. Do not repeat a handoff that requires test-writer
to fetch an unavailable oracle, and never substitute candidate output for
missing expected values. Planning has not calculated these digests.

1. Freeze the exact independent bytes from decoded page_56.yml body with
   the existing rstrip extraction. Confirm byte agreement with the tracked
   plaintext and fixture; record 255 bytes, no BOM/terminal LF, source path,
   source SHA-256 and extraction policy. The existing v1 declaration records
   decoded source SHA-256
   `45bda9f7ae9018cc4257b0acaaf30e95a8366f06acf7a4a52b137b555a590b64`
   and expected-file SHA-256
   `be341e15b67a3363b429319e23fd8ef4d172b9aea879016402bdd477348e7868`;
   preparation re-verifies these rather than trusting this plan.
2. Establish literal SHA-512 and unkeyed 64-byte BLAKE2b expectations with
   independent tools (for example Python hashlib over the frozen bytes,
   cross-checked with standalone OpenSSL). Record exact commands, tool
   versions and results, making independence from Primus wrappers explicit.
3. Establish **original** BLAKE-512 using separately implemented
   `@noble/hashes` 1.8.0, pinned commit
   `32f700f38ec49d7e6b2ab687904d6b2d7d60d80a`, with the package/source
   checksums and verification procedure in sibling
   `../blake512-ruby/VECTORS.md`. Read-only reference; no gem changes.
   Verify archive SHA-256
   `e8a765d92c04faaccba8776411c5038cb195f812ee629fce07e1d2e6aec80ea0`
   and src/blake1.ts SHA-256
   `bc232796e5e0811d81d96b120c41ef7166f9df2f5d5af516075be31571f6f586`.
   Obtain/pre-stage a verified package if network access is constrained.
   Cross-check against the pinned designer C implementation if available;
   C CLI versus its Ruby binding alone does not establish independence.
4. Record literal 128-character lowercase answers and provenance for every
   algorithm in the reviewed packet; demonstrate which exact bytes were
   hashed. Expected values are copied into fixtures/preset, never generated
   by the system under test at runtime. If any oracle is unavailable, report
   that preparation gate concretely and do not hand incomplete fixtures to
   test-writer or claim the four-check control verified.

### Incremental test-writer and implementation handoff

After plan review and oracle preparation, proceed in small reviewable slices:

1. Retain green v1 page-56 output/provenance and existing f/e boundary controls.
   Add only a missing characterization for explicit prime consumption around
   the skip: original ordinals 55/56/57 consume prime 263/no prime/269.
   Characterization is expected green before implementation.
2. Begin new red behavior at actual CLI validate/run with repeatable
   recipe-param flags and the four independent known-answer checks. Verify
   the failure is unsupported new behavior, not fixture lookup, fetch,
   encoding, dirty-code or stale-clone setup. Add default and custom YAML/CLI
   canonical equality and invalid typed/unknown/duplicate parameters at the
   shared model/Composition boundary. Then implement the narrow recipe path.
3. Prove default [] differs from explicit [56] on the same page, and a small
   independent source works under arbitrary ID with a custom prime start.
   Exercise first/last skip bounds, adjacent skips, GP digraphs and non-GP
   separators without enumerating redundant permutations. Pin literal small
   outputs independently: no copying the implementation formula into tests.
4. Pin full page-56 output and each of the three literal digest agreements as
   separate behaviors; add one coherent four-result completion summary and
   saved review contract. Retain existing generic partial-failure/any-match
   regressions. Check original versus decoded provenance and repeat-state
   independence through public results. Source-selection/parameter changes
   alter execution identity; check-only changes do not. No cache tests.

Use `spec/lib/primus/commands/experiments_composable_spec.rb`,
`spec/lib/primus/experiment_composable_spec.rb`,
`spec/lib/primus/experiment/runner_spec.rb` and `runner_multiple_spec.rb`,
plus existing TotientShift/provenance specs where a genuine gap exists.
Use current full namespaces (`Primus::Experiment`,
`Primus::Experiment::Runner`, `Primus::Document::TotientShift`); add a
Composition/recipe spec only for behavior that belongs there. Avoid new
algorithm-specific files for this recipe. Reuse existing v1 page-56 feature
and all page-57 controls as regressions, not duplicated suites.

One behavior and one expectation per example; no let/let!, no tuple packing
of unrelated status/output/errors, no incidental ActiveModel error prose,
no deep collaborator navigation or forwarding APIs for tests. Supported
standard validations use Shoulda; custom parameter/cross-field rules assert
model validity. Keep explicit setup/exercise/verify spacing and plain local
fixture helpers. Repository fixtures are established here; do not introduce
FactoryBot merely because the general skill mentions Rails factories.

Use configured Ruby 2.7.4 and `RUBYOPT=-EUTF-8`. User reports the main suite
passed; `flaky-specs.md` records 562 examples, 0 failures, 12 pending on the
prior implementation and its encoding diagnosis. Any later focused guard
results supplied by the user are historical, not a fresh planner run.
Run relevant model/CLI/runner/totient regressions after meaningful slices,
changed-file lint, then full `bundle exec rspec` with the configured UTF-8
runtime. Preserve intentional WIP code/test snapshots before clone-based
CLI tests; never weaken the executable-code-clean guard.

Log **actually observed** failures in root `flaky-specs.md` during execution:
revision/dirty state, Ruby/encoding, command/seed, exact failure and retry
outcome. Classify expected new-feature reds separately from environment,
implementation or demonstrably flaky failures. Do not revive old diagnosed
failures as open regressions or record tests that were not run. Finally use
a clean implemented snapshot and temporary output to validate/run/review
both the unchanged v1 and complete v2 control. No such results are claimed
by this documentation-only plan.

## Edge cases

Input count versus rune byte length; zero and last valid skip; all GP symbols
skipped; adjacent/unsorted unique skips; unknown runic-looking text not in GP;
non-GP hex and digits; prime 2 versus index 2; empty or malformed input using
existing source rules; invalid typed YAML and quoted JSON scalars; explicit
null versus omitted defaults; repeated validation and source-file replacement;
changed source selection with identical bytes; unchanged original provenance
and final decoded rune; trailing-byte mismatch; unavailable hash backend.

## Out of scope

Page-55 experiments, assigning meaning to skip 56, general preset overrides,
saved-output assess/reuse (increment 3), sections/reversal/chains, new hash or
cipher algorithms, arbitrary modulus/alphabet/direction, prime indices,
automated searches, hash-target interpretation, alternate byte policies,
legacy cleanup/migration, gem changes, release work, pushes and PRs. The
independent CLI error-reporting follow-up remains deferred.

## Open questions and next step

No unresolved design choice blocks this focused plan. Defaults are deliberately
page-independent; the page-56 exception is explicit control data. The only
unfulfilled verification gate is independent preparation of all three literal
hash expectations over the agreed plaintext bytes. After review, complete
that preparation before test-writer. Completing this plan does not authorize
starting page-55 work.
