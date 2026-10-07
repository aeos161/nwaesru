# Phase 6 — Original BLAKE-512 in Primus

## Goal

Include blake512-ruby in the existing Primus Gemfile, verify the bundle and
native load, and deliver a page-57 original-BLAKE-512 control with an independent
oracle. Phase 5 CI, platform expansion, sanitizers and release delivery are
deferred and do not block this increment.

## Baseline and dependency decision

Reconciled from clean Primus branch `codex/primus-blake512-integration` at
`9251083`. Public HTTPS `git ls-remote` verified gem main at
`36dfec39eac5401548676c35190ab72c559a5e8c` on 2026-10-06, matching the reviewed
Phase 4 revision. Phase 4 supplies digest/hexdigest, immutable build_info,
stale-source checks and source-gem installation. Its reported 116 passing
examples on MRI 2.7.4/macOS arm64 were not rerun during planning. Primus Git
bundle/native installation remains to verify. No prerequisite refactor is
indicated.

Add directly to the existing Gemfile:

```ruby
gem "blake512-ruby", "= 0.1.0",
    git: "https://github.com/aeos161/blake512-ruby.git",
    ref: "36dfec39eac5401548676c35190ab72c559a5e8c", require: false
```

Update tracked Gemfile.lock narrowly with this HTTPS remote and exact revision.
Do not introduce a research Gemfile or change primus.gemspec for distribution.
No sibling checkout, local path override or RubyGems publication is required.
Lazy require does not make dependency resolution optional: unresolved Git
installation remains a Bundler setup failure before CLI startup. Source is
pinned; save actual source/native identity per run because local build artifacts
can differ. Advancing the pin requires deliberate review and a lockfile update.
The [Bundler Git guide](https://guides.rubygems.org/git/) documents HTTPS Git
sources and explicit refs; native installation is an empirical gate below.

## Acceptance criteria

- MRI 2.7.4 with the existing Bundler resolves the pinned public HTTPS Git
  dependency and builds its native extension during `bundle install` into a
  fresh isolated bundle, without a sibling checkout, local override or manual
  compile. Gemfile.lock records the reviewed revision. A fresh Primus process
  loads `aeos/blake512`, verifies the literal abc vector and reports schema-1
  build_info for that Bundler-installed artifact.
- Accept ID `page-57-latin-blake512`, algorithm `blake512`, existing page-57
  recipe and `gp-latin-compatibility-v1` policy. Reject wrong recipe/algorithm,
  malformed digest and unknown fields under existing validation rules.
- Hash exact owned frozen `Observation#output_bytes`, without conversion,
  mutation or newline addition. Preserve the four existing hash_check fields:
  algorithm, policy, expected_digest and observed_digest.
- The new control matches a separately prepared 124-byte page-57 oracle fixed
  before Runner execution, not copied from the candidate gem or Runner output.
- Expected load/build-identity failure becomes backend Unavailable and a saved
  error/not_checked attempt retaining Observation; never mismatch. Unrelated
  exceptions are not broadly translated.
- Source/version/native changes and restored availability change fingerprint;
  diagnostic-only path/compiler changes do not. Existing controls, fingerprint
  semantics and saved-history review remain compatible.

## Approach

### 1. Verify dependency and native setup

From Primus, use the selected MRI 2.7.4 and existing Bundler version. Run
`bundle install` and `bundle check`; additionally prove installation in a fresh,
disposable bundle location with no inherited local gem override or cached
native artifact. Bundler must fetch the pinned HTTPS source and build the
registered extension from its gemspec. Record the Ruby/Bundler versions,
resolved revision and installation evidence. Do not substitute a sibling
checkout's compile task, prebuilt library or load path for this acceptance gate.
Stop and report an installation failure before claiming integration success.

From that bundle execute a fresh `bundle exec ruby` process requiring
`aeos/blake512`, hashing abc and printing build_info. Compare against the literal
abc vector in verified fixtures; confirm gem version, source identity and
native_path belong to the Bundler-installed Git dependency. This is a real
installation/load gate, not merely `bundle check`.

Deliver Gemfile/lock and README setup instructions: Git/HTTPS access for initial
fetch, compiler, make and headers matching the selected Ruby. Document a tested
Bundler reinstall/rebuild procedure for a missing/stale native artifact, using
a fresh process afterward. No runtime compilation or downloads are introduced.
Dependency or build failures remain actionable Bundler setup failures before
application boot, not experiment records. Avoid unrelated dependency upgrades.
No need to rerun the whole gem suite for Primus-only edits.

### 2. Prepare the independent expectation

Verify `experiments/expected/page-57-latin.txt` is 124 bytes with SHA-256
`2d450628c6431f9497a6709f5af25d3dad2aa509c31d99ec3a00b07a42eb9a39`, equal to
the established decoded-page body, with no BOM/final newline. Retain lowercase
GP spellings, wraps, punctuation and spacing under the existing byte policy.

Use the Phase 2 vetted @noble/hashes BLAKE1 blake512 1.8.0 at revision
`32f700f38ec49d7e6b2ab687904d6b2d7d60d80a`, following gem VECTORS.md. Verify
its recorded tarball/source checksums and known answers before deriving this
page digest. Preserve literal expectation and runtime/tool/source/input hashes
in definition provenance or a focused evidence note before first Runner use.
Only then cross-check with the candidate gem; same-C CLI and Ruby are not
independent algorithm oracles. Stop on disagreement. No Node runtime dependency
is added to Primus.

Add `experiments/definitions/page-57-latin-blake512.yml` and
`spec/fixtures/experiments/page_57_blake512_valid.yml`, patterned on BLAKE2b.
Keep existing source SHA/policy and distinguish original BLAKE from BLAKE2b.

### 3. Add the narrow backend and dispatch

Add `lib/primus/experiment/blake512.rb` with hexdigest(bytes), runtime and
`Unavailable < StandardError`. Load this wrapper from `lib/primus.rb`; require
the gem lazily inside it. Translate expected `::LoadError`, including
Aeos::Blake512::BuildMismatch, at this boundary. Preserve cause/class for
useful rebuild guidance; do not rescue arbitrary StandardError/TypeError or
RuntimeError. Unsupported descriptor schema is explicit unavailability, not
guessed provenance. Do not mutate the gem's deeply frozen build_info.

Extend Experiment RECIPES/HASH_ALGORITHMS and evaluator's explicit algorithm
case. Observation already owns frozen binary bytes and needs no change.
Add new typed error to CLI rescue. Replace digest_label's current non-SHA
BLAKE2b fallback with explicit labels for the three supported algorithms.
Do not add a registry or redesign the CLI.

Runner obtains runtime before execution. The new runtime method returns
available:false on expected load failure, allowing reservation and observation
production; hexdigest then raises Unavailable, and existing Runner rescue
records error/not_checked with Observation. Validation and saved review remain
lazy when a resolved bundle has an unusable native artifact. Do not promise
CLI boot when the mandatory Git dependency cannot resolve.

### 4. Preserve provenance and project stable fingerprint fields

Extend Runner's runtime selection only for this new ID. Use existing Store
hash_runtime support to retain backend `blake512-ruby`, available Boolean and
successful build_info: schema_version, algorithm, gem_version,
upstream_revision, source_sha256, native_sha256, ruby_engine, ruby_api_version,
ruby_platform, dlext, compiler, compile_flags and native_path. Failed loading
records backend, availability, resolved gem version when obtainable and error
class/message. Do not invent hashes for an unloaded backend.

For the new ID only, fingerprint backend, availability, schema_version,
algorithm, gem_version, upstream_revision, source_sha256, native_sha256,
ruby_engine, ruby_api_version, ruby_platform and dlext. Exclude native_path,
compiler, compile_flags and error prose, retaining them as saved diagnostics.
For unavailable state use its deterministic known subset and error class;
restored availability always changes identity. Indistinguishable unavailable
attempts may deduplicate: no identity claim is made for an artifact that did
not load.

Keep BLAKE2b's existing full-runtime fingerprint and all other identity inputs
unchanged. No global fingerprint schema migration. Definition identity already
includes expected digest/provenance. Gem source_sha256 includes its manifest
and declared inputs; Primus CODE_PATHS cannot cover the external gem source.
Source/native validation is a per-process load snapshot, not live monitoring.
Store/read schemas should need no change beyond focused regression proof.

## Test-writer handoff and validation

The user has authorized the test-writer handoff after this reconciliation.
Add focused specs with full namespace paths:
`spec/lib/primus/experiment/blake512_spec.rb`, evaluator/runner/store specs under
that namespace, `spec/lib/primus/experiment_spec.rb`, and commands specs under
`spec/lib/primus/commands/`. Do not relocate unrelated older specs for naming.
One outer describe per class with method groups; one behavior/expect per
example, explicit setup, no let/let!, unrelated tuples, deep Demeter chains or
error-prose coupling. Five-line methods are a readability heuristic.

Cover real-gem known answers/binary inputs, descriptor/error translation,
validation matrix, preserved bytes/hash fields, match/mismatch, retained
Observation on failure, restored/changed backend deduplication and stable
fingerprints across diagnostic-only changes. Pin existing fingerprint/history
behavior with focused regressions. Use disposable subprocess fixtures or
narrow wrapper failure doubles for missing/stale native code; never damage the
shared gem checkout. Run relevant tests and full Primus suite once settled.

From Primus root verify the real CLI:

- `bin/primus experiments validate page-57-latin-blake512`
- `bin/primus experiments run page-57-latin-blake512`
- `bin/primus experiments review page-57-latin-blake512`

Automated runs use test-owned output directories. The real Runner requires
clean executable paths: record the real run after implementation's authorized
WIP commit rather than bypassing the guard. Confirm matched, 124 output bytes,
four hash-check fields and runtime identity. Validate/run existing SHA-512 and
BLAKE2b controls without overwriting history. Stop after integration; no search
campaign follows automatically.

## Edge cases and open questions

The HTTPS revision is verified and pinned; version 0.1.0 alone would not pin
source. A clean Git install must prove native compilation with the existing
Ruby/Bundler combination. BuildMismatch is a LoadError subclass
and must be translated before Runner's StandardError handling. Bundler failures
precede experiment execution. No blocking decisions remain; successful bundle/
load and the independent page digest are implementation gates, not outcomes
established during planning.

## Out of scope

Phase 5 CI/platform expansion, sanitizers and release packaging/publication
are deferred. No gem source edits, generic backend framework, extra algorithms,
optional research bundle, distributed Primus packaging redesign, runtime
upgrade, search, push or merge. This task changes plans only; no implementation
starts here; the authorized test-writer handoff follows this plan commit.
