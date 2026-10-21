# IC interpretation for saved-checkpoint analysis

## Goal

Every IC result printed by `analyses run` or `analyses review` includes a
plain-language judgment about its similarity to English repetition, including
an explicit insufficient-evidence judgment when comparison is unavailable.
Keep exact raw measurements, selected-checkpoint identity, hash outcomes and
execution success distinct.

## Baseline and prerequisite assessment

Review amendment to `codex/checkpoint-symbol-analysis`, inspected at `34541e9`
on 2026-10-21 with a clean working tree. Continue that in-flight branch and its
CLI review; do not restart from main. This plan supersedes only the earlier
plans' prohibition on English comparisons, not their measurement or evidence
contracts. Position windows remain deferred to the VERY END.

No prerequisite refactor is warranted: SymbolStatistics already owns arithmetic,
Result owns measurements, LogEntry owns stage evidence, and Runner coordinates.
A focused interpretation collaborator can supply this new scientific behavior
without expanding the thin result into a classifier or moving checkpoint state.
No source edits, tests, research trials, pushes or PRs occur during this pass.

## Acceptance criteria

### Always present, narrowly worded judgment

- Keep full frequency bins, N, numerator, denominator, raw numeric value and
  `normalization: none` unchanged. Add interpretation beside every printed IC,
  for every declaration, representation and selected stage, on run and review.
  An insufficient measurement is a successful analysis with insufficient
  evidence, never a scientific failure or an invented zero.
- N=0/1: `English comparison: insufficient evidence — fewer than two symbols;
  IC is undefined.` Retain existing null value and exact 0/0 semantics.
- For N>=2, use the explicitly named, representation-matched reference set
  below. Print signed difference from each reference, and a descriptive
  judgment using these ordered, exhaustive rules (exact rational arithmetic,
  before display rounding):
  1. IC above the maximum control IC: `More concentrated than both solved
     English controls; higher IC does not mean closer to English.`
  2. IC within the inclusive range of control ICs: `Within the observed IC
     range of the solved English controls; compatible with their repetition
     level, but this does not establish English plaintext.`
  3. Otherwise compare absolute distance to the nearest control IC against
     distance to the theoretical uniform-alphabet IC. Smaller control distance:
     `Closer in IC to a solved English control than to the uniform benchmark,
     but below the controls' observed range.` Smaller uniform distance:
     `Closer in IC to the uniform benchmark than to either solved English
     control; weak support for English-like repetition from IC alone.`
     Equality: `Equally distant from the nearest English control and uniform
     benchmark; IC comparison is inconclusive.`
- These are descriptive numerical comparisons, not fitted thresholds, language
  likelihoods, confidence percentages or significance tests. A single-symbol
  repeated sample has IC=1 and must not receive a stronger-English label.
  Samples with the same histogram (including a permutation/substitution that
  destroys readable words) receive the same comparison. State that IC measures
  repetition, not word order, readability or correctness of a decryption.
- Every computed judgment displays N and: `Limited comparison: two short solved
  controls, with different lengths; sample variation can be substantial. This
  is not a probability of English or evidence of decryption.` This applies to
  short page-55 samples without inventing a universal minimum useful N or
  claiming reliability above an arbitrary cutoff. N>=2 makes IC defined, not
  statistically persuasive. Do not treat overlapping symbol pairs as independent
  Bernoulli trials or attach a naive binomial confidence interval.
- A known measurement with no compatible reference receives `English comparison:
  insufficient evidence — no compatible English reference is available.` Show
  a theoretical uniform benchmark only when the alphabet is known. Unknown
  representation/alphabet is never silently treated as Latin-26 or GP-29.
  Corrupt new reference data remains an explicit execution/read error rather
  than quietly downgrading scientific provenance to unavailable.

### Reference and baseline contract

