# CLI experiment discoverability

## Goal

After a named preset or ad-hoc single-check run returns a retained record,
show its experiment ID, run ID, and an exact command for reviewing that
attempt. Keep this a small, standalone CLI change.

## Baseline and scope

On 2026-10-07, local `main`, `origin/main`, and a live remote main lookup
all resolved to `0fdbc9acc180280669caebe3b3b247f033b70b5b` (Compose
single-check experiments from CLI or YAML). The working tree was clean.
The user reports the full suite passing on main; that is the current
baseline. No tests were run during this documentation-only planning step.

`docs/plans/composable-experiments.md` supplies wider context, but this
plan covers only discoverability on the merged single-check feature.
There is no prerequisite refactor: `Runner#log_entry` and `LogEntry#data`
already expose the saved identity. Existing command formatting methods
provide a suitable home for this modest addition.

## Acceptance criteria

- Keep the existing first stdout line exactly as it is:
  `<run_id>: <status> (<comparison>)`. Append these lines once, in order:

  ```text
  experiment ID: <experiment_id>
  run ID: <run_id>
  review: bin/primus experiments review <experiment_id> <run_id> --output-path <path>
  ```

  Angle-bracket values denote actual values, never printed placeholders.
  Include `--output-path` even for the default `experiments/runs`, making
  the target store explicit. The text after `review: ` is copyable.
- A named version-one preset, named version-two YAML composition, and
  ad-hoc CLI composition all print identities from the returned record.
  Ad-hoc output includes its generated `ad-hoc-...` experiment ID; it
  never substitutes the missing positional preset ID.
- The review command contains both identities and selects that exact
  attempt, including when multiple attempts exist. It works from the
  same working directory as the original run, using the direct
  `bin/primus` entrypoint, without a `bundle exec` prefix.
- Preserve the supplied output-path value, whether relative or absolute.
  Shell-escape command arguments with Ruby's standard `Shellwords`
  facilities for POSIX shells, including spaces, apostrophes, dollar
  signs and semicolons. Do not interpolate an unescaped path, assume a
  particular user directory, expand shell syntax, or change storage
  location. Default simple arguments remain readable and unquoted.
- Existing version-one deduplication prints the identity of the returned
  prior record, so its review command selects that prior attempt. A
  forced rerun prints its new attempt ID. Do not introduce reuse for
  version-two runs or change any fingerprint/deduplication behavior.
- When the runner returns an entry with `mismatched`, `invalid`, or an
  already recorded `error` status, print the same discoverability lines
  before the existing Thor error path. Preserve existing comparison text,
  error messages, output streams, and exit statuses. Matched runs remain
  successful; existing unsuccessful cases remain unsuccessful.
- Failures before a runner returns a record retain their current error
  behavior and do not print invented IDs or a review command. In
  particular, do not promise a reviewable experiment for failed loading:
  its separate failed-load storage has no experiment ID. Leave exception
  rescue paths unchanged, including execution exceptions that currently
  bypass the normal summary even if the runner recorded an error.
- `validate` and `review` output and behavior remain unchanged.

## Approach

- `lib/primus/commands/experiments.rb`: retain the existing status line
  and failure decision in `#execute`; call a small private display helper
  with the returned entry. Read `entry.data.fetch("experiment_id")` and
  `entry.run_id`, and format the review argv using `Shellwords.join`.
  Use the command's existing `options[:output_path]`. Explicitly require
  the standard library if it is not already required at this boundary.
  Do not reach through runner internals or add forwarding APIs: the
  owned entry's existing public data is already used throughout this CLI.
- `spec/lib/primus/commands/experiments_spec.rb`: add focused CLI-boundary
  coverage for the literal labels/order, default path, custom path,
  deduplicated and forced attempts, mismatch/invalid results and failures
  without a returned entry. Use existing error examples as regression
  coverage rather than duplicating them wholesale.
- `spec/lib/primus/commands/experiments_composable_spec.rb`: cover generated
  ad-hoc identity and named v2 identity, and review the exact retained
  attempt using the printed command arguments.
- `README.md`: add one short run-output example and explain copying the
  `review:` line's command from the same working directory. Document
  explicit output-path preservation without broadening the CLI guide.

### Test-writer handoff after human review

Keep fully namespaced `RSpec.describe Primus::Commands::Experiments`
groups and method groups (`#execute`, with `#review` only where it is
actually the behavior exercised). Use no `let`; each example has one
behavior, one expectation and explicit setup/exercise/verification
spacing. Assertions on labels and command syntax use literal text, while
unpredictable IDs come independently from the persisted record, never
from the display helper under test.

Prove the user journey at the existing subprocess boundary: run an
experiment, extract the text after `review: `, split it into argv, invoke
the CLI from the original working directory, and verify review identifies
the intended saved attempt. Use a path containing spaces and shell
metacharacters to pin argument preservation, plus a literal escaped
command expectation so parsing alone cannot hide unsafe shell syntax.
Use separate examples for status, diagnostics and reviewability instead
of bundling unrelated outcomes in one assertion. Cover named v1, named
v2 and ad-hoc dispatch without repeating an algorithm matrix.

Existing subprocess helpers clone committed code, and Runner rejects
uncommitted executable changes. Follow the pipeline's authorized WIP
commit workflow so exercised clones contain the revision being tested;
do not disable code-clean checks or mistakenly test the pre-change clone.

Run targeted experiment CLI coverage at implementation start and after
changes, then touched-code lint and the full suite for final regression
validation. Use the project's configured Ruby and existing test invocation.
Any actually observed test failure must be logged in root `flaky-specs.md`
with command, Ruby/runtime, revision and working-tree state, spec/example,
failure text, and reproduction/retry results. Label it an observed failure,
not proven flakiness; separate expected new-feature TDD reds from unrelated
failures. Carry this logging instruction through every subsequent handoff.
Do not revive historical failures as current facts or create an empty log
when none were observed. The user explicitly authorizes this logging
exception to the planner's docs/plans-only restriction if needed.

## Edge cases

- Returned prior entries, including unsuccessful entries, are real history;
  never imply a newly executed attempt merely because `run` was invoked.
- A relative output path remains relative to the original working directory;
  relocation and commands runnable from arbitrary directories are not promised.
- Storage failures or missing/invalid input must not gain a misleading
  success message, empty-ID command, or changed exception semantics.
- Printing IDs must not consult current preset contents or recompute the
  ad-hoc digest: the retained entry is the authoritative identity.

## Out of scope

Multiple checks, reassessment, cross-experiment observation reuse, new
storage APIs or schemas, a generic presenter/formatter framework, unrelated
CLI cleanup, failed-load recovery, new platforms' shell dialects, and
changes to cryptographic or experiment execution behavior. This planning
step writes no implementation or tests and opens no PR or push.

## Open questions

None blocking. The proposed lowercase labels, preserved first status line,
and always-explicit output path are concrete choices for human review.
Stop after the plan's WIP commit; do not hand off to test-writer until the
user has reviewed this plan.
