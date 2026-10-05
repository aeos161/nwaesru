# Page 57 control with a saved SHA-512 expectation

## Goal

Run the existing page-57 rune-to-Latin recipe as a separate saved experiment,
comparing its actual output bytes with an independently prepared SHA-512
expectation. Retain the bytes, digest evidence and history for review while
preserving existing page-57/page-56 plaintext experiments.

This replaces the artificial-input proposal in
[synthetic-hash-experiment.md](synthetic-hash-experiment.md). Page 57 already
provides the simple reproducible transformation and independent known text
needed for this control. A match verifies this software path and exact byte
policy; it does not identify the algorithm or meaning of the historical
page-56 hash or establish any page-55 solution.

## Verified baseline and planning boundary

Inspected on 2026-10-03: clean local `main` at `e996a6e` (experiment-ID CLI),
containing page 56 at `946431c` and page 57 at `45cab84`. `origin/main` is
`c0e93e4`; local main is one commit ahead. Branch this work from actual local
main, not the older remote ref. No merge, push or remote publication is
inferred. The earlier prerequisite milestones are present locally.

The prior verification report was 399 examples, zero failures, 12 pending;
this planning pass did not rerun it. Only plan documents change here: no
implementation, tests, dependencies, generated oracle/definition files,
experiment execution or next-agent invocation. The fixed digest is prepared
and reviewed during the later implementation pass, before its first run.

Inspection found localized changes to explicit definition validation,
evaluation and serialization. No independent preparatory refactor is needed.
Keep existing domain responsibilities and do not turn the large Experiment
or Store classes into a general cleanup project.

## Acceptance criteria

- Add `experiments/definitions/page-57-latin-sha512.yml`, with distinct ID
  `page-57-latin-sha512`, existing page 57 source, `runes_to_latin`, no
  parameters and `gp-latin-compatibility-v1`. The two existing definitions
  remain valid unchanged. Only the three declared recipe/expectation
  combinations below are supported.
- Save a fixed SHA-512 digest prepared from the independently known page-57
  plaintext before execution. Record its source identities, extraction/byte
  policy and independent verification method in provenance. Runner must
  never calculate, update or repair the expected digest from its candidate.
- Validation accepts only `sha512` and a String containing exactly 128
  lowercase hexadecimal characters for a hash expectation. Missing, null,
  nonstring, malformed or unsupported algorithm/digest fields are model
  errors before execution. Unknown or mixed plaintext/hash keys are errors.
  Standalone validate remains read-only.
- A real execution produces the unchanged page-57 output and provenance;
  SHA-512 of those exact bytes equals the fixed expectation. Retain actual
  `output.txt`, expected/observed digests, algorithm, byte policy and match
  Assessment. Hash evaluation does not mutate output or normalize bytes.
- A controlled one-byte output change against the same fixed expectation
  produces a mismatch Assessment. A valid but different saved digest also
  produces a scientific mismatch, not invalid configuration. These controls
  are focused tests; do not modify the tracked known-good experiment.
- Invalid definitions create no Observation or Assessment and retain the
  existing invalid/not_checked attempt where storage permits. Execution
  failures remain error/not_checked, never mismatch or empty-digest matches.
  Interruption stays running; persistence failure is not durable success.
- Hash runs have their own history, despite producing the same bytes as the
  original plaintext page-57 experiment. Unchanged repetition reuses its
  prior LogEntry; intentional rerun requires a reason and links the prior
  attempt. Changed expected digest changes execution identity.
- Historical plaintext records and new hash records round-trip through Store
  without migration. Review reads saved evidence even after the current
  definition changes or disappears. CLI validate/run/review use the new ID
  and clearly distinguish scientific SHA-512 checks from SHA-256 identities.

## Approach

### Definition and model preconditions

Keep schema version 1 and the existing scalar operation. Extend the explicit
supported recipes in `lib/primus/experiment.rb` with one entry; also constrain
expectation kind by recipe. Do not merely whitelist the new ID independently
of page/path/operation or allow either kind for every ID.

| ID | Page/source | Operation | Expectation |
| --- | --- | --- | --- |
| `page-57-latin` | 57, `data/encoded/liber_primus/page_57.yml` | `runes_to_latin` | plaintext |
| `page-56-totient-latin` | 56, `data/encoded/liber_primus/page_56.yml` | `totient_shift_to_latin` | plaintext |
| `page-57-latin-sha512` | 57, `data/encoded/liber_primus/page_57.yml` | `runes_to_latin` | hash |

