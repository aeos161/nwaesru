# Superseded: reproduce Liber Primus pages 57 and 56

The fixed `Primus::Reproduction` two-recipe adapter proposal in commit
`a0d3de1` is superseded. Do not implement its combined scope or its exclusions
of persistence/experiment definitions.

The page-57 harness is implemented at `45cab84` and present on local main
as of 2026-10-01; remote publication was not inferred. Current actionable
plan: [page 56 through that harness](page-56-harness-experiment.md), reconciled
against the actual implementation. Research definitions remain outside
RSpec; RSpec verifies the harness.

The delivery sequence is now:

1. Page 57 harness and plaintext experiment — implemented at `45cab84`.
2. [Page 56 using that harness](page-56-harness-experiment.md) — reconciled
   plan ready against the locally integrated first milestone.
3. [Synthetic hash expectation](synthetic-hash-experiment.md), separately
   re-planned after page 56 merges.
4. Page 55 experiments against a declared real target-hash hypothesis.

The broader [research direction](page-54-55-research.md) remains deferred.
Earlier synthetic two-cipher and general-chain proposals are research ideas,
not the next mandatory deliverable.

The approved harness vocabulary is Experiment (`ActiveModel::Model`) for
saved definition/preconditions, Observation for actual output, Assessment for
evaluation against the declared expectation. The approved LogEntry describes one attempt, separate from scientific
output; Store owns history lookup/review. Runner exposes `log_entry`, not
an ExperimentLog or a history collection.
Runner takes an Experiment and `output_path`, executes as a nil-returning
command, and exposes domain readers. Invalid preconditions produce model
errors and no Observation; failed-attempt history is separate. Follow-on
plaintext/hash evaluation extends Assessment behavior, not model validation.
The page-57 plan governs the concrete API; this record adds no implementation
scope before its existing gate.
