# Repeated n-gram analysis of saved checkpoints

## Goal

Add descriptive, overlapping repeated-pair and repeated-triple analysis to a
selected saved checkpoint, retaining every occurrence, spacing and source
coordinate. GP-rune sequences are primary; canonical expanded-Latin sequences
are a separately declared representation, never an English language score.

## Baseline and delivery boundary

Inspected local main and origin/main at `e015a88` on 2026-10-28, including merged
Atbash/rune mirroring, continuous page input and saved checkpoint analysis.
This document and `lag-coincidence-analysis.md` describe TWO independent feature
increments, each with its own implementation branch, tests and review. Neither
requires the other or authorizes implementing both together. Refresh touched
interfaces against main when either increment starts; do not assume the sibling
plan's proposed APIs have landed.

No standalone prerequisite refactor is justified. Definition, Runner, Result,
LogEntry, RecordValidator and CLI currently assume symbol-statistics, but their
existing responsibilities permit small explicit analyzer dispatch and separate
measurement types. This is bounded feature integration, not a plugin framework.
Do not grow the IC-specific Result into a bag of optional fields. Keep existing
symbol-statistics behavior and interpretation intact. If implementation reveals
actual structural friction beyond that, stop and invoke planner for a separate
prerequisite rather than silently expanding scope.

Planning changes only these two documents. Preserve the existing untracked
`experiments/definitions/page-54-55-latin-target-baseline.yml` and
`experiments/analyses/totient-symbol-statistics.yml` untouched and unstaged.

## Acceptance criteria

### Declaration and sequence contract

- Add analyzer `repeated-ngrams`, version 1, with required parameters
  `lengths: [2, 3]` and `boundary_policy: continuous-gp-v1`. Accept a nonempty,
  strictly increasing, unique subset of integers 2 and 3 only. Reject booleans,
  strings, floats, duplicates, unsorted values, unknown parameters and versions.
  These bounds are product limits, not scientific thresholds.
- Preserve one or two declarations, unique IDs, unique representations and one
  shared target stage per definition. This increment uses a homogeneous analyzer
  per definition, so the two entries may select GP and expanded Latin separately.
  Existing symbol-statistics YAML remains valid without parameters. Reject mixed
  analyzer families clearly; use separate analysis invocations for other metrics.
- Preserve explicit run ID and target.stage selection: original, final, or a safe
  captured step ID. Use verified retained evidence only, without rerunning any
  transform or reading current source transcription files.
- `continuous-gp-v1` filters to captured GP symbol rows in CURRENT ordinal order.
  Non-GP passthrough text, spaces, punctuation, digits and line breaks contribute
  no symbols and do not interrupt adjacency. Cross-line and cross-page n-grams
  are included, with no invented separator. Source order follows declared page
  occurrences, then transformations; never sort rows by source coordinates.
  This policy is explicit in declaration, retained result and CLI explanation.
- GP uses one element per rune and the existing ordered 29-rune alphabet.
  Expanded Latin uses the existing canonical map split into lowercase characters
  and its 26-letter alphabet; do not scan rendered output or ordinary ASCII words.
  Store the representation and map/profile identity so unlike units cannot mix.

### Exact measurements and positions

- For each requested n and sequence length N, count every overlapping start
  i in 0..N-n. Candidate count is max(N-n+1, 0). Retain only patterns occurring
  at least twice; do not truncate to top-k or enumerate absent alphabet powers.
- Retain each pattern as an ordered symbol array, its count, all occurrences in
  ascending current start-index order, and consecutive start-to-start gaps.
  An occurrence spans [start_index, start_index+n) in the chosen representation;
  gaps have that same unit. Do not silently substitute unoccupied-symbol gaps,
  all-pairs distances, source byte distances or greatest-common-divisor guesses.
- Retain a position map once per result, in current analysis-index order. Each
  position maps to current checkpoint rune ordinal and all original saved source
  coordinates: page_number, occurrence, rune_index, byte_start/end,
  character_start/end, line and column. Preserve the source conventions verbatim;
  current analysis indices are explicitly zero-based, end-exclusive.
- Expanded-Latin positions additionally retain zero-based expansion_offset and
  expansion_length. Several positions may share one source rune; each occurrence
  references its positions through its index span. Thus a pair inside a `th`
  expansion is distinguishable from a pair crossing two source runes. Never
  invent per-letter source-byte spans inside a rune's original encoding.
- Sort length groups ascending, patterns lexicographically by representation
  alphabet indices, and occurrences ascending. Counts, arrays and ties must be
  reproducible independently of hash iteration or locale.
