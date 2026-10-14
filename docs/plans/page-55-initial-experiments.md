# Page 55: first bounded experiments

## Goal

Retain two reproducible page-55 observations and six declared target-hash
comparisons using existing recipes. Establish a small baseline before choosing
any new structural hypothesis; deciphering page 55 is not a completion criterion.
This pass creates only this plan and a roadmap note. No definitions, source,
tests, experiments, push or PR are authorized by this planning step.

## Verified baseline and rationale

Read-only inspection on 2026-10-08 found clean local `main` at
`d98c722eff3d22d69708d8dcdb28567c1cb474f3`, containing reusable totient and
complete page-56 controls, after multiple checks `45d4380`. Cached `origin/main`
remains `45d4380`; no fetch or remote-merge claim is made. Branch this plan from
current local main, not that older remote-tracking ref:
`codex/page-55-initial-experiments`.

`flaky-specs.md` records the historical UTF-8 Ruby 2.7.4 run: 608 examples,
zero failures, 12 pending; the v2 page-56 control had four matches and the
unchanged v1 control matched. Page-57 plaintext and three hash controls are
already implemented. These are prior evidence, not tests rerun by this planner.
The reusable-totient gate in the older roadmap is satisfied on local main.

The user's self-reference thesis connects GEB, Emerson/self-reliance, koans,
mirrors/Atbash, 3301/1033, internal plaintext keys and the 2016 tree/cicada motifs.
It motivates page selection, not a proven cipher. Relevant local evidence:

- [2012 account](../research/what-happened-2012-before-phone-number.md),
  sections 4.4–4.5: eight displayed line initials match the beginning of the
  reported 23-character key; full correspondence is unverified and an external
  clue also supplied the key. This is not proof of conventional autokey.
- [2014 account](../research/what-happened-part-1-2014.md), sections 4.4–4.5:
  reported reversed gematria, exceptional F/reset, and reuse of `welcome
  pilgrim to the`; these are source claims, not independently reproduced here.
- [2016 record](../research/2016-message.md), lines 30–48: exchanged vertical
  placement of tree/cicada motivates page 55 and reversal, without identifying
  a literal geometric reflection or cipher operation.
- [Post-2014 account](../research/what-happened-liber-primus-post-2014.md),
  section 4.1: zero-based GP ordinal 56 is skipped on page 56 without consuming
  prime 269. Its possible page-number/self-reference significance is a
  hypothesis, not a rule for every page. No skip 55 is in this batch.

Direct Latin is the simplest representation baseline, not a claim the page is
unencrypted. Default totient is a tightly bounded transfer of a known mechanism,
not evidence that page 55 shares page 56's cipher or exception. Neither baseline
directly tests the full self-derived-key thesis.

## Acceptance criteria

### Fixed input, target and byte policy

- Select only `page-55`, the whole existing encoded YAML body. The inspected
  source `data/encoded/liber_primus/page_55.yml` is 269 bytes, SHA-256
  `e8594c0257d70c4cd8d7cf70749241ce0fe42add14e109d010e6b82128922c95`.
  The roadmap reports 76 GP runes/four physical lines; verify these against
  transcription and image before execution, preserving ambiguity rather than
  silently correcting the source. Source positions refer to the original body.
- Freeze this literal target, obtained by joining only the five hexadecimal
  lines in the local post-2014 account (lines 176–184; joined at line 194):

  ```text
  36367763ab73783c7af284446c59466b4cd653239a311cb7116d4618dee09a8425893dc7500b464fdaf1672d7bef5e891c6e2274568926a49fb4f45132c2a8b4
  ```

  Read-only extraction verified 128 lowercase hex characters, representing
  64 digest bytes; these are not 128 target bytes. The source research file's
  SHA-256 is `88013c2b43d6a6300b61e369d11d4fab3f10e2bf59774738a89e9762c6eab525`.
  Before running, compare the five groups directly with the page-56 image and
  encoded/decoded transcriptions and record that audit. Existing encoded
  page-56 YAML SHA-256 is
  `05ef023a9165ed3300712bfacec538863e7e82b7a4b0327bde0abb9182e71e7e`.
- Declare the target interpretation as **hypothesis: the page-56 value hashes
  exact rendered Liber Primus page-55 candidate bytes**. The actual referent
  may be an external deep-web page; neither the algorithm nor serialization
  is established by the text. Three algorithms are three explicit alternatives.
