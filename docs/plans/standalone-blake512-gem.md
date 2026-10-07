# Standalone original BLAKE-512 Ruby gem

## Goal

Deliver an independently usable MRI gem wrapping the designer's final original
BLAKE-512 C reference, with byte-exact results, traceable native identity and a
tested source-gem installation. Deliver it incrementally: a private/local gem
is a complete milestone; Primus consumption is a final separate increment and
public publication is optional.

Baseline verified 2026-10-06: clean `feature/original-blake512-ruby` at
`399b5a3`, atop main/origin/main `6dcf1df`. This continues the
[original investigation](original-blake512-ruby.md), superseding its proposed
inline Primus extension. Algorithm research and evidence limits remain useful.
No prerequisite refactor is indicated by the existing evaluator, backend,
Observation and saved-runtime boundaries. This task changes plans only.
Naming reconciliation started from clean planning commit `0ea9815`; the
existing gem repository state is recorded in Phase 1 below.

## Current sequencing

Phase 4 is complete in the gem at `36dfec3`. Phase 5 is deferred by the user
and does not block Primus use. The next increment follows the actionable
[Primus integration plan](primus-blake512-integration.md), using the existing
Gemfile and public HTTPS Git dependency pinned to reviewed revision
`36dfec39eac5401548676c35190ab72c559a5e8c` (remote main verified 2026-10-06).
It supersedes both the sibling-path setup and optional research-Gemfile
proposal, plus the Phase 5 dependency in the original roadmap.

## Acceptance criteria

- An independent gem implements final December-2010, 16-round, unsalted,
  unkeyed BLAKE-512. It has no Primus, Rails, OpenSSL, FFI or executable runtime
  dependency and never silently substitutes BLAKE2, BLAKE3 or older BLAKE-64.
- `Aeos::Blake512.digest(bytes)` returns a fresh 64-byte ASCII-8BIT
  String; `.hexdigest(bytes)` returns exactly 128 lowercase ASCII hex
  characters. Accept String and subclasses; reject other objects with
  TypeError, without implicit `to_s` or `to_str` conversion.
- Hash exact bytes, including NUL, high bytes and invalid text encodings,
  without normalization, newline addition, caller mutation or shared mutable
  state. Frozen input and repeated independent calls work.
- Literal independent vectors cover empty, `abc`, 110/111/112 and 127/128/129
  bytes, multi-block binary input, and upstream self-tests. Every fixture
  identifies exact input bytes and provenance; expectations never come from
  the candidate implementation alone.
- Clean checkout build and isolated installed-gem smoke tests pass on existing
  MRI 2.7.4/macOS arm64 before claiming support. Other support claims require
  their own passing evidence.
- Installation fails on required build failure. Missing/unloadable native code
  fails explicitly; hashing never compiles, downloads or falls back.
- Consumers can identify the gem, source and actually loaded native build.
  Stale source/native combinations are rejected.
- Later Primus integration preserves the binary Observation contract, existing
  SHA-512/BLAKE2b behavior and readable saved experiment histories.

## Approach

### Phase 1 — Project identity and independent skeleton

Dependencies: none. Identity is settled: gem/repository `blake512-ruby`,
require `aeos/blake512`, namespace `Aeos::Blake512`, and public methods
`.digest(bytes)` / `.hexdigest(bytes)`. Do not use a personal-name namespace.
Use the existing repository at
`/Users/chriswoodford/Workspaces/chriswoodford/blake512-ruby`; do not create
another repository. Its configured origin is
`git@github-aeos:aeos161/blake512-ruby.git`. This records local configuration,
not a remote-access or registry-availability check.

Read-only inspection found clean `main` at `04a316f` (Initial Commit), with a
Bundler-generated skeleton: gemspec/Gemfile/Rakefile, README, LICENSE.txt,
CHANGELOG, RSpec, RBS, bin scripts and CircleCI. The generated namespace is
still `Blake512::Ruby`, with `lib/blake512/ruby.rb` and version `0.1.0`.
Its spec includes an intentionally failing placeholder. No native extension
exists. No AGENTS.md or CLAUDE.md was found in the destination repository.