- Store candidate_count, distinct_pattern_count (including singletons),
  repeated_pattern_count, and repeated_occurrence_count (sum of counts for
  retained repeated patterns), with no percentage needed in v1. Candidate count
  is the exact denominator if users compare counts; repeated_occurrence_count
  is not a count of disjoint symbols or a probability.
- If N<n: status insufficient_sample, candidate_count 0, all aggregate counts
  0 and patterns empty. If candidates exist but none repeat: status computed,
  patterns empty and repeated counts 0. Empty input has an empty position map;
  singleton inputs use the same rules. Do not fabricate significance judgments.

### Retention, validation and review

- Append under the existing saved run's analyses directory, retaining exact
  definition bytes/digest, analyzer/version/parameters, representation profile,
  checkpoint selector/resolved UUID/step/ordinal and artifact digests, execution
  identity and immutable result. Version all measurement and boundary semantics.
  New attempts never alter saved observations or older analyses.
- Review displays retained measurements without recalculating or consulting live
  definitions, expansion maps or transformed outputs. Later caller/file mutation
  cannot alter the owned result. Deep-copy before freezing, not caller objects.
- Validate declaration-to-envelope analyzer/version/parameters and result bindings,
  valid alphabets/indices/source-map lengths, positive repeated counts, occurrence
  count/length/order/range, exact gaps, aggregate consistency and canonical order.
  Reject malformed fractions of a representation, missing provenance, altered
  profiles, duplicate JSON keys, unknown versions and contradictory checkpoint
  identities through existing error boundaries. Do not silently repair records.
- Preserve full retained-chain verification, containment, final-projection parity
  and completed/failed-run eligibility already enforced by ObservationReader.
  RecordValidator currently permits only capture/totient/latin operations: add
  parity for already-supported atbash and reverse-runes checkpoints, with existing
  operation/parameter/policy validation authoritative. This is not a new operation.
- CLI clearly labels sequence repetition, candidate count, overlap, boundary
  policy, representation units, pattern counts, all starts/gaps and source map.
  No language-like/not-language-like score: repeated structures can be useful
  in ciphertext. Canonical digraphs are representation effects, not evidence of
  English. Frequency/IC evidence and ordered-sequence evidence remain distinct.
- A bijective GP symbol relabeling preserves repetition counts and occurrence
  starts but changes labels. Full reversal reverses pattern labels and maps
  occurrence starts; it preserves the distribution of pattern counts. Neither
  invariant establishes plaintext, correct direction or a useful key.

## Approach

- `lib/primus/analysis/definition.rb`: bounded analyzer-specific parameter
  validation alongside unchanged symbol-statistics contract; no arbitrary dispatch.
- `analysis/observation_reader.rb` and `observation.rb`: expose an owned sequence
  with position mapping built from already-verified checkpoint symbols_rows.
  Keep verification in Experiment::CheckpointEvidence; do not reopen artifacts
  or duplicate its source-lineage checks. Use a focused noun-named sequence value
  if needed, not a public graph of raw nested hashes or one object per scalar.
- Add `analysis/repeated_ngrams.rb` and an owned `repeated_ngram_result.rb` for
  counting and result queries. Preserve current `result.rb` IC/frequency API.
  Runner selects the declared analyzer explicitly; only symbol-statistics uses
  ICReferencePacket and ICInterpretation. Commands perform work then return nil;
  query methods return values without I/O.
- `analysis/log_entry.rb`: construct/restore the correct measurement type and
  envelope from retained declaration identity; remove hardcoded analyzer only
  at that boundary. `record_validator.rb`: shared identity validation followed
  by focused analyzer-specific validation (separate validator file if warranted).
  `commands/analyses.rb`: explicit analyzer rendering, with a focused presenter
  if necessary to keep methods near five lines and avoid growing classes.
- `analysis/store.rb` retains append/read mechanics; test new record round trips
  rather than introducing a second store. No new generic framework, Rails
  dependency, migrations, legacy reader or deletion of old evidence.
- Extend definition/reader/observation/runner/log_entry/record_validator/store
  specs and command specs; add analyzer/result specs and a literal independent
  oracle under `spec/fixtures/analysis/repeated_ngrams_oracle.md`.
- Add a dedicated example `experiments/analyses/repeated-ngrams.yml` and README
  usage during implementation. Leave pre-existing user definitions unchanged.

Example definition (new file in implementation, not created by planning):