- Use only `gp-latin-compatibility-v1`. Runner supplies the body with `rstrip`
  to the compatibility Builder, translates GP runes, optionally applies totient,
  then renders `to_s(:letter)`. Printer also applies final `rstrip`.
  Canonical lowercase GP expansions, existing compatibility spaces, punctuation,
  line/blank-line rendering are the contract. Preserve `euery`/`seec`-style
  canonical spellings, not modern English substitutions. Do not strip or
  normalize the saved output again, change case, join lines, introduce a BOM,
  add a final newline, or hash a terminal display/copy. Rune digraph expansions
  mean output length is not GP rune count. Record exact output byte count and
  SHA-256 before interpreting comparisons; no output length is invented here.

### Exactly two planned experiment definitions

After execution is separately authorized, materialize these proposed v2
compositions under `experiments/definitions/`; they do not exist from this pass.
Both select the checksum above and the same output policy and target.

| Planned ID | Recipe | Explicit parameters | Output/check budget |
| --- | --- | --- | --- |
| `page-55-latin-target-baseline` | `latin` | None; parameters are invalid for latin | One observation, three checks |
| `page-55-totient-latin-target-baseline` | `totient-latin` | modulus 29, prime_start 2, skip_sequence [] | One observation, three checks |

For each, checks in order are `check-1` / `sha512`, `check-2` / `blake2b512`,
`check-3` / `blake512`, each strategy `hash`, each using the literal shared
64-byte target above and provenance identifying the local source, group-joining
rule, image-audit record and unconfirmed interpretation. BLAKE2b-512 and original
BLAKE-512 are different algorithms. There is no independent known plaintext for
page 55, so do not add a fabricated plaintext expectation or use an output as
its own oracle. Target comparisons cannot establish transformation correctness.

The totient recipe subtracts `(p - 1)` modulo 29. `prime_start: 2` means prime
value 2, not prime index 2. A fresh stream starts at the first GP symbol.
Non-GP tokens consume neither ordinal nor prime. No skip, reset, arbitrary
alignment, alternative modulus, key, operation order or normalization varies.

Budget: two page derivations and six assessments total, one attempt per ID.
Operational cap: 60 seconds per attempt, 10 MiB retained artifacts per attempt;
these are operator stop limits, not existing CLI timeout/quota flags. If a cap
is exceeded, interrupt, preserve the partial record and investigate; do not
label unexecuted checks mismatches. No automatic retries or parameter search.

### Retained evidence and review

- Validate both frozen definitions before running. Inspect existing history
  before starting: v2 executes fresh every time; it does not deduplicate.
  Any justified retry gets a recorded reason and separate run ID, preserving
  prior attempts. Do not repeatedly invoke run to discover its outcome.
- Use configured Ruby 2.7.4 with UTF-8 and the existing pinned dependencies.
  Preserve Git HEAD, clean-code evidence, runtime and each backend descriptor,
  including original BLAKE gem/upstream/source/native identity. Validation is
  offline and does not prove backend availability. An error is not a mismatch.
- Retain `experiments/runs/<experiment-id>/<run-id>/record.json`, original
  `definition.yml`, `input.yml`, `source-body.txt`, one `output.txt`, and
  `provenance.json`, with existing artifact byte sizes and SHA-256 metadata.
  Keep all 76 original GP source associations if the transcription audit
  confirms that count, including original rune, decoded rune and Latin output.
- Retain three `assessments/<assessment-id>/record.json` files per complete
  attempt, ordered references, algorithm/target/provenance, observed digest,
  output SHA-256, expected digest length 64, status, timestamps, runtime/backend
  and assessment identity. Verify the saved output's actual byte count and
  SHA-256 against metadata with independent file tools; saved review alone
  does not rehash artifacts. Do not edit completed evidence.
- Record a compact research results table with one row per check: planned ID,
  run ID/record path, output byte count/SHA-256, check/assessment ID, algorithm,
  expected and observed digest, match/mismatch/error, execution status and
  interpretation. Link saved provenance and runtime rather than duplicate them.
  Initial state of all six rows is **not run**, not mismatch.
- A fully processed three-mismatch attempt is `status: completed`,
  `matching_outcome: no_match`, counts 0/3/0 and exit 0. Completion does not
  mean a match. One match gives `matching_outcome: matched`; a backend error
  still gives execution status error/nonzero exit, even alongside a match.
  Report each algorithm separately and preserve all errors/negative results.

## Approach and concrete next step