Keep the existing page-56 parameters exactly as implemented; parameters
remain absent on both page-57 recipes. Preserve title/purpose, input safe
path/digest checks, integer page identity and output-policy validation.
Use kind-specific expectation key allowlists:

| Kind | Required keys | Meaning |
| --- | --- | --- |
| plaintext | `kind`, `path`, `sha256`, `provenance` | Existing file oracle, unchanged |
| hash | `kind`, `algorithm`, `digest`, `provenance` | Inline saved expected digest; algorithm exactly `sha512` |

The output policy is declared once at `output.policy` and copied into hash
assessment evidence. Require nonblank provenance for both. Hash expectations
must not require a dummy path, plaintext file or SHA-256 of a digest string.
Reject plaintext-only keys for hash and hash-only keys for plaintext. A
well-formed wrong digest is deliberately valid: validation cannot compare
it with candidate output, nor recompute it from provenance sources.

Branch file-oracle validation only for plaintext; clear cached expected bytes
on every validation as today. For hash, `expected_bytes`, expectation_path
and expectation_digest are nil. The last remains the SHA-256 identity of a
plaintext oracle, never the scientific SHA-512 digest. Source validation is
unchanged. Keep malformed YAML as LoadError and semantic configuration
failures as ordinary ActiveModel errors with existing stage/type details.

### Independent expected value and exact bytes

Use the already tracked `experiments/expected/page-57-latin.txt` as the
preparation source, independently of Runner/Translator output. Its declared
SHA-256 is `2d450628c6431f9497a6709f5af25d3dad2aa509c31d99ec3a00b07a42eb9a39`.
Cross-check it byte-for-byte against the body of
`data/decoded/liber_primus/page_57.yml` with existing Ruby `rstrip`; that
source's declared SHA-256 is
`960d9e6e20817b4a52d7b24eb7ecf447acfd05d3112f1ed8ca516b2fc3192ad7`.
Reverify both identities during preparation; stop on an unexplained change.
These are repository known-solution sources, not a new image audit.

The bytes are UTF-8 without BOM, with canonical lowercase GP spellings and
existing physical wraps/internal punctuation and spacing. Preserve `lice`,
`unnelng` and `diuinity`. Preserve existing compatibility rendering and
`rstrip` behavior; no terminal whitespace/newline is added. Do not change
Printer, Builder, Translator or source handling. Hash precisely the bytes
retained as output, not JSON, YAML, hex text, a CLI line or a stripped copy.

During implementation, compute the expected SHA-512 independently over that
known plaintext using a separate tool (for example Python hashlib), verify
it with another available SHA-512 implementation and pin the literal result
in the saved definition before invoking Runner. Retain preparation source
paths, both verified SHA-256 identities, exact policy, tool/version and
verification result in the provenance string. The definition snapshot then
preserves this account and the literal expected digest for every attempt.
No additional expected-digest file is necessary. Existing plaintext files
remain untouched and need not be present to execute an otherwise valid hash
experiment; they are preparation provenance, not runtime dependencies.

A focused fixed `abc` SHA-512 known-vector test verifies the evaluator
independently of page fixtures. Its expected value must be a reviewed literal,
not computed by the implementation or the same test's digest call. This
small unit vector does not restore a synthetic research experiment.

### Evaluation and domain interfaces

Keep Experiment as ActiveModel preconditions, Observation as produced bytes
and rune provenance, Assessment as scientific comparison, LogEntry as one
attempt, and Store as history. Preserve Runner's constructor, nil-returning
`run`, `output_path` and readers `observation`, `assessment`, `log_entry`.
Do not introduce a Definition wrapper, result hash or forwarding readers.

**Approved output-bytes contract:** `Observation#output_bytes` always
returns an `ASCII-8BIT` (binary) String, equivalent to applying Ruby's
`String#b` to the supplied output. Observation owns this conversion at
construction, retaining an independent frozen copy as it does today; it
must not retag, freeze or otherwise mutate the caller's String. This is an
encoding-tag change, not transcoding: every byte, length and digest stays
unchanged. The compatibility policy still produces UTF-8 text bytes; their
binary String representation does not change that policy.

