# Page 57 control with BLAKE2b-512

## Goal

Add one saved page-57 BLAKE2b-512 control over the same independent known
plaintext and exact output bytes as the existing SHA-512 control. Use the
project's existing OpenSSL support and retain a separate history with explicit
expected/observed digest evidence.

The user selected BLAKE2b first. Original BLAKE-512 is deferred to a fresh
plan and dependency review; it is not a prerequisite or acceptance criterion
for this delivery. This supersedes the combined proposal in
[page-57-blake-controls.md](page-57-blake-controls.md).

## Baseline and planning boundary

Inspected 2026-10-05: clean `feature/page-57-blake-controls` at `8724e8b`,
whose only changes from `main`/`origin/main` at `098c0da` were plan documents.
Reuse this branch for the narrowed plan. The SHA-512 implementation is
present at `098c0da`; no implementation has begun for either BLAKE algorithm.
The previous suite report was 453 examples, zero failures, 12 pending; this
planning pass did not rerun it.

Only `docs/plans/` changes now. No source/tests, installations, builds,
oracle generation, experiment execution or next-agent invocation before plan
review. No preparatory refactor is needed: the current domain boundaries
support this localized extension. Existing long methods and the five-line
heuristic do not justify a general Experiment/Store cleanup.

## Algorithm and dependency decision

