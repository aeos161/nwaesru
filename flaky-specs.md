# Observed test failures

## 2026-10-10: saved-output statistics TDD and integration

On `codex/saved-output-text-analysis` at clean test-head `6473f8b`, MRI
Ruby 2.7.4p191, Bundler 2.1.4 and `RUBYOPT=-EUTF-8`, the focused command
`bundle exec rspec spec/features/analyze_saved_output_spec.rb
spec/lib/primus/experiment/final_symbol_manifest_spec.rb
spec/lib/primus/analysis/symbol_statistics_spec.rb` reported 51 examples,
51 expected new-feature failures (seed 21185). The producer lacked the
representation manifest and the analysis classes and CLI were absent. These
were TDD reds, not observed flakiness.

After the first producer/statistics checkpoint `7573144`, the 20 corresponding
examples passed with zero failures (seed 21896). Producer-backed feature
examples run while implementation files were dirty recorded invalid
observations under the existing executable-code-clean guard; those failures
were a known fixture precondition, not stochastic behavior. Once the code was
committed, the focused feature run had one remaining failure (31 examples,
seed 46250): the output byte-count rejection message said `byte count` where
the literal expectation matched `bytes`. Commit `2dc402e` corrected that
message. The full focused command then passed 51 examples, zero failures
(seed 14238), and passed again after review hardening at `33fd9eb` (seed
56335). No unexpected or reproduced flaky failure was observed.

The full suite at clean implementation revision `2dc402e`, with the same Ruby
and UTF-8 setup, passed 659 examples, zero failures and 12 existing pending
(seed 44449). The final full-suite retry at clean implementation revision
`33fd9eb` also passed 659 examples, zero failures and 12 existing pending
(seed 30514). No new failure remains.

## 2026-10-08: reusable totient implementation baseline

At clean revision `05b3bbb`, MRI Ruby 2.7.4 with `RUBYOPT=-EUTF-8`,
`bundle exec rspec spec/lib/primus/experiment_composable_spec.rb spec/lib/primus/experiment/runner_spec.rb`
reported 52 examples, 16 expected new-feature failures, seed 5362. The
model rejected the new `totient-latin` recipe or left its parameters
uncanonicalized; runner examples therefore recorded invalid attempts with no
observation or assessments. No unrelated failure was observed in this focused
baseline. The prior clean `673942b` full-suite baseline reported 608 examples,
27 expected new-feature failures and 12 pending, seed 64904; the later
`05b3bbb` literal fixture correction has not yet had a full-suite retry.

During implementation at revision `849a2e0` with dirty `lib/` files,
`RUBYOPT=-EUTF-8 bundle exec rspec spec/lib/primus/experiment_composable_spec.rb spec/lib/primus/experiment/runner_spec.rb`
reported 52 examples, 22 failures, seed 32986. Runner attempts were invalid
because its executable-code-clean guard detected those uncommitted source
changes; they did not exercise the new derivation. After committing the
source changes at `55a3061`, the model, runner and CLI focused command passed
97 examples, zero failures, seed 18059.

The full suite at clean revision `ade0d8e` with MRI Ruby 2.7.4 and
`RUBYOPT=-EUTF-8 bundle exec rspec` passed 608 examples, zero failures and
12 existing pending, seed 38613. The named v2 page-56 control completed with
four matches, zero mismatches and zero errors; its saved review confirmed the
same result. The unchanged v1 page-56 control matched. No unrelated or
unclassified failure remains. Bundled RuboCop was unavailable; the installed
standalone version rejected the repository's obsolete Performance and Rails
cop configuration before checking any files.

## 2026-10-07: expected discoverability TDD reds

These were **expected new-feature failures**, not evidence of flaky tests or
failures on `main`. They were observed before the CLI implementation at
revision `80a6090aaa5a6f9f69434a170208deb61a8831ec` with a clean working
tree. Runtime: MRI Ruby 2.7.4p191 (arm64-darwin21), Bundler 2.1.4. Command:

```shell
PATH="$HOME/.asdf/shims:$PATH" bundle exec rspec spec/lib/primus/commands/experiments_spec.rb spec/lib/primus/commands/experiments_composable_spec.rb
```

Result: 60 examples, 13 failures, randomized seed 54260. Failure text is
condensed below, preserving each failed expectation or exception:

