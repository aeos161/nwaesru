# Lag coincidence of saved checkpoints

## Goal

Measure equal-symbol pairs at explicitly declared positive offsets across an
entire selected checkpoint. Retain exact match/comparison counts and raw fractions
for GP runes and separately declared canonical expanded-Latin symbols, without
claiming that a peak proves a period, repeating key, plaintext or English.

## Baseline and delivery boundary

Inspected local main and origin/main at `e015a88` on 2026-10-28. Atbash,
reverse-runes, continuous page input and checkpoint analysis are merged.
This is its own implementation increment, independent of the separate
`repeated-ngram-analysis.md` plan. Give each feature its own implementation
branch, tests and review. Either can start against this baseline. Refresh actual
interfaces before implementation if the sibling has since merged; do not assume
its proposed objects or files exist or implement it as part of this change.

No standalone prerequisite refactor is warranted. Existing Definition, Runner,
Result, LogEntry, RecordValidator and CLI have symbol-statistics assumptions,
but modest explicit analyzer dispatch and dedicated measurement responsibilities
fit their existing separation. Avoid a generic analyzer registry/framework and
an IC Result with irrelevant optional fields. If concrete implementation friction
requires a structural prerequisite, stop for a separate fresh plan instead of
bundling it. Existing statistics and IC interpretation must remain unchanged.

This planning branch changes documents only and preserves the two untracked
user YAML files under experiments/definitions and experiments/analyses.

## Acceptance criteria

### Declaration and observation

- Add analyzer `lag-coincidence`, version 1, requiring parameters `lags` and
  `boundary_policy: continuous-gp-v1`. `lags` is a nonempty, strictly increasing
  list of unique integer offsets in 1..1024, at most 64 entries. The proposed
  example is [1,2,3,4,5,8,13,21]. Bounds limit work/output, not scientific merit;
  there is no hidden default range, adaptive lag selection or peak search.
- Reject zero, negatives, floats, booleans, strings, duplicate/unsorted offsets,
  too many offsets, out-of-bound values, unknown parameters/versions and missing
  parameters before reserving a run. Lags at least N remain valid declarations
  and produce explicit insufficient-sample rows instead of disappearing.
- Keep one or two declarations, unique IDs and representations, and one shared
  checkpoint stage. Require one analyzer family per definition; GP and expanded
  Latin may be two entries of that family with independently declared lags.
  Existing symbol-statistics definitions remain valid without new parameters.
- Preserve original/final/named saved checkpoint selection, explicit experiment
  and run IDs, full retained-chain verification and current eligibility rules
  for completed captures of finished runs. No source reload or transform rerun.
- `continuous-gp-v1` takes captured symbols_rows in CURRENT ordinal order. Remove
  all non-GP passthrough literals, including ASCII words, whitespace, punctuation,
  line endings and digits. They neither count nor interrupt the sequence.
  Offsets cross line/page boundaries and declared page occurrences. Never insert
  separators, sort by source position or split into windows/blocks/residue classes.
- `gp-runes-v1` counts one per rune with alphabet size 29. Separately declared
  `gp-expanded-latin-v1` splits the canonical GP expansions into letters, alphabet
  size 26. Do not inspect rendered output text. Retain profile/map binding and
  name the unit: rune offsets and expanded-letter offsets are not interchangeable.

### Exact result and interpretation

- For each requested lag d and full sequence s of length N, comparison_count is
  max(N-d,0). Match_count is the number of i satisfying 0 <= i < N-d and
  s[i] == s[i+d]. No wraparound, padding, unordered-pair doubling or normalization.
- Store one row per declared lag in ascending order: lag, status, match_count,
  comparison_count and value. value is match_count/comparison_count as an
  unrounded numeric value when positive denominator; integer counts remain the
  authoritative exact fraction. Status is computed even when match_count is 0.
  When denominator is 0, match_count is 0, status insufficient_sample and value
  is null. N=0/1 therefore has insufficient rows for every positive lag.
- Store sample_size, alphabet_size, declaration/representation identity and the
  exact declared lag list and boundary policy. Do not reuse IC's N*(N-1)
  denominator or sum counts across lags into an undocumented score.
- Expanded-Latin rows additionally partition comparisons and matches into
  within_source_rune and across_source_runes counts, based on current checkpoint
  rune ordinal of each expanded position. Their sums equal the respective total
  counts. This distinguishes canonical multi-letter expansion effects from
  relations between runes without interpreting either as English evidence.
  GP rows have zero within-rune counts and all comparisons across runes; use the
  same explicit partition fields for simple validation and representation parity.