The sole new identifier is `blake2b512`: sequential BLAKE2b with 64-byte
output, no key, zero salt/personalization and default tree parameters. This
is distinct from original BLAKE-512. Accept no algorithm aliases or optional
key/salt/output-length parameters. See the
[BLAKE2 specification](https://www.rfc-editor.org/rfc/rfc7693.html) and
[OpenSSL 1.1.1 digest documentation](https://docs.openssl.org/1.1.1/man3/EVP_blake2b512/).

Use `OpenSSL::Digest.new("BLAKE2b512")` through the already available Ruby
binding. Prior read-only probing of the actual project executable verified:

- Ruby 2.7.4p191, arm64-darwin21, as specified by `.tool-versions`.
- ruby-openssl 2.1.2, built/linked OpenSSL 1.1.1w.
- BLAKE2b512 construction succeeds and reports a 64-byte digest.

That executable is
`/Users/chriswoodford/.asdf/installs/ruby/2.7.4/bin/ruby`; the tool shell's
`/usr/bin/ruby` and standalone `openssl` executable are not evidence about
project support. Subsequent verification uses project Ruby and its bundle.
Capability is verified; cryptographic vectors have not yet been run.

No new crypto gem, C extension, compiler task, vendored source, packaging
change or runtime upgrade is proposed. Other Ruby/OpenSSL builds may lack
this digest; report that honestly as an unavailable execution backend.

## Acceptance criteria

- Add `experiments/definitions/page-57-latin-blake2b512.yml` with the matching
  ID, page 57 and its existing source, `runes_to_latin`, no parameters, and
  `gp-latin-compatibility-v1`. Preserve all three existing definitions.
- Keep schema 1. The new expectation contains exactly `kind`, `algorithm`,
  `digest`, `provenance`, with kind `hash`, algorithm `blake2b512`, nonblank
  provenance, and a String digest of exactly 128 lowercase hexadecimal
  characters. The SHA-512 ID remains bound to `sha512`; plaintext IDs retain
  plaintext expectations. Reject ID/algorithm swaps, aliases, unsupported
  algorithms, malformed/missing fields, mixed expectation keys, changed
  recipe coordinates and extra parameters as model validation errors.
- Validation is read-only and does not hash, generate expectations or require
  OpenSSL capability. A well-formed incorrect digest is valid configuration
  and becomes a scientific mismatch only after computation.
- Verify the backend against independently published unkeyed BLAKE2b-512
  empty-input and multi-block vectors. Pin literal expected values from the
  source; never compute expectations with the implementation under test.
- Prepare the fixed page-57 digest independently from known plaintext before
  the first Runner execution. Record source identities, byte policy,
  preparation tools/versions and verification result in provenance. Runner
  never creates, updates or repairs its expected digest.
- The real control matches and retains the same 124 output bytes and rune
  provenance as current page 57. Hash Observation's exact owned frozen
  binary String directly. Do not normalize whitespace, transcode, mutate the
  caller's String, add newlines, or hash a rendered CLI/JSON/hex form.
- A changed output byte or valid changed expectation produces mismatch.
  Assessment preserves the existing four `hash_check` keys: `algorithm`,
  `policy`, `expected_digest`, `observed_digest`. Hash expected-length and
  first-difference fields remain nil; actual length is the input byte count.
- Save output/provenance artifacts and definition snapshot; omit dummy
  expected plaintext artifacts. Existing oracle SHA-256 fields stay nil for
  hash runs; source/artifact SHA-256 identities remain unchanged in meaning.
- Missing OpenSSL binding/digest is an explicit `error`/`not_checked`, never
  mismatch or fallback to SHA-512. Preserve any produced Observation; leave
  Assessment absent. Report the selected algorithm and underlying cause.
- All four experiment histories remain separate. Unchanged repetitions reuse
  the existing attempt; intentional reruns require a reason and link the
  prior attempt. Changed expectation or BLAKE2b backend identity creates a
  distinct fingerprint; restored capability does not reuse an unavailable
  error as though the new backend executed.
- Historical plaintext/SHA-512 records and their fingerprints remain
  compatible. Review uses saved evidence without current definition or
  OpenSSL support. Existing CLI ID commands, ActiveModel ownership, Runner's
  nil-returning run command/readers and Observation's binary contract remain.

## Approach

### Definition and evaluation

Extend `lib/primus/experiment.rb`'s explicit recipes with the one ID.
Use a small explicit ID-to-hash-algorithm lookup for the two hash recipes,
retaining exact page/path/operation constraints and existing source/path
integrity checks. Keep parameters absent for every page-57 recipe. Do not
turn the lookup into registration, arbitrary constant dispatch or support for
other algorithms on any ID.

`Primus::Experiment::Evaluator` retains comparison ownership and its
plaintext-string API. Select the existing standard-library SHA-512 path or
the new OpenSSL BLAKE2b path explicitly. Use a fresh digest per computation;
no reusable global hasher or new inheritance/adapter framework. A small
noun-named `Primus::Experiment::Blake2b` collaborator is justified only to
own the OpenSSL dependency boundary and its runtime descriptor. Keep
Assessment, Observation, LogEntry and Store in their current roles; no
Definition wrapper, result hash or forwarding readers on Runner.

Lazy-load OpenSSL when probing/executing BLAKE2b, not from global application
boot. Catch `LoadError` explicitly at that boundary (it is not a
StandardError); translate load and digest-capability failure into a focused
StandardError subtype with algorithm/cause. Runner's existing failure path
then records error/not_checked and preserves produced output. Other
computation failures remain execution errors, not unavailability or mismatch.
CLI translates the focused exception to its usual command error. Unsupported
algorithm selection must not default to SHA-512, even in direct evaluator
calls; model validation remains the normal entrypoint precondition.

### Persistence and execution identity

Assessment/Store already round-trip the four-key hash evidence; do not alter
that shape or add an unnecessary scientific record schema. Review prints the
saved algorithm/digests through existing CLI rendering.

For the new BLAKE2b ID only, save an optional top-level `hash_runtime` mapping
containing `openssl_binding_version`, `openssl_build_version`,
`openssl_library_version`, and `available`. The version fields are strings
or nil when unavailable; availability is a boolean determined by constructing
the exact digest, without hashing candidate bytes. Keep variable error text
out of identity; the actual failure message belongs to execution errors.

Include this same mapping in the BLAKE2b execution fingerprint. Probe once
per run; a failed capability probe returns its unavailable descriptor rather
than escaping before reservation. Normal execution still produces its
Observation and invokes the backend so the existing failure-recording path
retains output and records the cause. Versions distinguish linked-library
changes, and availability distinguishes restored support. Do not probe or
add fields to SHA-512/plaintext fingerprints. Historical records omit the
mapping and require no rewrite. Reuse lookup remains scoped by experiment ID.

Likely source files: experiment validation, evaluator, the focused Blake2b
dependency boundary, its Ruby loader, Runner/Store runtime metadata, and CLI
error presentation only if needed. Add one real definition, a small vector
fixture/provenance note, focused specs and README usage. No gemspec,
Gemfile.lock, build configuration, native-source or CODE_PATHS changes are
needed for this scope. Printer, Builder, Translator, page-56 transformation
and known source/oracle files remain as-is.

### Independent oracle and fixed vectors

Prepare from `experiments/expected/page-57-latin.txt`, SHA-256
`2d450628c6431f9497a6709f5af25d3dad2aa509c31d99ec3a00b07a42eb9a39`.
Cross-check byte-for-byte against the rstrip body of decoded page-57 YAML,
whose source SHA-256 is
`960d9e6e20817b4a52d7b24eb7ecf447acfd05d3112f1ed8ca516b2fc3192ad7`.
Reverify identities and stop on an unexplained change. Preserve lowercase GP
spellings, existing wraps/punctuation/internal spacing, no BOM and no final
newline. The resulting 124 bytes remain independent of Runner output.

During implementation, compute using Python `hashlib.blake2b` explicitly
requesting 64-byte output and unkeyed defaults, then cross-check via the
available project's OpenSSL over the same known-text file outside the
candidate path. Record Python/OpenSSL versions and the independent
preparation method honestly; two invocations of the Ruby candidate evaluator
are not independent verification. Pin the literal digest and provenance in
the tracked definition before Runner's first execution. Known-text sources
are preparation provenance, not hash execution dependencies.

For algorithm correctness, use a small cited subset of the official
[BLAKE2 known-answer corpus](https://github.com/BLAKE2/BLAKE2/blob/master/testvectors/blake2-kat.json):
`hash=blake2b`, empty key, 64-byte output, input lengths 0 and 255. The latter
uses byte values 0 through 254 and crosses the 128-byte block boundary;
it also covers embedded NUL/high bytes. Preserve exact vector input bytes,
literal expected digests and upstream revision/source identity in the
fixture provenance. No runtime downloads and no expectation computed by
OpenSSL inside the tests. Additional native-padding tests from the combined
proposal are not part of this milestone.

### Focused test mapping

| Boundary | Behavior to verify |
| --- | --- |
| Feature/current CLI entrypoint | Real BLAKE2b definition matches; exact page bytes/artifact; ID selection and saved review independent of current definition/backend |
| Experiment validation | New valid combination, ID/algorithm swaps, malformed/unknown fields and no parameters; existing fixtures remain valid; capability does not affect configuration validity |
| Evaluator/dependency boundary | Independent empty and 255-byte vectors; one-byte/newline sensitivity; no mutation/state leakage; unsupported name and unavailable backend errors |
| Runner/Store integration | Literal saved BLAKE2b evidence/runtime metadata; error/not_checked with output; separate histories, reuse/rerun reason, changed expectation and restored-support fingerprints; old records load |

Use outside-in tests, fully qualified constants, one expectation/behavior per
example, blank phase separation, no let/let!, and existing fixture/temp-dir
patterns. Do not add FactoryBot, thin-wrapper unit tests or bin-level tests.
Avoid repeating all SHA-512 lifecycle scenarios; pin new behavior where it
varies. Keep meaningful ownership and Law of Demeter; five-line methods are
a heuristic, not a reason to scatter forwarding methods.

After plan review, establish relevant failing tests, implement, run focused
specs and applicable style checks, then the full suite under project Ruby
2.7.4. The supported runtime must actually pass OpenSSL vectors; do not skip
or mark them pending. Production experiment execution follows the existing
clean committed-code requirement, with its expectation already fixed.

## Edge cases

Empty bytes are valid, not absent. Binary/NUL/high-byte input is not text to
repair. Hash exactly the saved bytes, including deliberate terminal-newline
variants in tests. Repeated calls and intervening SHA-512 evaluation must
not share digest state.

An unavailable OpenSSL backend must not prevent application boot, plaintext
or SHA-512 controls, configuration validation or saved review. An unsupported
name is different from a supported-but-unavailable backend. Persistence
failure is not durable success; preserve current interruption/error behavior.
Do not accept keyed, salted or shortened digests because a library offers
such options.

## Out of scope

Original BLAKE-512 and its dependencies, native bindings/builds/packaging,
BLAKE3/BLAKE2s/parallel or extendable-output variants, arbitrary parameter
selection, new serialization policies, page-55/page-56 target-hash runs,
search campaigns, general algorithm frameworks, broad refactors, runtime
upgrades, push, merge and PR creation.

## Open questions

No unresolved algorithm or dependency choice blocks this focused plan:
reuse existing OpenSSL BLAKE2b512. Literal page-57 digest, vector source
revision and preparation tool versions remain evidence to prepare after
review, not values fabricated in planning. Original BLAKE-512 requires a
fresh planner invocation and dependency review later; its earlier native
proposal is not approved or required by this plan.
