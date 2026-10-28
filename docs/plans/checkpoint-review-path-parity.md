# Checkpoint review path parity

## Goal

Make the review command printed after a successful experiment work with the
normal relative output directory, including its default, just as the equivalent
absolute path works. Preserve all saved evidence and strict artifact containment.

## Diagnosis and scope

Inspected `codex/atbash-rune-mirroring` at `83ccd99` on 2026-10-26. Continue on
this branch as requested. No prerequisite refactor is needed: normalization at
the evidence object's input boundary fixes the inconsistent representation.
Planner uses the existing Rails best practices and commit/PR guidelines.

The reported Warning control run `20261026T201851-fb43fedfee60` matched, but
review with `--output-path experiments/runs` reports checkpoint path mismatch.
The parent verified that absolute-path review of that same saved run succeeds.
Store snapshots record absolute artifact paths, while Store.review passes a
relative record path through to CheckpointEvidence. Its constructor retains
that relative spelling, so artifact verification compares absolute metadata
against a relative expected path. The resolved containment path is already
absolute, but the first equality fails before that check helps.

The same retained record-path assumption occurs in CheckpointEvidence's
`artifact`, `verify_original` (source-body.txt), and `verify_final` (output.txt).
OrderedSourceEvidence receives that path and uses it for each original YAML/body
artifact. All must share the corrected boundary, not just the first checkpoint.
ObservationReader already expands its recorded directory; avoid unrelated changes.

## Acceptance criteria

- A software-control run created through the normal command path prints a review
  command which can be executed successfully as printed. Exercise a relative
  output directory, not only the absolute temporary directory helpers normally
  return. Assert the saved match status and same run identity are shown.
- Review of the same retained run through the default output directory, explicit
  relative output directory and equivalent absolute output directory succeeds
  with equivalent evidence/results. Test default handling in an isolated temporary
  working directory containing the appropriate saved software fixture; never
  replace, rerun or edit the user's existing Warning attempt.
- Cover both single-page checkpoint evidence and an ordered two-source control,
  so original aggregate, per-member YAML/body, intermediate and terminal artifact
  validation all succeed through a relative record path. These are software tests,
  not new research trials or new cryptographic controls.
- Artifact metadata must still name the exact expected artifact under the run
  directory. Preserve realpath containment, checksum/byte-count verification,
  source identity, lineage and terminal linkage checks. Wrong/sibling paths,
  tampered bytes and artifact symlinks escaping the run still reject; do not
  normalize or rewrite persisted metadata to manufacture acceptance.
- Review remains read-only: saved record and artifact bytes/checksums are unchanged
  after successful relative and absolute review. Missing/corrupt evidence retains
  existing honest error behavior. Existing absolute-path review remains covered.

## Approach

First add a failing command-level regression in the existing experiments command
specs, following the printed review command against a saved software-control run.
Add focused CheckpointEvidence coverage using a relative record path; exercise
ordered-source evidence where the common helper currently hides the bug with an
absolute temporary root. Reuse existing security/tamper examples and add only a
missing relative-path escape check if needed.

Then normalize the caller-supplied record path once with File.expand_path in
CheckpointEvidence's initialization boundary. Derive its real directory from that
owned absolute path and pass the normalized path to OrderedSourceEvidence. Keep
exact metadata equality separate from realpath containment; do not substitute a
basename check, remove checks, or resolve away the metadata spelling contract.
Only change OrderedSourceEvidence separately if a direct supported caller needs
the same boundary guarantee. Do not fix this solely by printing an absolute CLI
command, because default relative Store.review must work too.

Run the focused new regressions, checkpoint evidence/ordered-source and existing
experiment command specs, then required project checks. After code checks pass,
read-only review of the reported retained Warning run via the user's original
relative command and equivalent absolute command verifies the actual symptom;
do not execute the experiment again. Report observed checks, not inferred passes.

## Edge cases

Relative paths with leading `./`, absolute paths, default directory selection,
spaces in a directory name, source-manifest artifacts and partial chains. The
working directory supplies the normal meaning of relative input paths. This
change does not promise portability after moving a run, reinterpret old artifact
metadata, or broaden accepted symlink arrangements.

## Out of scope

Transform changes, plaintext/hash reassessment, research execution, saved-run
mutation/migration, general path framework, output-directory relocation support,
new CLI options, push or PR. Planner changes this document only and makes its
required local WIP commit; test-writer and implementer handle tests/source next.

## Open questions

None blocking. The requested fix and existing absolute artifact-path contract
provide a narrow implementation with no need for another user decision.