```yaml
schema_version: 1
id: repeated-ngrams
analyses:
  - id: rune-repeats
    analyzer: repeated-ngrams
    version: 1
    parameters:
      lengths: [2, 3]
      boundary_policy: continuous-gp-v1
    target:
      stage: original
      representation: gp-runes-v1
```

```sh
bin/primus analyses run EXPERIMENT_ID RUN_ID --definition experiments/analyses/repeated-ngrams.yml
bin/primus analyses review EXPERIMENT_ID RUN_ID ANALYSIS_RUN_ID
```

## Independent controls and validation order

1. Hand-work `AAAA`: pairs AA at [0,1,2], count 3, gaps [1,1],
   candidates 3; triples AAA at [0,1], count 2, gap [1], candidates 2.
   `ABABA`: AB at [0,2], BA at [1,3], ABA at [0,2]; triple BAB is
   singleton and omitted. Use real GP A/B rune fixtures for integration.
2. Pin empty, singleton, N=n and no-repeat cases independently. Test invalid
   lengths/parameters, mixed analyzers/stages and deterministic ordering.
3. Literal GP `ᚦᚪᚦ` gives three runes, no repeated pair/triple; expanded
   `thath` gives repeated th at [0,3], gap 3, with offsets 0/1 of source
   rune ordinals 0 and 2. Each th is within one rune, not two adjacent runes.
   Contrast `ᛏᚻᛏᚻ` -> `thth`: repeated th spans distinct source runes.
4. Add whitespace, CRLF, punctuation, ASCII and page boundaries; show they do
   not break filtered adjacency. Use repeated page occurrences, declared pages
   in nonnumeric order and reversal so original source IDs do not increase
   with current indices. Assert literal byte/character/source mappings.
5. Retain original, totient, atbash, reverse-runes and final captures in a tiny
   chain; assert literal oracles per stage, final/named alias identity behavior
   and GP relabeling/reversal properties. Expanded-Latin reversal need not equal
   character reversal, because a rune's expansion retains its internal order.
6. Pin round trips, immutable ownership, corrupted evidence/records and review
   with unavailable live source/definition; prohibit transform/analyzer calls
   during review. Production analyzer, parser or serializers cannot generate
   their own expected values. Existing solved pages 56/57 remain regression
   controls; any added real-text expectations require an independent oracle.
7. Run focused changed RSpec examples, then full RSpec and required project
   lint checks; inspect relevant CLI output. No page-55 research run is needed.

## Edge cases

Repeated overlaps are intentional; sources may be reordered, repeated, mirrored
or separated by omitted literals. Current coordinates never substitute for
original ones. Canonical expansions can change N and create repetition absent
in GP. Very repetitive input retains all starts; output size is linear per
requested length, and consecutive gaps avoid quadratic all-pairs output.

## Out of scope

English corpus/training/frequency tables, language likelihood, ranking/pruning
intermediates, new transformations, key search, periodic IoC, lag coincidence
implementation, significance/confidence thresholds, automatic research runs,
input/output migrations, source edits during planning, push and PR creation.

## Open questions and roadmap

No blocking choice remains for this bounded v1. The fixed n set, continuous
filtered boundaries, consecutive start gaps, explicit parameters and homogeneous
analysis definitions are deliberate product choices. Revisit through an explicit
versioned change if later research needs additional lengths or boundary modes.

Position windows/subranges belong at the VERY END of the broader roadmap, after
these separately delivered sequence analyses and other agreed capabilities.


## Review amendment: readable CLI output (2026-11-02)

### Goal and delivery boundary

Finish this increment with readable descriptive output for repeated n-grams.
This amendment supersedes the earlier requirement to print every start, gap and
source-map entry by default; complete evidence remains saved and accessible.
Continue on `codex/repeated-ngram-analysis` from inspected HEAD `4f469c1`.
No prerequisite refactor is warranted: the existing RepeatedNgramPresenter owns
this presentation, and Analyses already routes both run and review through it.
Preserve the unrelated working change to `experiments/analyses/repeated-ngrams.yml`.

### Acceptance criteria

- Default run and review identify the analysis/checkpoint and show a separate
  section for each retained representation, with its sample size N and units.
  For every requested n, show the existing candidate count, distinct pattern
  count, distinct repeated-pattern count and repeated occurrence count. Label
  the latter as overlapping occurrences, not disjoint coverage or probability.
  Use saved aggregates; do not add scientific measurements.
- Each n has a human-readable table of at most 10 repeated patterns with columns
  pattern, count, starts and consecutive start-to-start gaps. Show at most the
  first 8 values in each starts/gaps cell, followed by an explicit omitted-value
  count when needed. These are display limits, not analysis thresholds.
