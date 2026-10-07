# Original BLAKE-512 in Ruby: investigation and proposed work

## Status update — standalone delivery selected

The [standalone gem delivery plan](standalone-blake512-gem.md) now controls
implementation scope and sequencing. It supersedes this investigation's
inline `ext/primus_blake512` packaging proposal and mandatory Primus extension
option. Algorithm research and evidence limits below remain historical
context; native ownership moves to an independent gem and Primus integration
becomes a later separate increment. Neither plan proves a built or released
backend.

## Goal

Make final original BLAKE-512 available to Primus through a narrow Ruby
byte-string API, with independently checked correctness and reproducible
backend identity. This is a scoped investigation/proposal, not implementation
approval or a claim that native compatibility has been demonstrated.

Inspected 2026-10-05: clean main and origin/main at `6dcf1df`, containing the
completed BLAKE2b control. This plan starts from that actual baseline.
The superseded combined [BLAKE plan](page-57-blake-controls.md), current
[BLAKE2b plan](page-57-blake2b-control.md), and deferred
[research direction](page-54-55-research.md) do not authorize a search campaign.
No prerequisite refactor is indicated by the current explicit evaluator,
backend collaborator and saved-runtime boundaries.

## Findings and recommendation

Recommend a small MRI C extension around the designer's compact reference
implementation. Own the binding and build lifecycle locally; do not reimplement
the cryptographic core. Final December-2010 BLAKE-512 uses 16 rounds; it is
neither earlier 14-round BLAKE-64 nor BLAKE2b nor BLAKE3. The designer's
[algorithm page](https://www.aumasson.jp/blake/) establishes this distinction.

The [designer repository](https://github.com/veorq/BLAKE) is CC0 and has only
four commits in its displayed history, most recently May 2014. Its simplicity
is useful, but it is not evidence of maintained Ruby/platform support. Pin
[65f9ac8101191b12368e533afed6486c5b694fa3](https://github.com/veorq/BLAKE/commit/65f9ac8101191b12368e533afed6486c5b694fa3),
retain LICENSE/copyright notices, record checksums of imported files and
explain every local patch. The commit and current source were inspected via
GitHub; immutable source downloads/checksums remain implementation work.

[blake512.c](https://github.com/veorq/BLAKE/blob/master/blake512.c) exposes
`blake512_hash(out, in, uint64_t inlen)` with length in bytes. It also embeds
CLI main/self-tests; these must not become the Ruby-facing interface.
[blake.h](https://github.com/veorq/BLAKE/blob/master/blake.h) defines constants,
so avoid compiling repeated global definitions. Keep integration changes
small and auditable, with private symbols or appropriate symbol visibility.
The byte-oriented loads avoid an obvious host-endianness assumption; this
source inspection is not a portability test.

Searches did not establish a maintained original-BLAKE Ruby gem. This is not
proof that none exists. RubyGems search/API could not be retrieved here.
[mgomes/blake2b](https://github.com/mgomes/blake2b) explicitly implements BLAKE2b;
[Shopify/blake3-rb](https://github.com/Shopify/blake3-rb) implements BLAKE3.
Neither supplies the requested algorithm. Do not select a similarly named
package without inspecting its source, version, license and final-round vectors.

| Option | Assessment |
| --- | --- |
| Small native extension, vendored reference | Recommended: least new algorithm code; requires compiler, Ruby headers, packaging, and binding review |
| Pure Ruby | No native build and easier distribution; requires owning a new cryptographic port, explicit 64-bit masking/rotations and padding correctness; speed unmeasured |
| FFI/Fiddle | Still requires a compiled shared library and loader/distribution work; adds ABI/pointer handling without removing the C dependency |
| Separate executable | Useful independent preparation tool; runtime integration adds process launch, binary I/O, failure/output parsing and executable provenance; poor default for repeated candidate hashing |

## Acceptance criteria

- Select only final, unsalted, unkeyed `blake512`; one-shot input is a Ruby
  String of exact bytes. Native result is 64 binary bytes; Ruby hexdigest is
  exactly 128 lowercase hex characters. No normalization, newline addition,
  encoding conversion, caller mutation, parameter variants or fallback.
- Published independent known-answer fixtures verify empty, `abc`, padding
  boundaries 110/111/112 bytes, block boundaries 127/128/129, and a multi-block
  binary input. Pin input bytes, literal digest, source revision and provenance;
  never derive fixture expectations from the candidate implementation.
- Project Ruby 2.7.4 arm64 can build/load and pass vectors using documented
  commands. Test both a clean checkout development build and built-gem install
  in isolation; no reliance on an old extension in another load path.
- Missing/incorrect-architecture/unloadable extension yields a typed unavailable
  error, not mismatch. Validation, unrelated experiments and saved review remain
  usable. No automatic compilation or network download during hashing or review.
- A later page-57 control hashes the existing 124 owned frozen output bytes,
  saves the four existing hash-check fields, and records errors as error/not_checked
  while retaining produced Observation. Its expected digest is fixed beforehand.
- Saved backend source/build identity participates in original-BLAKE fingerprints;
  restored availability or a different built backend cannot reuse an unavailable
  attempt or masquerade as the earlier backend. Existing histories stay readable.

## Approach

1. **Vendor and bind narrowly.** Add `ext/primus_blake512/` with source, notices,
   binding and `extconf.rb`, plus a focused lazy Ruby boundary such as
   `lib/primus/experiment/blake512.rb`. Use Ruby's actual String byte length,
   never strlen or an int truncation; validate conversions to the C length type.
   Keep a fresh stack state and fixed-size output per call. Hold the GVL for
   this initial small-input use, with no Ruby callbacks while holding raw String
   pointers. Releasing it would require additional input lifetime/mutation
   protection and is unnecessary scope now. Review pointer bounds, counters,
   empty buffers and error paths; no broad digest adapter framework.
2. **Make builds reproducible.** Current `primus.gemspec` includes Ruby files,
   bin files, LICENSE and root Markdown only, and declares no extensions.
   Explicitly include native sources/notices and register the extension. Add a
   development compile task/load path and clean/rebuild instructions: a Gemfile
   path gem and `bundle exec` are not by themselves proof that local native
   files were built. `bin/primus` prepends local lib and uses bundler/setup;
   ensure it loads the intended checkout build. Keep generated objects and
   bundles ignored. Follow [Ruby 2.7 extension documentation](https://docs.ruby-lang.org/en/2.7.0/extension_rdoc.html)
   and [RubyGems extension packaging](https://guides.rubygems.org/gems-with-extensions/).
3. **Prove the implementation.** Locate and pin final-version published vectors,
   not older submission vectors. The compact source has one-zero-byte and
   144-zero-byte self-tests; they are useful but insufficient boundary coverage.
   The designer page warns that the separate NIST-API reference received a
   correctness fix on 2015-09-07, so do not silently use an old copy as an oracle.
   Independently implementated [noble-hashes BLAKE1](https://github.com/paulmillr/noble-hashes/blob/main/src/blake1.ts)
   is a candidate cross-check, not a validated dependency selected here. Pin
   and vet its revision/runtime, then require agreement with authoritative
   vectors before using it for oracle preparation. No new production dependency
   on JavaScript is proposed.
4. **Connect the existing experiment boundary.** Extend explicit ID/algorithm
   validation and evaluator dispatch only when adding the page-57 control.
   Reuse Store's hash_runtime support, with original-BLAKE fields for source
   revision/checksums, binding identity, Ruby ABI/platform, compiler/build flags,
   built-library SHA-256 and availability. Include native source and relevant
   build inputs in Runner CODE_PATHS, which currently omits ext/vendor/Rakefile.
   Verify the loaded build corresponds to current source; a ignored stale binary
   must not appear equivalent to a fresh build. Do not alter BLAKE2b metadata or
   historical SHA/plaintext fingerprints.
5. **Prepare the scientific control separately.** Recheck the known page-57
   plaintext source and byte policy from the BLAKE2b plan. Generate its literal
   expected original-BLAKE digest outside Runner, cross-check with a separately
   implemented verified backend, and record tool/source identities. Running the
   same vendored C through a CLI and Ruby checks the binding, but is not an
   independent algorithm cross-check. Preserve the expectation before first run.

## Edge cases

NUL/high bytes, frozen and differently encoded Strings, empty input, repeated
calls, inputs across padding/block boundaries, wrong library architecture,
missing compiler/headers, changed source with stale binary, and installed-gem
versus checkout resolution all require explicit checks. Do not catch unrelated
execution errors as unsupported algorithms. No shared mutable digest state.

## Out of scope

This investigation performs no installation, compilation, source/test edit,
vector generation, experiment execution or suite rerun. Prior 482/0/12 test
results are historical, not verified here. No runtime upgrade, performance
project, streaming API, salted/keyed variants, general adapter framework,
page-55 search, prebuilt binary distribution, push, merge or PR creation.

## Open questions and limits

Read-only probes verified `/Users/chriswoodford/.asdf/installs/ruby/2.7.4/bin/ruby`
as 2.7.4p191 arm64-darwin21, its ruby.h exists, RbConfig selects clang and
.bundle extensions, xcrun finds Command Line Tools clang, and make is present.
These are prerequisites, not a successful compilation/link/load demonstration.
Initially verify this environment; Linux/x86_64, other Ruby versions, Windows
and non-MRI support require explicit testing before being advertised.

Decide whether compiler-free installation of other Primus features must remain
supported: declaring a normal mandatory extension makes gem installation need
a working toolchain even though runtime loading can be lazy. If compiler-free
installation is required, deliberately choose an optional backend package/build
strategy rather than silently succeeding after a failed required build.

Exact source hashes, independent boundary fixtures, `abc` fixture provenance,
independent oracle tool revision, supported platform scope and packaging smoke
results remain to establish. The substantial work is correctness/build/provenance
integration, not adding another evaluator case. No reliable elapsed-time estimate
is justified before the first build and vector checks.