The next increment is to reconcile this skeleton, not generate it again.
Carry over this plan and applicable workflow conventions when implementation
starts. Move the entrypoint/version to `lib/aeos/blake512.rb` and
`lib/aeos/blake512/version.rb`; update the existing `blake512-ruby.gemspec`,
spec helper, console, README and RBS references consistently. Use
`spec/lib/aeos/blake512_spec.rb` and `sig/aeos/blake512.rbs` for the full
namespace. Replace the generated placeholder spec with meaningful skeleton
contract coverage through the test-writer/implementer workflow. No legacy
namespace alias is needed for this unimplemented skeleton.

Retain the initial `0.1.0` version. MIT for new binding code remains a proposal
requiring confirmation; the existing LICENSE.txt and gemspec already say MIT,
but generated files alone do not settle that decision. Retain CC0-1.0 for
upstream source. Replace generated gemspec/README metadata placeholders with
verified project information and clarify local installation versus optional
publication. The existing Bundler release task can push and publish: it is
not part of routine validation or authorized by this plan.

Reserve `ext/aeos_blake512/` for extconf, binding, source and notices, with a
private native load target under `aeos/blake512/`. Explicitly inventory packaged
files and select development tools that resolve on MRI 2.7.4; do not copy Rails
dependencies from Primus. Existing gemspec Ruby `>= 2.6.0` and CircleCI Ruby
3.1.3 settings are scaffold defaults, not evidence of supported platforms.

Acceptance/stopping point: the existing skeleton consistently uses the settled
gem name, require path and namespace, with reviewed API/support/build contract,
no metadata placeholders, no fake digest and no Primus fixture dependency.
Account for native source/header/notices and extension registration as native
files arrive in Phases 2–3; do not claim a working extension in this increment.
Handoff: after skeleton reconciliation, Phase 2 establishes source and fixtures;
public digest behavior tests start once those fixtures are trustworthy.

### Phase 2 — Source provenance and independent correctness fixtures

Dependencies: Phase 1 layout; research can be prepared independently. Fetch and
verify the compact designer implementation at candidate revision
`65f9ac8101191b12368e533afed6486c5b694fa3`. Record immutable URL/revision,
original SHA-256 per imported file, license and notices in `UPSTREAM.md`.
Preserve an auditable snapshot and document each local patch. Exclude CLI/main
from the extension; keep upstream self-tests as test evidence. Avoid duplicate
header definitions and exported symbol collisions. Do not rewrite the
compression, counter or padding implementation for style.

Build a fixture manifest with literal digest, exact input hex or deterministic
byte construction, provenance and verification method. Establish final-round
published known answers first. Then cross-check boundary/binary fixtures using
a separately implemented backend pinned to a reviewed revision, such as
noble-hashes BLAKE1. Distinguish published vectors from independently generated
fixtures. The same C source via CLI and Ruby tests the binding, not independent
algorithm correctness. The designer warns that the separate NIST-API reference
needed a 2015 correction; an unvetted old copy is not a trustworthy oracle.
No JavaScript production dependency is proposed.

Acceptance/stopping point: vetted source/license manifest, minimal patch plan
and trustworthy fixture corpus ready for test-writer. Stop on discrepancies.
Exact source checksums and independent oracle revision remain deliverables,
not invented values or user clarification questions.

### Phase 3 — Minimal native byte API

Dependencies: Phases 1–2. Test-writer writes failing public API examples;
implementer supplies the small C binding, mkmf extconf, loader and extension
registration. Use Ruby build configuration rather than hard-coded library
suffixes/compiler paths. Derive hexdigest from binary digest with standard
Ruby hex encoding; keep only the two hashing operations in the initial API.

Review Ruby/C type and byte-length conversion, pointer lifetime, bounds,
counter arithmetic and output ownership. Never use strlen or narrow to int.
Audit the pinned upstream update function's own limits; validate conversion
or chunk safely rather than trusting the outer signature alone. Use fresh
state and fixed-size output per call. Hold the GVL initially; no Ruby callbacks
or allocations while retaining raw input pointers. Copy completed output into
Ruby ownership and retain no caller buffer after return.

Acceptance/stopping point: both methods pass literal vectors; separate examples
establish output size/encoding, lowercase hex, NUL/high bytes, frozen input,
encoding independence, unchanged caller bytes, rejected types and independent
interleaved/repeated calls. Include a practical large multi-block input;
inspect unreachable length limits without enormous allocations. Deliver a
working checkout build; packaging is still the next gate.