- Persist the immutable current-position map once per result: zero-based index,
  current rune ordinal, and verbatim original source page_number, occurrence,
  rune_index, byte/character start/end, line and column. Expanded positions also
  store zero-based expansion_offset/expansion_length; original spans belong to
  the source rune, not invented substrings. This binds filtered indices and
  partitions to retained provenance under mirroring/reordered sources.
- Retain a fixed versioned limitations statement: peaks are descriptive equality
  at a chosen offset; finite comparison counts, selected offsets, repetitions
  and canonical expansions affect them. No p-values, confidence labels,
  period/repeating-key certainty or classification thresholds in v1. Insufficient
  rows explicitly explain that the lag has no available comparisons.
- Do not add a uniform or English baseline to this increment. In particular,
  1/29 or 1/26 would require an explicitly assumed independent-uniform model,
  which does not generally describe these sequences; symbol-statistics' retained
  IC control packet is not a lag-specific null model. Existing IC interpretation
  stays confined to symbol-statistics and is never relabeled as lag evidence.
- Bijective relabeling preserves all GP equality counts. Total sequence reversal
  also preserves match/comparison counts at every lag, so this statistic cannot
  choose a direction or distinguish Atbash from the original. Reversing rune
  order is not generally reversing expanded characters: internal expansions keep
  their order. These limitations are explicit in CLI/docs and tested.
- Use lag evidence on encrypted intermediates as descriptive structure; do not
  rank/prune candidates or require language-like IC before measuring it.

### Persistence, validation and CLI

- Append analyses in the existing run directory, retaining definition bytes and
  digest, analyzer/version/parameters, evidence profile, requested/resolved
  checkpoint and artifact digests, execution identity and exact result snapshot.
  Results deeply own their nested data and do not freeze caller-owned values.
- Review only retained results, including limitations; never rerun transforms or
  measurements or silently update historical parameters from current YAML/code.
  Preserve existing symbol-statistics frequency/IC review and interpretations.
- Validate definition-to-envelope analyzer/version/parameter identity, profile,
  stage and checkpoint bindings. Dedicated lag validation checks exact lag list,
  row order/uniqueness, integer counts and bounds, N-d denominator, status/null
  rules, numeric fraction agreement, partitions, position-map length/order and
  valid source coordinates. Reject unknown fields/versions and contradictions
  through existing CLI errors. Do not repair records or infer missing evidence.
- Analysis RecordValidator currently accepts checkpoint operations only capture,
  totient and latin although Experiment verifies atbash and reverse-runes. Bring
  analysis review into parity for those already-merged operations and their
  existing policy/parameter contracts. Test named intermediate review; do not
  weaken lineage validation or introduce transformations.
- Preserve containment, strict parsing, final-projection parity, duplicate-key
  checks and artifact validation. Invalid observations create no completed
  result; persistence failures keep the current incomplete/error behavior.
  Saved observations and previous analyses are never rewritten or deleted.
- CLI reports selected checkpoint/representation/unit/boundary policy and N,
  followed by every lag, match/comparison fraction, value/status and comparison
  partitions, in declaration order. Display the stored limitations. No top-peak
  filtering, significance decoration or hidden sample-size cutoff.

## Approach

- `lib/primus/analysis/definition.rb`: explicit bounded parameter validation
  beside the unchanged symbol-statistics schema; same selectors and CLI syntax.
- `analysis/observation_reader.rb` and `observation.rb`: expose a deeply owned
  sequence/position mapping from already-verified selected symbols_rows. Existing
  CheckpointEvidence remains the source of verified lineage, coordinates and
  artifact snapshots. Use a focused noun-named sequence object if needed; avoid
  raw nested traversal in analyzer/CLI, scalar wrappers or a second verifier.
- Add `analysis/lag_coincidence.rb` and `lag_coincidence_result.rb` to own counting
  and immutable result queries. Keep `analysis/result.rb`'s statistics contract.
  Loop over at most 64 lags, with linear work per lag; do not materialize every
  comparison pair or add FFT/parallel execution. Within/across partitioning uses
  the owned map, not source byte adjacency or assumed increasing source IDs.
- `analysis/runner.rb`: explicit declared analyzer selection; only statistics
  enters ICReferencePacket/ICInterpretation. Preserve nil-returning run command.
  `log_entry.rb`: envelope and restore the appropriate measurement type with its
  retained analyzer/version/parameters rather than hardcoding statistics.
- `record_validator.rb`: reuse shared evidence checks and delegate measurement
  invariants to a small lag validator if needed. `commands/analyses.rb`: explicit
  renderer for lag rows; extract a focused presenter if needed for existing
  class limits and roughly five-line methods. Keep noun ownership and CQS;
  no unrelated restructuring, Rails dependency or new persistence layer.
