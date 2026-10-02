# Consistent experiment ID arguments

## Goal

Use an experiment ID consistently for validate, run, and review, resolving
live definitions from `experiments/definitions/<id>.yml`. This is a separate
change from direct executable startup; implement it in its own handoff after
that change, reconciling this plan against the then-current code.

## Acceptance criteria

- `experiments validate page-56-totient-latin` and its page-57-latin equivalent
  load their conventional definitions, succeed, and write no attempt.
- `experiments run ID` loads the same definition and retains a matching attempt
  from a clean checkout; output-path, reuse, rerun, and reason semantics remain.
- `experiments review ID [RUN_ID]` retains optional run selection and planned
  display. Historical attempts remain reviewable when the live definition is
  missing or invalid.
- All three commands consistently reject path-like IDs: absolute paths,
  slash/backslash, traversal, and .yml filenames. A small lexical ID rule
  prevents IDs from accessing outside definition/history directories.
- Unknown well-formed IDs fail validation/run. A failed run load still records
  an invalid attempt with the resolved definition path. Malformed YAML and
  model-invalid definitions retain meaningful failure categories/statuses.
- Help and README consistently show ID arguments. Thor retains its existing
  handling of missing required arguments.
- The library's `Primus::Experiment.load(path: ...)` still accepts explicit
  file paths for consumers and fixtures.

## Approach

- `lib/primus/commands/experiments.rb`: accept IDs for validate/execute and
  resolve their conventional paths in one small place, also used for planned
  review. Validate ID syntax at the CLI boundary. Review retained history
  before loading live definitions. Retain the resolved path for failed-load
  recording. Keep focused helpers, the five-line method heuristic, and Law of
  Demeter in mind; avoid forwarding wrappers or a generic registry.
- `spec/lib/primus/commands/experiments_spec.rb`: replace CLI fixture paths
  with IDs. Prepare malformed/mismatching definitions in an isolated checkout
  under the conventional directory. Cover public signatures, statuses,
  records, optional run selection, and history without a live definition;
  avoid exact error-prose coupling and use full class names where relevant.
- `spec/features/page_57_experiment_identity_spec.rb`: migrate subprocess
  arguments to IDs. Helpers currently mutate a fixture definition; change
  them to mutate the definition actually selected by the ID so source-change
  and integrity assertions remain meaningful.
- `README.md`: use IDs in all experiment examples and explain the CLI/API
  distinction. Preserve the executable invocation style established by the
  independent startup change.
- No preparatory refactor is needed. Do not modify bootstrap as part of this
  work; inspect the merged startup implementation at handoff and reuse it.

## Verification

Run focused CLI and execution-identity specs, then the full suite. Clone-based
specs exercise committed HEAD and the runner rejects dirty executable files;
perform final verification from the clean authorized implementation commit.
Do not disable or stub provenance checks to pass tests. Exercise both saved
IDs and rerun/review with temporary output directories. Keep library tests
using explicit paths where that is their intended contract.

## Edge cases

- Reject unsafe syntax before filesystem access; a valid but unknown ID may
  resolve to a missing file and follow normal failed-load handling.
- Do not normalize IDs or add an implicit path compatibility fallback.
- Review's output-path and optional RUN_ID semantics stay unchanged; history
  cannot acquire a dependency on current definition validity.
- Isolated test definitions must have the identity appropriate for the ID
  being exercised, preserving existing model validation.

## Out of scope

Executable/bootstrap changes, dependency upgrades, arbitrary-working-directory
support, installed-gem distribution, new experiments, definition registries,
Ruby API signature changes, broad refactors, and provenance changes.

## Open questions

None blocking. Deliberate choice: ID-only CLI with explicit paths retained in
its Ruby API. This plan is independently actionable but its implementation
handoff should follow and account for the separate startup change.