### Phase 4 — Reproducible build, identity and packaged installation

Dependencies: Phase 3. Document compile, clean, rebuild and spec tasks; ignore
objects, Makefiles, bundles and generated metadata. A path dependency or
`bundle exec` alone is not proof that native files were rebuilt. Verify the
resolved native path and keep load paths namespaced.

Provide read-only build metadata (proposed `.build_info`, separate from hashing):
algorithm, gem/binding version, upstream revision, source/build-input digests,
Ruby ABI/platform and compiler/flags. Embed source/build-input identity during
compilation and compare with the packaged or checkout source manifest at load.
Generate metadata without Git or network requirements in an installed gem.
Expose the actually loaded library identity and SHA-256; absolute paths are
diagnostic, not intrinsically portable fingerprint fields. Edited source with
an old binary must raise a focused load error with rebuild guidance, resolved
by a clean rebuild. Include Ruby binding/build inputs in stale checks.

Build a source `.gem`, inspect its file list, install into a disposable gem
home and call the API from outside the repository with no checkout load paths
or inherited Bundler environment. Verify loaded gem/version/native path and
literal known answers. Repeat after clean rebuild. Document compiler, make and
matching Ruby headers; verify missing-toolchain, missing-library and
unloadable/incompatible-artifact failures do not masquerade as success.

Acceptance/stopping point: MRI 2.7.4/macOS arm64 checkout and isolated install
pass; all source/notices are packaged, ignored binaries do not leak into the
source gem, and loaded identity/stale detection are demonstrated. The gem is
locally usable; byte-for-byte reproducible binaries are not promised.

### Phase 5 — CI, native validation and private delivery (deferred)

Deferred by user decision; this work does not block Phase 6.

Dependencies: Phase 4. CI builds from clean source, runs vectors/binding specs,
builds the gem and tests isolated installation. Preserve MRI 2.7.4/macOS arm64
as required initial compatibility evidence. If hosted runners cannot reproduce
it, record local validation rather than claiming hosted coverage. Add Linux
x86_64 GCC/Clang and a selected current maintained MRI version as explicit
expansion targets; choose exact versions at implementation time and advertise
only passing lanes.

Review binding/upstream warnings separately. Run useful address/undefined
behavior sanitizer checks in a small native vector harness with bounded,
deterministic differential binary cases. Use instrumented Ruby only where
runtime/toolchain compatibility makes it reliable. Record limitations; these
checks are not a cryptographic audit or reason to style-rewrite upstream C.

Deliver examples, tested support matrix, troubleshooting, changelog/version
policy and maintainer checklist: review upstream changes, refresh manifests,
re-run vectors/native checks, clean build, isolated install and identity checks.
Produce a checksummed local source gem tied to version/source revision.
Document local artifact use and optional pinned private Git consumption;
Git/path consumers still require verified native builds. No push is implied.

Acceptance/stopping point: documented, reproducible private/local release
candidate with passing supported lanes. Standalone delivery can stop here.
Public RubyGems publication requires a later decision on name availability,
owner/account, metadata and credentials plus explicit publication authorization.
Prebuilt packages require a separate ABI/platform/install matrix. Neither is
required for Primus use; release automation must not publish by default.

### Phase 6 — Independent page-57 oracle and Primus integration

Dependencies: completed Phase 4 and Phase 2 verified independent oracle.
Phase 5 is not a prerequisite. Follow the reconciled
[Primus integration plan](primus-blake512-integration.md) for exact files,
setup commands, provenance fields and acceptance criteria.

Use the real Primus Gemfile with `blake512-ruby` version 0.1.0 from
`https://github.com/aeos161/blake512-ruby.git`, ref
`36dfec39eac5401548676c35190ab72c559a5e8c`, `require: false` and tracked lockfile.
Prove Bundler builds and loads the native extension from a fresh isolated Git
installation, without sibling checkout, local override or manual compile.
Document Git/network and compiler/make/matching Ruby header requirements.
This replaces optional separate installation/research-Gemfile architecture.
No RubyGems publication is required.

Before first run fix the original-BLAKE digest outside Runner from the existing
independently documented 124-byte page-57 plaintext. Use the Phase 2 pinned
noble-hashes oracle and record tool/source/input/digest evidence. Retain the
existing SHA-512/BLAKE2b controls as regression examples. The gem has no page-57
knowledge and no generic backend refactor is proposed.

