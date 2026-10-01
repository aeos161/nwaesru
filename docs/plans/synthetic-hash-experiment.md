# Follow-on: synthetic experiment with a hash expectation

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

After [page 56](page-56-harness-experiment.md) merges, invoke planner fresh
against the actual harness. Define a small synthetic experiment whose saved
expectation is a known hash of controlled output bytes rather than a
plaintext fixture. This is the third milestone, separate from pages 57/56.

## Bounded intent

Keep define, validate, run, artifact retention and review unchanged. Add only
the expectation behavior needed to compare exact produced bytes with an
independently established digest. Choose a tiny known input and existing
transformation; no two-cipher chain is required to prove hash validation.
Use an explicitly named algorithm and output-byte policy. SHA-512 from the
standard library is a reasonable first proposal, to confirm during fresh
planning; the synthetic oracle is independently computed/checked, never
self-generated from the candidate during execution.

Save actual output bytes, expected and observed digest, algorithm/policy and
comparison result. Demonstrate both match and a controlled one-byte mismatch,
plus invalid configuration and unavailable/error handling. Keep file-identity
SHA-256 separate from this scientific expectation. RSpec verifies the added
comparison behavior; the synthetic scenario is a saved research definition.

## Completion evidence to refine after the gate

The existing harness can define/run/validate an output against plaintext or a
specified digest, retaining inspectable artifacts and honest status/history.
A synthetic match verifies those controlled bytes and the software path; it
does not validate an interpretation of the Liber Primus hash.

## Out of scope and open decisions

No automatic algorithm discovery, BLAKE dependencies, generic hash-adapter
framework, search or mandatory layered cipher example. Choose the synthetic
input, independent vector and exact byte policy when re-planning. Only add a
second algorithm or stage if the concrete experiment demonstrates a need.

## Later page 55 research

Then separately plan saved page-55 experiments using the target quoted on
page 56 as a hypothesis. Its algorithm, serialization and relation to page-55
plaintext are uncertain. A 128-hex-character value alone establishes none of
those. Declare each assumption; a mismatch rejects only that tested byte/
algorithm combination. Recheck transcription and verified algorithm support
before execution. The synthetic oracle is controlled truth; this target is
an uncertain historical interpretation. Preserve that distinction in records
and conclusions. Broader search/layering remains separately bounded work.