| Spec and example | Observed failure text |
| --- | --- |
| `experiments_composable_spec.rb:114` named v2 identity | Expected stdout to include `experiment ID: page-57-composed`; got only the status line. |
| `experiments_composable_spec.rb:98` ad-hoc printed review | `NoMethodError: undefined method 'delete_prefix' for nil:NilClass` because no `review: ` line was found. |
| `experiments_composable_spec.rb:128` v2 second-attempt review | `NoMethodError: undefined method 'delete_prefix' for nil:NilClass` because no `review: ` line was found. |
| `experiments_composable_spec.rb:86` generated ad-hoc identity | Expected stdout to include `experiment ID: ad-hoc-5e452dc048bb111e`; got only the status line. |
| `experiments_spec.rb:233` deduplicated run ID | Expected stdout to include `run ID: 20261007T221633-a77421486fbf`; got only the status line. |
| `experiments_spec.rb:185` default output store | Expected stdout to include `review: bin/primus experiments review page-57-latin 20261007T221634-53bd0f016f37 --output-path experiments/runs`; got only the status line. |
| `experiments_spec.rb:245` forced rerun ID | Expected stdout to include `run ID: 20261007T221637-e4050d209da2`; got only the status line. |
| `experiments_spec.rb:282` returned recorded error ID | Expected stdout to include `run ID: 20261007T221637-9aa511130c0c`; got only the status line. |
| `experiments_spec.rb:212` v1 printed review | `NoMethodError: undefined method 'delete_prefix' for nil:NilClass` because no `review: ` line was found. |
| `experiments_spec.rb:168` identity and command order | Expected three lines after status (`experiment ID`, `run ID`, `review`); got `[]`. |
| `experiments_spec.rb:270` invalid-result identity | Expected stdout to include `experiment ID: page-57-latin` and the retained `run ID`; got only the status line. |
| `experiments_spec.rb:258` mismatch identity | Expected stdout to include `experiment ID: page-57-latin` and the retained `run ID`; got only the status line. |
| `experiments_spec.rb:197` shell-escaped custom path | Expected review line containing `runs\\ with\\ spaces/it\\'s\\ \\$money\\;done`; got only the status line. |

Reproduction: the single baseline run above reproduced all 13 intended reds.
After committing the implementation at `7a29c49`, the same command passed:
60 examples, 0 failures, randomized seed 53528, clean working tree. No
unrelated or unexpected failures were observed in these focused runs.

## 2026-10-07: observed full-suite encoding failures

These two failures were **observed**, not proven flaky. They were outside the
CLI change. At revision `f394c63070986f0d820559c96a50547396b188a8`,
the working tree was clean. Runtime: MRI Ruby 2.7.4p191 (arm64-darwin21),
Bundler 2.1.4; Ruby reported `Encoding.default_external` as `US-ASCII` with
`LANG=C.UTF-8` and `LC_ALL=C.UTF-8`.

Command: `PATH="$HOME/.asdf/shims:$PATH" bundle exec rspec`.
Result: 538 examples, 2 failures, 12 pending, randomized seed 41801.

| Spec and example | Observed failure text |
| --- | --- |
| `spec/lib/primus/liber_primus_spec.rb:23` chapter builds expected pages | `expect(result).to eq(actual_text)` failed; expected fixture text rendered as UTF-8 byte escapes (`\\xE1...`), got runic Unicode escapes (`\\u16C9...`). The diff displayed different rune lengths across 80 lines. |
| `spec/lib/primus/liber_primus_spec.rb:3` page builds from runic characters | `expect(result.to_s(:rune)).to eq(actual_text)` failed; expected fixture text rendered as UTF-8 byte escapes (`\\xE1...`), got runic Unicode escapes (`\\u16AB...`). The diff displayed different rune lengths around the retained numeric lines. |

Reproduction: rerunning only `spec/lib/primus/liber_primus_spec.rb` under the
same environment yielded 3 examples, the same 2 failures, seed 29291.
Retry with `PATH="$HOME/.asdf/shims:$PATH" RUBYOPT=-EUTF-8 bundle exec rspec
spec/lib/primus/liber_primus_spec.rb` yielded 3 examples, 0 failures, seed
25230. This points to the local Ruby process's default external encoding;
no project source or spec was changed to address it.

Full-suite retry at clean revision `76bc8c1` with
`PATH="$HOME/.asdf/shims:$PATH" RUBYOPT=-EUTF-8 bundle exec rspec` passed:
538 examples, 0 failures, 12 pending, randomized seed 27306.

## 2026-10-07: expected multiple-check TDD reds

These are **expected new-feature failures**, not flaky tests. The baseline
focused suite passed before test edits: 219 examples, 0 failures (seed 52358).
The final full run started with a clean tree at revision
`2070694d170097b2160ed37edfc501d0003938ce`, using MRI Ruby 2.7.4p191
(arm64-darwin21), Bundler 2.1.4, and `RUBYOPT=-EUTF-8`. Command:

