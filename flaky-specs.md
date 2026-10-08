# Observed test failures

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
