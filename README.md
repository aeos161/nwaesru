# Primus

Primus is a library deciphering and investigating [Liber Primus].

## Install

Install the gem manually from your shell, run:

```shell
gem install primus
```

## Documentation

### Page 56 and 57 Latin experiments

The saved definitions are `experiments/definitions/page-56-totient-latin.yml`
and `experiments/definitions/page-57-latin.yml`. Their expected texts are
extracted independently from the existing decoded YAML bodies using `rstrip`;
each definition records its source YAML digest. Page 56 subtracts successive
prime totients modulo 29 from GP runes, skipping GP ordinal 56 without
consuming a prime. Each run starts with prime 2 and preserves the hexadecimal
passage as text. Page 57 directly transliterates the GP runes.
`page-57-latin-sha512` runs that same translation as a separate control with
a fixed SHA-512 expectation prepared from the known page-57 plaintext. The
`page-57-latin-blake2b512` control checks the same bytes with an independently
prepared, unkeyed BLAKE2b-512 digest through the Ruby OpenSSL binding. These
digests check the exact saved output bytes; they do not identify any historical
target hash.
The `page-57-latin-blake512` control uses the final original BLAKE-512
algorithm through the pinned `blake512-ruby` native gem. Its fixed digest was
prepared independently with the vetted @noble/hashes implementation; the
definition records the exact input, package checksums and source revision.

The first `bundle install` needs Git and HTTPS access to fetch the pinned gem,
plus a C compiler, `make` and headers for the selected Ruby 2.7.4 to build its
native extension. Run `bundle check` after installation. If a previously
installed native artifact is missing or fails its build-identity check, run
`bundle pristine blake512-ruby` and start a fresh process. This rebuild was
verified with Bundler 2.1.4 on MRI 2.7.4/macOS arm64. If the Git checkout is
missing, run `bundle install` again to fetch the pinned revision. Resolution
and compilation errors are setup failures before an experiment can run.

From the repository root, use Ruby 2.7.4 (see `.tool-versions`) with the
project bundle installed, then run `bin/primus` directly:

```shell
bin/primus experiments validate page-56-totient-latin
bin/primus experiments run page-56-totient-latin --output-path experiments/runs
bin/primus experiments run page-56-totient-latin --output-path experiments/runs --rerun --reason "Check repeatability"
bin/primus experiments review page-56-totient-latin --output-path experiments/runs
bin/primus experiments validate page-56-totient-latin-controls
bin/primus experiments run page-56-totient-latin-controls
bin/primus experiments review page-56-totient-latin-controls
bin/primus experiments validate page-57-latin
bin/primus experiments run page-57-latin
bin/primus experiments review page-57-latin
bin/primus experiments validate page-57-latin-sha512
bin/primus experiments run page-57-latin-sha512
bin/primus experiments review page-57-latin-sha512
bin/primus experiments run page-57-latin-sha512 --rerun --reason "Check reproducibility"
bin/primus experiments validate page-57-latin-blake2b512
bin/primus experiments run page-57-latin-blake2b512
bin/primus experiments review page-57-latin-blake2b512
bin/primus experiments validate page-57-latin-blake512
bin/primus experiments run page-57-latin-blake512
bin/primus experiments review page-57-latin-blake512
```

You can compose a whole-page Latin run with several independent checks. The
following example compares the same saved output with SHA-512 and BLAKE2b-512,
then with exact plaintext bytes:

```shell
bin/primus experiments run --input page-57 --recipe latin --hash sha512 --hash blake2b512 --expect-digest "sha512=SHA_HEX" --expect-digest "blake2b512=BLAKE_HEX" --expect-text experiments/expected/page-57-latin.txt
```

Replace `SHA_HEX` and `BLAKE_HEX` with independent 128-character lowercase
hexadecimal digests. A single bare `--expect-digest HEX` instead applies the
same target to every selected hash. Available hashes are `sha512`,
`blake2b512` and `blake512`; `--hash=sha512` and
`--expect-digest=sha512=HEX` spellings work too. Every selected hash needs one
expectation, and plaintext is optional. `validate` accepts the same composition
flags without running the recipe or checking backend availability.

The v2 `totient-latin` recipe works on any selected whole page. Its parameters
default to `modulus: 29`, `prime_start: 2` and `skip_sequence: []`.
`prime_start` is the first prime **value** consumed, and must itself be prime.
Skips are unique, zero-based ordinals of the original GP runes; a skipped rune
does not consume a prime. Other text, including the hexadecimal passage, does
not consume an ordinal or prime. Use `--recipe-param KEY=JSON_VALUE` repeatedly
on either `validate` or `run`. For page 56, skip 56 is explicit:

```shell
bin/primus experiments validate --input page-56 --recipe totient-latin --recipe-param 'skip_sequence=[56]' --expect-text experiments/expected/page-56-totient-latin.txt
bin/primus experiments run --input page-56 --recipe totient-latin --recipe-param 'skip_sequence=[56]' --expect-text experiments/expected/page-56-totient-latin.txt
```