Extend explicit ID/algorithm validation, evaluator dispatch and focused
fixtures/specs. Hash `Observation#output_bytes` directly; it already owns
frozen binary bytes. Save the four existing algorithm/policy/expected_digest/
observed_digest fields. Translate expected load/backend failures to typed
Unavailable and error/not_checked, retaining Observation; never report mismatch
or swallow unrelated errors. Validation, unrelated experiments and saved review
must work with a resolved bundle whose native artifact is unavailable. An
unresolved mandatory Git dependency fails at Bundler setup before CLI boot.

Reuse Runner/Store hash_runtime for algorithm/backend version, upstream/binding
identity, source/build identity, loaded-library digest and availability.
Fingerprint restored availability, changed versions and changed native builds;
a stale build is unavailable, not a valid new backend. Primus CODE_PATHS does
not cover an external gem, so include its descriptor rather than treating
Primus Git HEAD as sufficient. Preserve historical SHA/plaintext/BLAKE2b
fingerprints and saved entries.

Acceptance/stopping point: end-to-end page-57 control matches its independent
oracle; absent/unloadable/stale backends record errors; changed/restored
backends cannot reuse old attempts; existing controls and review pass. No
search campaign follows automatically.

## Edge cases

Keep distinct coverage for 111-byte special padding and adjacent lengths,
block transitions, zero-length buffers, NUL/high bytes, ownership under GC and
independent calls/threads with the GVL held. Keep symbols private and check
checkout versus installed resolution, missing compiler/headers, incompatible
artifacts and source edited after compile. Document that large one-shot calls
hold the GVL; parallel hashing/streaming are future decisions.

## Handoff and validation conventions

Each phase is an independently reviewable increment with its status, deliverables
and evidence recorded. Test-writer precedes implementer for behavioral work;
red tests must fail for the intended reason. Fixture research precedes tests
of the candidate. Follow existing RSpec conventions: one behavior and one
expectation per example, explicit setup, no let/let!, no deep Demeter chains,
full namespace spec paths (for example `spec/lib/aeos/blake512_spec.rb` in the
gem and `spec/lib/primus/experiment/blake512_spec.rb` in Primus),
and error classes/structured fields rather than error prose. Use simple byte
fixtures, not Rails factories. Five-line methods are a readability heuristic;
do not manufacture abstractions or rewrite upstream crypto for that limit.
Rails-specific skill advice introduces no Rails dependency. Workflow commits
remain WIP; pushes, publication and merging remain separately authorized.

## Out of scope

Pure Ruby, FFI, streaming/Digest subclass compatibility, salts/keys, other
variants, optimization/GVL release, Ractors, non-MRI, Windows, broad platform
guarantees, prebuilt binaries and public release are deferred. No unrelated
Primus refactor, runtime upgrade, search, implementation or new repository
creation occurs in this planning task.

## Open questions

Repository location, gem name, require path and namespace are settled. Confirm
MIT for new binding code before finalizing licensing in Phase 1; retain the
upstream CC0 notices. Public RubyGems publication and wider platform support
can wait until the local gem works. Exact checksums, oracle revision, CI versions
and build proof are implementation deliverables. No reliable time estimate
precedes the first native/vector gates.

## Sources and evidence limits

Primary sources were rechecked 2026-10-05; repository state rechecked on resume:

- [Designer algorithm page](https://www.aumasson.jp/blake/) establishes final
  rounds and the separate NIST-reference correction.
- [Designer compact repository](https://github.com/veorq/BLAKE) identifies CC0
  licensing. The previous investigation selected the revision above; immutable
  file fetches failed during planning, so source verification/checksums remain
  Phase 2 gates.
- [RubyGems extensions guide](https://guides.rubygems.org/gems-with-extensions/)
  and [MRI 2.7 extension API](https://docs.ruby-lang.org/en/2.7.0/extension_rdoc.html)
  inform native build/packaging and String boundary work.
- [noble-hashes BLAKE1](https://github.com/paulmillr/noble-hashes/blob/main/src/blake1.ts)
  is a candidate independent oracle, not yet a pinned/validated dependency.

Planning performed no compilation, vector generation, test run, platform
certification or registry availability check.