- Ship one small, versioned, offline reference packet for the existing solved
  page-56 and page-57 English controls, separately in `gp-runes-v1` and
  `gp-expanded-latin-v1`. Name it `solved-gp-english-controls-v1` everywhere;
  never label its range `typical English` or an English confidence interval.
  This is an intentionally limited domain comparison, not a general corpus.
- Before test expectations, independently freeze the actual decoded GP token
  sequences for both controls, their canonical letter expansions, ordered
  histograms, N and exact IC fractions. Bind them to source/fixture paths,
  immutable source revision, source byte digests, extraction rules and canonical
  expansion-map digest. Record manual/independent derivation in a fixture oracle
  note. Never reconstruct rune identity by ambiguously retokenizing plaintext,
  generate expected values through production SymbolStatistics, or compare the
  candidate against its own output as reference. Existing page-56 oracle packet
  and page-57 expected output are starting evidence, not sufficient rune oracles.
- Page-56 hexadecimal passthrough and all punctuation/whitespace/literal letters
  outside decoded GP tokens are excluded exactly as in candidate measurement.
  Preserve canonical `u`, `c`, `s`, `ng`, `io` etc.; do not silently normalize
  them into conventional English spelling. Calculate the two representations
  separately; their alphabet sizes, lengths and English reference values differ.
- Uniform independent draws from K equally likely symbols have expected raw
  IC 1/K: GP-29 is 1/29 (~0.0344827586), Latin-26 is 1/26 (~0.0384615385).
  These values follow directly from sum over K probabilities (1/K)^2. They are
  theoretical expectations, not the finite-sample IC of equal integer bins.
  Label Latin-26 theoretical: uniform GP runes expanded canonically do NOT
  generate uniform independent Latin letters (some Latin bins are unreachable).
  Do not call either comparison proof of random ciphertext.
- Do not borrow ~0.066 as a universal English baseline, or reuse the legacy
  `expected_index_of_coincidence` methods. They normalize by alphabet size,
  whereas this API is raw; existing frequency tables also do not establish the
  required corpus/extraction provenance. A broader corpus and calibrated
  uncertainty model would require a separate reviewed proposal.

### Owned data and historical semantics

- Persist method ID/version, judgment code, explanatory text, limitations,
  representation, N, theoretical-uniform fraction, both reference IDs and exact
  fractions/sample sizes, exact signed differences, and reference provenance
  digest/source description with each owned measurement. Display rounding is
  cosmetic; it cannot decide labels. Reference snapshots are immutable and
  owned; do not freeze caller-owned collections.
- Use a versioned interpretation payload so the existing raw analyzer need not
  change identity. Validate new payload version, representation/N agreement,
  finite numeric fields, reference shape and allowed status/judgment combinations
  at the persistence boundary. Do not make CLI traverse raw result hashes or
  perform policy calculations. New completed results must contain the payload.
- Historical review displays the saved judgment/references even if current
  reference files, definitions or source artifacts change/disappear. Do not
  recompute historic comparisons, modify older records, rerun transformations,
  require a hash backend, or reinterpret success/hash status as English support.
- Recognize older records without a payload explicitly at the loading boundary:
  retain raw IC and print `English comparison: insufficient evidence — this
  historical analysis did not retain an interpretation; create a new analysis
  for a versioned comparison.` This is display context, not a retroactive saved
  scientific judgment. Never silently treat a malformed/present payload as old.
- All original/intermediate/final selectors and terminal aliases retain their
  existing requested stage, resolved checkpoint, profile and artifact identity.
  An interpretation belongs to its measurement; checkpoint context remains on
  the owned LogEntry/Observation. Analysis append-only behavior is unchanged.

## Approach

- Add a focused pure query collaborator (for example `ICInterpretation`) and a
  small reference-data reader at the appropriate boundary. Its policy and
  representation-specific references are explicit inputs; no arbitrary
  thresholds embedded in Result, global mutable registry or per-scalar objects.