Callers, including Evaluator, Store and tests, consume `output_bytes`
directly without appending `.b`. Historical observations hydrated from saved
output follow the same constructor contract. Independently read expected
values should be binary where a test compares exact bytes. Keep any needed
normalization of a caller-supplied plaintext expectation inside the existing
Evaluator byte-comparison boundary, preserving its plaintext-string API.
Do not spread encoding conversions or add forwarding readers to Runner.

Extend `Primus::Experiment::Evaluator#assess` with bounded hash expectation
handling while keeping existing `observation:, expectation:` plaintext-string
calls valid. Add an optional `policy:` keyword for the hash branch; Runner
passes validated expectation mapping and output policy for hash, and existing
expected_bytes for plaintext. Use `Digest::SHA512.hexdigest` from Ruby's
standard library, with explicit sha2 loading as needed. Only the hash branch
calculates an observed digest. No algorithm registry or arbitrary dispatch.

Extend Assessment with optional cohesive hash-check metadata. Serialize it
under an additional `hash_check` key containing exactly `algorithm`, `policy`,
`expected_digest` and `observed_digest`; omit that key for plaintext. Its hash
form retains the existing comparison and actual_length keys. Do not invent a first differing
plaintext byte or expected byte length from a digest: those fields are nil
for hash. Preserve the four existing plaintext keys and their meanings in
`to_h`, and keep historical four-key constructor hydration valid. Use a
focused construction method for hash metadata if needed to avoid expanding
constructor positional/keyword arity; do not add a class per scalar or a
parallel evaluator framework. Hash metadata belongs to Assessment, not
Observation or model validation. Keep new classes noun-named if a concrete
implementation need emerges; no speculative namespace plumbing.

Runner only selects the correct expectation at its existing evaluation call.
Its transformation/provenance path does not change. Ordinary hash computation
exceptions use its existing StandardError recording path, preserving any
Observation already produced and leaving Assessment absent. No new unavailable
status is required: unsupported algorithms are invalid configuration and
runtime failure is error/not_checked. Do not silently fall back to another
algorithm; dependency loading failure must surface as failure, never mismatch.

### Persistence, fingerprint and CLI

Store already serializes configuration, snapshots definition/source/output,
uses Assessment.to_h and hydrates via Assessment.new. Adapt its hydration to
remove `hash_check` before passing the existing four fields to the historical
constructor and restore that metadata through the focused Assessment
construction API. An absent hash_check means the existing plaintext shape;
do not blindly forward the new nested key into today's four-key constructor. Preserve record schema 1 and old histories without rewriting them.
For hash, existing oracle_path/oracle_declared_sha256/oracle_actual_sha256
fields stay nil and `expected.txt` is absent. Expected digest and provenance
are retained in configuration/definition, and observed scientific evidence
in Assessment. Artifact manifests continue SHA-256 byte identities.

Runner's current fingerprint includes sorted parsed definition, source SHA-256,
oracle SHA-256, Git HEAD, Ruby version and version 1. The entire hash
expectation and output policy already participate via definition; keep this
identity algorithm/version and plaintext behavior unchanged. Hash's oracle
SHA-256 is nil. Store scopes lookup by ID, and the ID also enters definition
identity. Do not collapse records on equal output, input, operation or observed
digest. YAML formatting-only changes still reuse; changed digest/provenance
or other parsed configuration changes invalidate reuse.

`lib/primus/commands/experiments.rb` already resolves ID to
`experiments/definitions/<ID>.yml` and enforces filename/declaration agreement;
its ID regex admits the new ID. No new route, option or bin/primus edit.
Update validate display for hash to label algorithm, fixed expected digest
and output policy, avoiding an empty misleading oracle-SHA256 line. Review
uses saved configuration/assessment, displays expected/observed digest,
algorithm/policy and comparison for hash, and preserves old plaintext display.
A planned hash definition has no observed digest. Existing run exit/status
semantics remain; no UI redesign. Add concise README ID-based examples in
the later implementation, including review and intentional rerun.

### Focused test mapping and later verification

