# Follow-on: page 56 through the experiment harness

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

## Goal and gate

Use the merged page-57 harness to define, validate, run, save and review a
page-56 experiment against independently known plaintext. This is a separate
second milestone, not current implementation scope. Invoke planner fresh
after [page 57](page-57-experiment-harness.md) merges; inspect actual interfaces
before writing detailed acceptance criteria or source/tests.

## Bounded intent

Add a saved page-56 definition and independent expected text using the same
run/review lifecycle. Enhance only what this experiment requires: existing
TotientShift before Latin rendering, with explicit parameters and fresh state.
Reuse Builder/Translator/TotientShift rather than introduce new algorithms.

The known recipe subtracts successive prime minus one modulo 29, starting
at prime 2; skip zero-based GP processing ordinal 56 without consuming a
prime. Non-GP characters do not consume steps. Preserve punctuation, the
hexadecimal block and all source provenance. Rune 56 remains `f`, rune 57
becomes `e` using prime 269; validate this independently of a full-text match.
Internal rune-to-GP mapping is representation preparation, not an extra
cipher layer. Clarify the operation configuration against the merged harness;
do not commit now to a general chain interface or registry.

## Completion evidence to refine after the gate

One reviewed saved definition/oracle; exact expected Latin output; recorded
configuration/integrity/correctness checks; retained source/output/provenance;
fresh state across repeated page-56 and page-57 runs; intentional rerun and
review behavior unchanged. The harness's own RSpec coverage demonstrates the
extension, while the research experiment remains outside RSpec.

## Out of scope and open decisions

No general pipeline, hashes, new cipher, search, cross-page resets or broad
cleanup. Determine only the smallest necessary configuration extension after
page 57 merges; fixture byte policy should reuse the agreed page-57 policy
unless a concrete difference requires a named alternative.

## Next

After this milestone merges, invoke planner for
[synthetic hash validation](synthetic-hash-experiment.md). This is explicitly
the third milestone; an extra synthetic two-cipher project is not a gate.
