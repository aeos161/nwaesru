# Observed test failures

## 2026-10-23: continuous page input test-writer regression check

On `codex/continuous-page-input` after test-only commits `f9dc476` and
`8886a7b`, the Ruby 2.7.4 UTF-8 focused regression command covering
`run_page_56_experiment_spec.rb`, `run_page_57_experiment_spec.rb`,
`runner_checkpoints_spec.rb`, and `observation_reader_checkpoint_spec.rb`
reported 58 examples, 1 failure, seed 41410. The sole failure was the
existing clone-helper race in
`observation_reader_checkpoint_spec.rb:99`: `Errno::ENOENT` for temporary
`.git/61743.tags`, followed by `Errno::ENOTEMPTY` during temporary-directory
cleanup. Its duplicate-key assertion was never reached. Running that exact
example again passed (1 example, 0 failures, seed 7871). This is distinct
from the expected red ordered-input controls, which currently fail because
`input.pages` has not been implemented.

The full UTF-8 suite on the same branch then reported 886 examples, 27
failures and 12 pending (seed 34912). Twenty-six failures were the intended
new controls. The only existing-spec failure was the same clone-helper race
at `runner_checkpoints_spec.rb:285`: temporary `.git/64419.tags` was missing,
followed by `Errno::ENOTEMPTY` while cleaning the clone. Its punctuation
assertion was not reached. The exact example passed on retry (1 example,
0 failures, seed 41980). No other existing example failed.

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

## 2026-10-16: transformation checkpoint focused verification

At clean revision `6fd726f`, MRI Ruby 2.7.4p191, command
`PATH="$HOME/.asdf/shims:$PATH" bundle exec rspec spec/lib/primus/experiment/runner_checkpoints_spec.rb --format progress`
reported 32 examples, 6 failures, seed 39464. Four failures compared
`File.binread` output (ASCII-8BIT) to UTF-8 rune literals at spec lines 83
(original, first, second) and 293 (mixed punctuation). The displayed byte
sequences match; this is an assertion encoding mismatch, not differing
checkpoint bytes. Test-writer has been notified; implementation must not
change the immutable spec.

Two further failures arose in the fixture helper's local Git clone, before
the example body: `Errno::ENOENT` for temporary `.git/38049.tags.tmp` and
`.git/38173.tags`, followed by `Errno::ENOTEMPTY` while `Dir.mktmpdir`
cleaned the two repositories. A rerun is needed to establish whether these
temporary Git failures reproduce. No production checkpoint assertion was
reached in those examples.
The two exact examples at lines 155 and 245 passed on rerun (2 examples,
0 failures, seed 43583) with `RUBYOPT=-EUTF-8` and the same Ruby 2.7.4.

At revision `745a205`, the full command
`PATH="$HOME/.asdf/shims:$PATH" RUBYOPT=-EUTF-8 bundle exec rspec --format progress`
reported 775 examples, 82 failures, 12 pending, seed 45771. The 32 new
checkpoint runner examples failed because the newly extracted Checkpoint
used `transcription` after removing that reader (`NameError` at
`lib/primus/experiment/checkpoint.rb:26`); this implementation error was
fixed immediately. The remaining failures were older version-two specs that
still construct `recipe` definitions after the approved change to `steps`;
their test fixtures require migration by test-writer. Four byte assertions
also still require the previously reported encoding correction. These are
not classified as flaky. The full suite will be rerun after the fixture
handoff and source fix.

At clean revision `534b54b`, the focused checkpoint runner command with
`RUBYOPT=-EUTF-8` reported 32 examples, 6 failures, seed 10669. The four
known binary/UTF-8 assertions remained. Two fixture helper Git clone races
recurred, this time at examples 110 and 88: missing temporary
`.git/42479.tags` and `.git/42639.tags` followed by temporary-directory
`Errno::ENOTEMPTY` cleanup errors. This establishes intermittent helper
behavior; exact examples 155 and 245 had passed on the earlier rerun.

At clean revision `7d93714`, the four-file focused command with UTF-8
reported 66 examples, 4 failures, seed 62730: only the four identified
binary/UTF-8 rune-byte assertions failed. The full UTF-8 suite reported
775 examples, 42 failures, 12 pending, seed 32730. Of those, 37 are
pre-existing version-two specs still expressing disposable `recipe`
definitions or records that the approved `steps` schema replaces; four are
the same binary/UTF-8 assertions; one is another clone helper race at
runner_checkpoints_spec.rb:335 (missing `.git/47660.tags`, then
`Errno::ENOTEMPTY` during cleanup). No additional source regression was
identified from that failure list. The test-writer must migrate affected
fixtures and correct the test-only encoding and clone setup.