- Rank displayed patterns by descending saved count; ties retain their saved
  canonical alphabet order. Sort a presentation copy, never the retained arrays.
  GP patterns remain rune sequences; expanded-Latin patterns are labeled as
  letters, never implicitly treated as adjacent GP runes. No new transliteration
  lookup is needed for historical rendering.
- Explicitly distinguish insufficient sample (N<n) from a computed result with
  no repeated patterns. Neither renders an empty table without explanation.
- When rows or values are omitted, say so with the omitted count. Default output
  never dumps the position map. Every repeated-ngram entry points to its complete
  saved `analyses/ANALYSIS_RUN_ID/record.json` under the chosen output root and
  explains that `--details` reveals full patterns and source coordinates.
- Add the same boolean `--details` (default false) to `analyses run` and
  `analyses review`. It controls presentation only: full mode prints every
  repeated pattern, every start/gap and every indexed source-map entry including
  all retained coordinates and Latin expansion offsets/lengths. Use readable
  labeled fields rather than raw Ruby hash inspection. Preserve the relation
  between occurrence spans and indexed source rows. Keep the same frequency/tie
  ordering in both display modes. No new definition parameter or saved field.
- Retain a short boundary/overlap explanation, zero-based current indices and
  end-exclusive spans in representation units. Expanded Latin also states that
  canonical expansions can create repeats within one source rune; such repeats
  are not evidence of English or of an improved decryption. Do not classify
  individual patterns or calculate expansion-derived statistics in this change.
- Existing saved analyses render through both modes without recomputation,
  current source files or current expansion-map lookup. Full evidence and saved
  canonical ordering remain unchanged. Symbol-statistics output stays unchanged;
  its help may explain that the details option applies to repeated n-grams.

### Approach

- `lib/primus/commands/repeated_ngram_presenter.rb`: implement the bounded
  overview, display ordering, explicit empty statuses and readable full-detail
  rendering. Keep formatting here; no analyzer/validator/schema changes.
- `lib/primus/commands/analyses.rb`: declare both options, pass the display choice
  to the presenter and provide the artifact pointer using existing entry identity
  and output path. Preserve existing provenance/checkpoint headers and normal
  symbol-statistics rendering; avoid a broad command framework refactor.
- `README.md`: document the default overview, fixed display limits and both
  detailed run/review invocations. Explain full retained data is never truncated.
- `spec/lib/primus/commands/repeated_ngram_presenter_spec.rb` (new if useful):
  independent literal result fixtures for summaries, row and cell limits,
  exact-limit versus over-limit cases, descending frequency/canonical ties,
  no-repeat/insufficient/empty cases, both representations and full source detail.
- `spec/lib/primus/analysis/repeated_ngrams_integration_spec.rb`: revise the
  existing output example that currently requires source maps in default output;
  add focused command coverage of default and detailed run/review parity and
  artifact pointers with custom output roots (including spaces). Review an
  existing-format record with live definition/source unavailable and prohibit
  analyzer execution during review. Assert record bytes unchanged after review;
  assert a default run still retains patterns/positions omitted from its display.
  Compare retained result data across presentation choices, excluding naturally
  different execution IDs/timestamps, rather than requiring identical new runs.
- Tests should isolate one behavior per example with literal expectations for
  counts/order/coordinates. Assert useful labels and omissions without coupling
  to exact prose, padding or a snapshot of the whole terminal transcript.
  Retain existing symbol-statistics command regression coverage.

### Edge cases and validation

Handle exactly 10 versus 11 rows, exactly 8 versus 9 values, unequal starts/gaps
lengths, ties, N=0, N=n, and multiple declarations/analyses in one review.
Truncation counts apply to each array independently. Unicode rune widths must
not erase column boundaries; a simple delimited table is adequate. A Latin
occurrence can map several indices to the same source rune; details preserve
those separate indexed rows. Neither rendering mutates frozen result values.

Run focused presenter/integration and existing analysis command specs, then the
full suite and required project lint checks. Inspect representative synthetic
CLI output for each mode. Do not create research runs or modify saved artifacts.

### Out of scope and open questions

No blocking questions remain; 10 rows, 8 values and `--details` are deliberately
small presentation choices. No stage comparisons, new observations, statistical
significance, English scoring, cipher classification, lag implementation,
pattern-specific interpretation, new measurements or configurable report system.
Comparisons and observations belong to the next phase after this increment is
closed. Planning ends with a docs-only WIP commit; test writing and implementation
are separate pipeline steps. No push, PR creation or squash is part of planning.