```shell
PATH="$HOME/.asdf/shims:$PATH" RUBYOPT=-EUTF-8 bundle exec rspec
```

Result: 558 examples, 20 failures, 12 pending, seed 9270. Every failed
example is a newly added increment-2 test; all pre-existing examples passed.
The observed failures fall into these missing-feature groups:

- CLI repeated flags retain only the last value, so duplicate and mixed-mode
  validations incorrectly succeed or the run keeps one check.
- Multi-check execution is rejected or uses a singleton assessment/status, so
  ordered results, completion counts, independent IDs and review are absent.
- Runner probes the first backend before entering a per-check error boundary;
  a raised probe aborts, while digest failures do not retain later matches.
- The valid two-check YAML composition is rejected; no digest assessment occurs
  at the persisted-observation boundary.

Failed examples (the command above is the reproduction):

- `rspec ./spec/lib/primus/experiment_composable_spec.rb:39 # Primus::Experiment#valid? accepts two independent checks in declaration order`
- `rspec ./spec/lib/primus/experiment/runner_multiple_spec.rb:91 # Primus::Experiment::Runner#run keeps a negative outcome when a mismatch accompanies a backend error`
- `rspec ./spec/lib/primus/experiment/runner_multiple_spec.rb:112 # Primus::Experiment::Runner#run records no match when every backend probe fails`
- `rspec ./spec/lib/primus/experiment/runner_multiple_spec.rb:69 # Primus::Experiment::Runner#run retains a later SHA-512 match after BLAKE2b digest calculation raises`
- `rspec ./spec/lib/primus/experiment/runner_multiple_spec.rb:48 # Primus::Experiment::Runner#run retains a later SHA-512 match after a BLAKE2b runtime probe raises`
- `rspec ./spec/lib/primus/experiment/runner_multiple_spec.rb:25 # Primus::Experiment::Runner#run persists the observed output before the first digest calculation`
- `rspec ./spec/lib/primus/commands/experiments_composable_spec.rb:371 # Primus::Commands::Experiments#validate with multiple checks rejects repeated plaintext oracle flags`
- `rspec ./spec/lib/primus/commands/experiments_composable_spec.rb:348 # Primus::Commands::Experiments#validate with multiple checks rejects a duplicate selected algorithm`
- `rspec ./spec/lib/primus/commands/experiments_composable_spec.rb:359 # Primus::Commands::Experiments#validate with multiple checks rejects a mixture of shared and qualified expectations`
- `rspec ./spec/lib/primus/commands/experiments_composable_spec.rb:432 # Primus::Commands::Experiments#review of multiple checks reads every saved result after the current source and oracle disappear`
- `rspec ./spec/lib/primus/commands/experiments_composable_spec.rb:452 # Primus::Commands::Experiments#review of multiple checks uses a shell-escaped review command for a path containing spaces`
- `rspec ./spec/lib/primus/commands/experiments_composable_spec.rb:296 # Primus::Commands::Experiments#execute with multiple checks reports every match with qualified digests`
- `rspec ./spec/lib/primus/commands/experiments_composable_spec.rb:285 # Primus::Commands::Experiments#execute with multiple checks exits successfully after every comparison mismatches`
- `rspec ./spec/lib/primus/commands/experiments_composable_spec.rb:330 # Primus::Commands::Experiments#execute with multiple checks appends a plaintext check after hashes regardless of flag position`
- `rspec ./spec/lib/primus/commands/experiments_composable_spec.rb:271 # Primus::Commands::Experiments#execute with multiple checks reports a match after an earlier mismatch`
- `rspec ./spec/lib/primus/commands/experiments_composable_spec.rb:310 # Primus::Commands::Experiments#execute with multiple checks canonicalizes equivalent shared and qualified expectations identically`
- `rspec ./spec/lib/primus/commands/experiments_composable_spec.rb:256 # Primus::Commands::Experiments#execute with multiple checks accumulates repeated hash flags and retains their declaration order`
- `rspec ./spec/lib/primus/commands/experiments_composable_spec.rb:415 # Primus::Commands::Experiments#execute collection records gives distinct assessment IDs to repeated attempts on the same checks`
- `rspec ./spec/lib/primus/commands/experiments_composable_spec.rb:385 # Primus::Commands::Experiments#execute collection records saves two relative assessment record references`
- `rspec ./spec/lib/primus/commands/experiments_composable_spec.rb:399 # Primus::Commands::Experiments#execute collection records records an all-mismatch outcome separately from completed execution`