At revision `26092b1` with uncommitted checkpoint-analysis source changes,
MRI Ruby 2.7.4, the focused definition, checkpoint reader, evidence and
validator specs with `RUBYOPT=-EUTF-8 LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8`
reported 29 examples, 1 failure, seed 45151. The failing example was
`observation_reader_checkpoint_spec.rb:33`; its temporary local Git clone
lost `.git/18492.tags`, followed by `Errno::ENOTEMPTY` during cleanup. This
matches the previously observed clone helper race; no observation assertion
was reached. Later focused checkpoint suites passed 50/50 at seeds 4876,
53937, and 21122 without reproducing this cleanup race.

At committed revision `b837c46`, the full Ruby 2.7.4 UTF-8 suite
(`PATH="$HOME/.asdf/shims:$HOME/.asdf/bin:$PATH" RUBYOPT=-EUTF-8
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 bundle exec rspec --format progress`)
reported 822 examples, 9 failures, 12 pending, seed 48194. All nine
failures were in `spec/features/analyze_saved_output_spec.rb` at lines
135, 152, 168, 316, 333, 350, 370, 667, and 685. Their shared
`completed_observation` helper produced a version-one page-57 run with no
`checkpoints` array. The new analysis reader rejected that run as required
by the approved plan. These are fixture-migration failures, not intermittent
flakes; test-writer handoff is required before the full suite can be green.

After the page-57 fixture migration at `0e82782`, a full UTF-8 run started
with source files being edited concurrently. It reported 822 examples, 29
failures, 12 pending, seed 4721. Twenty-eight Runner examples were invalid
because the repo's clean-code guard saw those edits during execution; this
was a mixed-state run and does not describe committed behavior. The other
failure was the known clone helper race at
`observation_reader_checkpoint_spec.rb:168`: missing temporary
`.git/26991.tags`, then `Errno::ENOTEMPTY` cleanup. That exact example
passed on retry at clean `6288c79` (1 example, 0 failures, seed 64949).

At clean revision `6288c79`, the fixed-revision UTF-8 full suite reported
822 examples, 1 failure, 12 pending, seed 9598. The sole failure was the
same temporary clone helper race at
`observation_reader_checkpoint_spec.rb:99`: missing `.git/33648.tags`,
then `Errno::ENOTEMPTY` cleanup. The example body did not reach its
duplicate-key assertion. Its exact retry passed (1 example, 0 failures,
seed 38429). A second clean full-suite run follows.

At clean revision `2862337`, the second fixed-revision UTF-8 full suite
reported 822 examples, 2 failures, 12 pending, seed 49983. Both failures
were the established temporary Git clone race before assertions:
`runner_checkpoints_spec.rb:206` lost `.git/35990.tags` and
`observation_reader_checkpoint_spec.rb:84` lost `.git/37253.tags`, each
followed by `Errno::ENOTEMPTY` cleanup. Their exact examples passed together
on retry (2 examples, 0 failures, seed 32953). No source assertion failed
in either fixed-revision full run.

During IC interpretation implementation at `52dbafb`, a full Ruby 2.7.4
UTF-8 run (`PATH="$HOME/.asdf/shims:$HOME/.asdf/bin:$PATH"
RUBYOPT=-EUTF-8 LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 bundle exec rspec
--format progress`) was interrupted after 480 examples, 51 failures and
5 pending, seed 31132. The uncommitted edit to
`lib/primus/analysis/ic_reference_packet.rb` made the existing experiment
guard record `DirtyCode: executable code differs from Git HEAD`; resulting
invalid runs caused the 51 reported assertions to fail. This was an
expected mixed-state run, not a flaky test or committed regression. After
committing the edit at `bd19966`, the previously failing
`spec/features/run_page_56_experiment_spec.rb:12` passed (1 example,
0 failures, seed 15769). A clean full-suite run follows.

At clean revision `0b25967`, the Ruby 2.7.4 UTF-8 full suite reported
859 examples, 2 failures, 12 pending, seed 23349. Both failures were the
established temporary Git clone race in `runner_checkpoints_spec.rb`:
the examples at lines 77 and 65 lost `.git/6951.tags` and
`.git/7208.tags`, respectively, before their assertions, followed by
`Errno::ENOTEMPTY` during cleanup. No IC interpretation assertion failed.
An exact two-example retry yielded one pass and the same race for line 65
(missing `.git/10744.tags`, seed 10141). The line-65 example then passed
alone (1 example, 0 failures, seed 31138). The line-77 example passed
in the two-example retry.