No preparatory refactor, source implementation or test-writer handoff is needed
for these existing recipes. The implementation baseline is inspected in
`lib/primus/experiment.rb`, `experiment/composition.rb`, `experiment/runner.rb`,
`experiment/store.rb` and `commands/experiments.rb`. Current CLI accepts repeatable
hash flags and one shared bare digest; parameter values are JSON scalars/arrays.
Preset IDs cannot be combined with composition flags.

After plan review and separate execution authorization: audit source/target,
freeze the two named definitions and provenance, validate, then execute each
once and review the emitted saved review command. Check history first and retain
every attempt. Proposed named validate/run commands become usable only after
those definitions exist; this plan does not pretend they are installed presets.
For parser clarity, this is a supported ad-hoc validation example using today's
code (not executed here and not a third planned experiment):

```shell
RUBYOPT=-EUTF-8 bin/primus experiments validate --input page-55 --recipe totient-latin --recipe-param 'modulus=29' --recipe-param 'prime_start=2' --recipe-param 'skip_sequence=[]' --hash sha512 --hash blake2b512 --hash blake512 --expect-digest '36367763ab73783c7af284446c59466b4cd653239a311cb7116d4618dee09a8425893dc7500b464fdaf1672d7bef5e891c6e2274568926a49fb4f45132c2a8b4' --expect-provenance 'Local post-2014 account section 4.1, joined five hex lines; LP plaintext interpretation unconfirmed.'
```

Acceptance is a complete evidence table and honest interpretation, not discovery
of plaintext. If all six comparisons mismatch, stop the batch and record only
that these two exact byte outputs under these three algorithms do not equal
this target. Do not refute self-reference, totient generally, page 55, other
representations or the external-page interpretation. Review transcription,
byte-policy and target assumptions before selecting one newly justified bounded
follow-up. Do not automatically expand the search.

If any check matches, preserve the exact output and independently recompute
that algorithm over the saved bytes with an implementation independent of the
Primus wrapper; verify source, target, byte length, checksums and provenance.
Report an independently verified byte/digest match before interpreting historical
intent. A match alone is not a premature claim to have solved Liber Primus.

## Deferred structural work and edge cases

Existing `ReverseEntireSequence`, `ReverseLineOrder` and
`ReverseTokensWithinLines` operate on Transcription through PageMapper; they
are not selectable experiment recipes. `ReverseEntireSequence` reverses tokens
within each page occurrence, not page order across a joined document. Punctuation,
line tokens and fixed source coordinates require explicit semantics. Atbash and
Vigenere Document visitors also are not v2 recipe choices. No chain/checkpoint
configuration exists in the inspected Runner, whose input is one page.

Before any new reverse/Atbash/key chain runs against page 55, plan that narrow
capability separately and pass an independently specified synthetic layered
control: known source, ordered layers, frozen intermediate/final bytes and
hashes, delimiter/source mapping, key/prime consumption and inversion checks.
This future-chain gate does not block the existing Latin/totient baselines.
Self-derived line-initial keys additionally need exact extraction/constraint
semantics; English-looking text or hash closeness is no oracle.

Page 54–55 concatenation is a later independent hypothesis, requiring explicit
multi-page input and continuing-versus-reset state semantics. Current whole-page
input IDs do not accept a page list; do not invent a combined-page command or
modify page-55 YAML to simulate one. Page 54 alone is not in this first batch.
A page-number skip such as [55] is at most a separately justified low-prior
follow-up, never a silent default or an automatic rescue of negative results.

Missing backends, malformed definitions, changed input checksums, image ambiguity,
interruption, storage failure, missing artifacts and changed native runtime
are concrete failure conditions to report. Resolve before interpretation;
never erase incomplete history. Checks can complete after an earlier mismatch,
so inspect all three results rather than stopping at the first negative.

## Out of scope

Normalization search, parameter brute force, arbitrary skip sets, language
ranking, hash-closeness ranking, checkpoint hashing, general chain framework,
combined pages, new algorithms, saved-output reassessment/reuse and general
preset overrides. No software tests or experiment execution in this pass.
If later software changes become necessary, re-plan the narrow capability and
use fully namespaced RSpec, no let/let!, one behavior/expectation and independent
literal controls. Log actually observed unexpected test failures in root
`flaky-specs.md`; no new test result or log entry is claimed here.

## Open questions

What the target hashes, which algorithm it uses, and which exact serialization
it expects remain unknown. The page-55 transcription and page-56 target need
image audit before execution. Whether page 54 belongs to the decoding unit and
whether self-reference specifies a real key rule remain later hypotheses.
None requires inventing additional baseline variants or a generic framework.