Focused retries also reproduced intended reds: 8/8 CLI accumulation and
validation examples, 5/5 collection/review examples, 4/4 initial runner
examples, and the valid multi-check model example. One earlier full run was
interrupted after 15 examples to fix a new spec constant-name collision; it
showed a v1 identity example failing during interruption. That pre-existing
example passed in the complete clean rerun above, so the interrupted result
is not evidence of a baseline regression or flakiness.

### Final increment-2 test-writer run

After adding the Store reference and persistence examples, a clean working
tree at revision `b0f79e16e956fb4ca5cdabb6f72a8c0b95f300ba` used the same
MRI Ruby 2.7.4p191 and UTF-8 command above. Result: 562 examples, 24
failures, 12 pending, seed 52304. The prior 20 new-feature reds reproduced;
these four new examples also failed as expected:

- `rspec ./spec/lib/primus/experiment/store_multiple_spec.rb:29 # Primus::Experiment::Store#review rejects an assessment reference that escapes its run directory`
- `rspec ./spec/lib/primus/experiment/store_multiple_spec.rb:18 # Primus::Experiment::Store#review rejects a missing referenced assessment record`
- `rspec ./spec/lib/primus/experiment/store_multiple_spec.rb:43 # Primus::Experiment::Store#review rejects an unsupported referenced assessment schema`
- `rspec ./spec/lib/primus/experiment/runner_multiple_spec.rb:25 # Primus::Experiment::Runner#run surfaces an observation persistence failure before assessment`

Store currently ignores referenced assessments, so the three reader
examples raised no `ReadError`. The runner rejected the multi-check setup
before reaching `record_observation`, so the injected `Errno::ENOSPC` was not
raised. The same four failed in focused runs. All 538 pre-existing examples
passed; no unrelated failure was observed.

## 2026-10-08: implementer verification

All runs below used MRI Ruby 2.7.4p191, Bundler 2.1.4 and
`RUBYOPT=-EUTF-8` unless noted. No failure here is proven flaky.

- At clean revision `7055d9d`, the initial focused command
  `RUBYOPT=-EUTF-8 bundle exec rspec spec/lib/primus/commands/experiments_composable_spec.rb spec/lib/primus/experiment_composable_spec.rb spec/lib/primus/experiment/runner_multiple_spec.rb spec/lib/primus/experiment/store_multiple_spec.rb`
  used the default `/usr/bin/ruby` 2.6 and failed before loading specs because
  Bundler 2.1.4 was unavailable. Retrying with
  `PATH="$HOME/.asdf/shims:$PATH"` at the same clean revision produced 40
  examples, 24 expected new-feature failures, seed 5008. This was environment
  setup plus intended TDD red behavior, not an unrelated test failure.
- With uncommitted configuration edits after `7055d9d`, a focused location
  run of the model and three CLI validation examples showed 7 examples,
  3 CLI failures. The CLI specs clone committed code, so they exercised the old
  revision while the implementation was dirty. After committing `b7a21bd`,
  the same focused run passed 7 examples, 0 failures, seed 59031.
- With uncommitted runner/store edits after `b7a21bd`, the command
  `PATH="$HOME/.asdf/shims:$PATH" RUBYOPT=-EUTF-8 bundle exec rspec spec/lib/primus/experiment/runner_multiple_spec.rb spec/lib/primus/experiment/store_multiple_spec.rb`
  produced 9 examples, 6 failures, seed 24819. Three exposed an incorrect
  early runtime probe in the implementation; the others encountered the
  executable-code-clean guard while source was dirty. After fixing the probe
  boundary and committing `bbcd6c7`, the same command passed 9 examples,
  0 failures, seed 42428.
- At clean revision `05149ec`, the full command
  `PATH="$HOME/.asdf/shims:$PATH" RUBYOPT=-EUTF-8 bundle exec rspec`
  passed 562 examples, 0 failures, 12 existing pending, seed 36825. The
  focused four-file command passed 40 examples, 0 failures, seed 27791.
- After the final read-validation changes, the focused four-file command at
  clean revision `4f902bd` passed 40 examples, 0 failures, seed 45905. The
  full command above at clean revision `5e4174c` passed 562 examples,
  0 failures, 12 existing pending, seed 36629. The direct CLI controls at
  `05149ec` confirmed mixed match/mismatch exit 0, all-mismatch exit 0, and
  three qualified hash/plaintext matches exit 0. No unclassified test failure
  remains.