- Keep SymbolStatistics responsible for counts and exact IC. Runner assembles
  the measured result and interpretation through owned direct APIs; its `run`
  remains a nil-returning command. Result remains a thin owned measurement
  with a direct interpretation reader, not forwarding every nested field.
- Extend LogEntry serialization and RecordValidator boundary checks to retain
  interpretation snapshots and recognize old payload absence deliberately.
  Keep hash representation inside these boundaries, not deep traversal across
  orchestration. Add a narrow validator collaborator only if the new behavior
  cannot fit the existing class limits; do not use this as broad refactor scope.
- `commands/analyses.rb` prints raw IC and interpretation together through one
  rendering path used by run/review. Keep any necessary presenter focused on
  formatting, not scientific policy. Update README with exact label semantics,
  reference limitations, and raw-versus-normalized distinction.
- Likely additions: versioned packet under `data/analysis/`, independent oracle
  note/fixtures under `spec/fixtures/analysis/`, focused interpretation specs,
  and selected existing analysis/CLI persistence integration specs. This plan
  deliberately defines behavioral policy rather than prescribing needless
  class layers. Apply Ruby clean-code, CQS and existing method/class limits.

## Test-first handoff (after plan review)

1. Freeze independently checked control evidence and literal values first.
   A red CLI feature proves both new and reviewed results always include a
   judgment beside unchanged exact IC, for both representations.
2. Pin policy behavior with literal fractions: N=0/1, N=2, zero collisions,
   balanced finite counts, near-uniform, exact reference values/range endpoints,
   below the range nearer either comparator, exact distance tie, above both
   controls, and all-identical IC=1. Cover display rounding near boundaries.
   Use synthetic comparator fixtures to isolate branches, and real frozen
   controls to establish integration; never derive expected labels from code.
3. Verify multi-letter rune differences, canonical spelling, excluded page-56
   hex, independent alphabet baselines and control sample sizes. Shuffling the
   same counts cannot produce a different judgment or plaintext claim.
4. Exercise saved snapshots through run/review, modified/deleted current
   references, original/intermediate/final stages, unchanged source artifacts,
   old records without interpretation, malformed present payloads, unsupported
   versions and incompatible references. Assert ownership at the behavioral
   boundary without unit-testing thin serializers or forwarding methods.
5. Preserve existing independent transformation/control arithmetic, raw IC,
   selected evidence and hash/execution separation regressions. Run focused
   changed specs then required suite/lint with existing documented environment;
   report the known clone-race behavior honestly if encountered. No page-55
   experiments or fixture changes to force a desired label.

## Edge cases

For the reported `232/7140 = 0.032492997198879554`, N=85 because
85*84=7140. With no representation stated, the honest example is:

```
raw IC: computed 232/7140 0.032492997198879554
English comparison: insufficient evidence — the alphabet/representation is
not specified, so an English reference cannot be selected (N=85).
Context: this is below both theoretical uniform benchmarks: GP-29 0.034483,
Latin-26 0.038462. That alone does not identify the language or prove randomness.
```

The actual application knows the representation and will show the corresponding
control comparison. Do not predeclare its final label until the independent
reference fractions are frozen. Expected fractions must not be selected to make
this example look better. Zero computed IC and undefined IC remain distinct.

## Out of scope

Position windows/subranges (VERY END), new analyzers, n-grams, language detection,
plaintext probabilities, percent decrypted, significance testing, ranking/search,
key discovery, broader corpus ingestion, transformations, hash reassessment,
page-55 runs, deleting/backfilling analyses, pushes, PRs and downstream agent
handoff before this plan is reviewed.

## Open questions

Proposed review choice: use the two clearly labeled solved GP-English controls
as a bounded initial reference, instead of claiming a general English corpus
baseline. Their exact numerical reference packet remains implementation/test
preparation, independently audited before expectations or labels are frozen.
If general-English probability or calibrated confidence is desired, that is
additional scientific scope and requires new reference/calibration design.