- Retain `analysis/store.rb` mechanics and round-trip tests. Update relevant
  definition/observation/reader/runner/log-entry/validator/store/CLI specs, and
  add lag measurement/result specs plus independent literal fixture note
  `spec/fixtures/analysis/lag_coincidence_oracle.md`.
- Add `experiments/analyses/lag-coincidence.yml` and README examples during
  implementation. Do not alter the existing untracked user research YAMLs.
  No migration/backfill machinery for disposable pre-v1 runs; preserve evidence.

Example definition (not created during this planning pass):

```yaml
schema_version: 1
id: lag-coincidence
analyses:
  - id: rune-lags
    analyzer: lag-coincidence
    version: 1
    parameters:
      lags: [1, 2, 3, 4, 5, 8, 13, 21]
      boundary_policy: continuous-gp-v1
    target:
      stage: original
      representation: gp-runes-v1
```

```sh
bin/primus analyses run EXPERIMENT_ID RUN_ID --definition experiments/analyses/lag-coincidence.yml
bin/primus analyses review EXPERIMENT_ID RUN_ID ANALYSIS_RUN_ID
```

## Independent controls and validation order

1. Hand-compute `AAAA`: d=1 -> 3/3; d=2 -> 2/2; d=3 -> 1/1;
   d=4 -> 0/0, null/insufficient. `ABABA`: d=1 -> 0/4,
   d=2 -> 3/3, d=3 -> 0/2, d=4 -> 1/1, d=5 -> 0/0.
   Pin the literal answers, not production-derived expectations. Use real GP
   rune equivalents in saved-checkpoint integration. Cover N=0, N=1 and d=N-1.
2. `ᚦᚪᚦ` is GP TH,A,TH: d=1 -> 0/2, d=2 -> 1/1.
   Expanded `thath`: d=1 -> 0/4 (within-rune 0/2, across 0/2);
   d=2 -> 0/3 (within 0/0, across 0/3); d=3 -> 2/2
   (within 0/0, across 2/2); d=4 -> 0/1. Pin the map linking
   indices 0/1 to rune 0 and 3/4 to rune 2 with offsets 0/1.
3. Add punctuation, ASCII, CRLF and page joins to prove filtered continuity.
   Combine repeated pages in nonnumeric order, then mirror the checkpoint;
   assert current ordinal mapping and original coordinates independently. No
   assumed monotone page/occurrence/rune_index ordering after transformations.
4. Show two sequences with identical symbol frequencies and IC but differing
   lag counts: `AABB` d=1 is 2/3; `ABAB` d=1 is 0/3. This distinguishes
   sequence evidence from frequency evidence without ranking either as English.
   Test bijective GP relabeling and full reversal invariants with literal data.
5. Verify original/totient/atbash/reverse-runes/final selection, alias identity,
   finished-error eligibility and corrupted/missing evidence. Independently
   freeze oracle bytes/coordinates; production transforms, parser, analyzer or
   serializer must not compute their own expected measurements. Existing page
   56/57 controls remain regression coverage; any new real-text lag expectations
   require a separately computed fixed oracle, not a research trial.
6. Test declaration bounds, mutation ownership, persistence/review parity,
   malformed stored rows/maps/parameters and no live source/definition dependency.
   Make transform calls fail during analysis and analyzer calls fail during review.
7. Run focused changed RSpec examples, full RSpec and required project lint;
   inspect CLI exact fractions and insufficient rows. No page-55 trial, corpus
   training or source/test implementation is authorized by this planning pass.

## Edge cases

A huge allowed lag on short input yields an explicit zero-comparison row, not an
exception or fabricated zero probability. A single available comparison can
produce 1.0 without supporting a period claim. Letter expansion changes sequence
length and effective offsets. Excluded literals and page joins do not reset lag
counting; provenance is retained even when source IDs are out of current order.

## Out of scope

Repeated n-gram implementation, language models/training/scoring, expected-English
lag curves, statistical hypothesis testing, periodic IoC, candidate ranking or
pruning, automatic key search, new operations, page-55 research trials, migration
services, changes to unrelated YAMLs, pushing and PR creation.

## Open questions and roadmap

No blocking question. The explicit offset list bounded to 64 entries in 1..1024,
whole-checkpoint filtered continuity, descriptive-only output and absence of a
baseline are deliberate v1 choices. Revise limits through an explicit contract
change if actual usage needs it; they are not cryptanalytic thresholds.

Position windows/subranges are deferred to the VERY END of the broader roadmap,
after these separately delivered analyses and other agreed capabilities.