| Test home | New evidence |
| --- | --- |
| `spec/lib/primus/experiment_spec.rb` | Valid hash definition without oracle file; exact ID/page/path/operation/kind pairing; malformed/unknown/mixed algorithm and digest fields; plaintext rules unchanged |
| `spec/lib/primus/experiment/observation_spec.rb` | Binary output contract with non-ASCII UTF-8 input; exact bytes preserved; input unchanged and independently owned frozen output. Test this responsibility here, not through nested Runner access. |
| `spec/lib/primus/experiment/evaluator_spec.rb` | Independently fixed SHA-512 vector; exact match; one-byte/trailing-LF mismatch; no normalization or output mutation; scientific metadata |
| Assessment spec under full namespace | Hash evidence serialization and compatibility with historical plaintext shape, only where not already covered by Store integration |
| `spec/lib/primus/experiment/runner_spec.rb` | Hash expectation handoff and error/not_checked behavior with produced Observation retained; invalid config suppresses transformation |
| `spec/lib/primus/experiment/store_spec.rb` | Hash Assessment round-trip; pre-extension plaintext record hydration; saved evidence after definition changes/removal |
| New `spec/features/run_page_57_hash_experiment_spec.rb` | Tracked independent digest match; exact unchanged output/provenance; saved digest/bytes evidence; distinct plaintext/hash histories despite equal bytes |
| Focused identity feature coverage | Digest change creates new attempt; unchanged definition reuses; explicit rerun retains reason/prior link; YAML-only edit retains reuse |
| `spec/lib/primus/commands/experiments_spec.rb` | New ID validate/run/review; digest/policy labels and no observed value for planned/invalid attempts; ID mismatch/path safety regressions |

Remove caller-side `output_bytes.b` from the current hash specs during the
next test revision; compare the public byte contract directly. Keep existing
plaintext and archived-output regressions to catch encoding incompatibility.

Keep one behavior per example. Cohesive digest evidence can be asserted
together; do not bundle unrelated validity, exit codes, prose errors, counts
and output into tuples. Custom integrity/configuration tests assert validity
against a valid fixture; standard validations may use supported Shoulda
matchers. Avoid English ActiveModel error-message coupling. Use full
namespaces and existing domain readers; serialized-hash inspection belongs
at persistence boundaries. No tests in bin files and no test-driven method
splitting merely to satisfy a five-line heuristic.

Later run focused additions and existing page-56/page-57/evaluator/store/CLI
regressions, then the full suite and required project lint in configured Ruby
2.7.4 with the resolved bundle. End-to-end/identity specs execute committed
HEAD and enforce clean executable paths: establish an intentional WIP
implementation snapshot before genuine clone-based validation. Do not weaken
the clean-code check or mistake DirtyCode for a useful hash-feature red.
Only after independently pinning/reviewing the digest, validate/run/review
the saved control and inspect retained bytes/Assessment; do not run or create
that experiment during this planning pass.

## Edge cases

Empty bytes remain hashable in focused evaluator tests even though the saved
recipe requires a rune-containing page. Non-ASCII UTF-8 and CRLF/LF/trailing
whitespace are exact bytes, not normalization opportunities. Hash mismatch
has no first-difference offset. Nil/uppercase/whitespace-padded digest values
are invalid, not normalized into a different declaration. Reset cached model
bytes and Runner readers on revalidation/reuse as today. Missing saved output
must still be reported by existing artifact review; saved digest evidence is
not a claim that every archive artifact is available or re-audited. Existing
single-process, mutable configuration and nontransactional storage limits
remain unchanged; no unrelated hardening bundle.

## Out of scope

Artificial research input; two-cipher chains; general registries/adapters;
BLAKE variants or new dependencies; alternative output normalization; target
interpretation or page-55 execution; experiment generation/search; rewriting
old IDs or histories; broad refactoring; merge, push or PR creation here.

## Open questions

No blocking product choice remains. This plan recommends the inline digest,
`page-57-latin-sha512` ID and unchanged compatibility byte policy. The literal
digest and preparation tool/version evidence must be established during
implementation before execution; they are not invented placeholders in a
production definition. If independent source checks disagree, resolve the
oracle discrepancy before running rather than modifying candidate rendering.

After this control is implemented and integrated, plan page-55 target-hash
experiments separately. Declare algorithm/serialization/target interpretation
as hypotheses; a mismatch rejects only the tested combination. A 128-character
hex value alone identifies neither SHA-512 nor the bytes historically hashed.