The named `page-56-totient-latin-controls` definition records the same recipe
with SHA-512, BLAKE2b-512, original BLAKE-512, and exact plaintext checks.
The literal answers and independent preparation are documented in
`spec/fixtures/experiments/page_56_totient_oracle.md`. Check its review for
four matches, zero mismatches, and zero errors.

A multi-check run prints each check and a summary. Its `matching outcome` is
`matched` if any check matches, even when another check mismatches or errors.
The command exits successfully when all comparisons complete, including when
every check mismatches. A backend, configuration, transformation or storage
error causes a nonzero exit. The older one-check runs retain their existing
convention: a mismatch exits nonzero. Copy the printed `review:` command to
inspect all retained check evidence later, without relying on current inputs
or installed hash backends.

The CLI accepts experiment IDs and reads live definitions from
`experiments/definitions/<ID>.yml`. Ruby callers can still load an explicit
definition path with `Primus::Experiment.load(path: ...)`.

`run` accepts `--output-path DIR` to retain attempts elsewhere. Legacy v1 runs
reuse an unchanged attempt; v2 composed runs create a fresh attempt.
`--rerun --reason "..."` remains available.
`review` also accepts a run ID. The default local history is
`experiments/runs/`, which Git ignores. Each attempt retains exact definition,
encoded YAML, extracted body, expected text for plaintext checks, output when
produced, provenance,
and a JSON record. Invalid and interrupted attempts remain visible. Validation
does not write an attempt.

For example, a successful run prints its retained identity and review command:

```text
20261007T221654-96e2732ad650: matched (match)
experiment ID: page-57-latin
run ID: 20261007T221654-96e2732ad650
review: bin/primus experiments review page-57-latin 20261007T221654-96e2732ad650 --output-path experiments/runs
```

Copy the command after `review: ` from the same working directory to inspect
that attempt. It includes the actual output path, including a custom path when
one was supplied to `run`.

The callable API then provides `valid?` and `errors`;
`Primus::Experiment::Runner.new(experiment: ..., output_path: ...)`
offers the `run` command and `observation`, `assessment`, and `log_entry`
readers. An ordinary `run` returns `nil`. A retained prior attempt is exposed
through `log_entry` without creating a new observation. A new comparison is
an `Assessment` against the independent expected bytes or fixed digest.

Runs require the executable and dependency files to match Git HEAD. The record
captures that commit and Ruby version, plus exact source and oracle digests.
The BLAKE2b-512 control also records the OpenSSL binding, build and linked
library versions and digest availability, so backend changes create separate
attempts. If the backend is unavailable, the attempt retains any produced
output and records an execution error.
The original BLAKE-512 control saves the gem's source and native checksums,
Ruby/native identity and diagnostic build details. A source, native binary or
availability change creates a distinct attempt; changing only a path, compiler
description or compile flags does not.
Git HEAD does not identify the entire host environment, so a saved attempt
is evidence of this local run rather than a fully portable build recipe.

### Saved final-output statistics

New observations retain versioned final-symbol profiles alongside their
output and provenance. To analyze a specific saved run, use its printed run
ID and the separate analysis definition:

```sh
bin/primus analyses run EXPERIMENT_ID RUN_ID --definition experiments/analyses/final-symbol-statistics.yml --output-path experiments/runs
bin/primus analyses review EXPERIMENT_ID RUN_ID --output-path experiments/runs
bin/primus analyses review EXPERIMENT_ID RUN_ID ANALYSIS_RUN_ID --output-path experiments/runs
```

Each invocation appends a separate retained analysis. Review reads those
measurements without rerunning the experiment or requiring today's input,
definition or hash backend. Runs saved before the final-symbol manifest was
added need to be recreated before they can be analyzed.

The GP profile counts the final decoded runes in provenance (29 bins). The
expanded-Latin profile counts only the canonical lowercase letters for those
same runes (26 bins); punctuation and passthrough output such as page 56's
hexadecimal block are excluded. `ᚦᚪᚦ` is three GP symbols with raw IC 1/3,
while its Latin expansion `thath` is five letters with raw IC 1/5. Raw IC is
the number of ordered matching pairs divided by `N × (N - 1)`, without
alphabet normalization. Samples shorter than two symbols report an
insufficient statistic. These are measurements, not a plaintext verdict.

## License

Primus is free  software, and may be redistributed under the terms specified in
the [LICENSE] file.

## Contributing

Please see [CONTRIBUTING.md]

## More Information

* [Uncovering Cicada Wiki]

[Liber Primus]: https://uncovering-cicada.fandom.com/wiki/Liber_Primus
[Uncovering Cicada Wiki]: https://uncovering-cicada.fandom.com/wiki/Uncovering_Cicada_Wiki
[CONTRIBUTING.md]: CONTRIBUTING.md
[LICENSE]: LICENSE
