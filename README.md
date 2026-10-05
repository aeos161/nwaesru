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

From the repository root, use Ruby 2.7.4 (see `.tool-versions`) with the
project bundle installed, then run `bin/primus` directly:

```shell
bin/primus experiments validate page-56-totient-latin
bin/primus experiments run page-56-totient-latin --output-path experiments/runs
bin/primus experiments run page-56-totient-latin --output-path experiments/runs --rerun --reason "Check repeatability"
bin/primus experiments review page-56-totient-latin --output-path experiments/runs
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
```

The CLI accepts experiment IDs and reads live definitions from
`experiments/definitions/<ID>.yml`. Ruby callers can still load an explicit
definition path with `Primus::Experiment.load(path: ...)`.

`run` accepts `--output-path DIR` to retain attempts elsewhere. An unchanged
attempt is reused; `--rerun --reason "..."` creates a linked new attempt.
`review` also accepts a run ID. The default local history is
`experiments/runs/`, which Git ignores. Each attempt retains exact definition,
encoded YAML, extracted body, expected text for plaintext checks, output when
produced, provenance,
and a JSON record. Invalid and interrupted attempts remain visible. Validation
does not write an attempt.

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
Git HEAD does not identify the entire host environment, so a saved attempt
is evidence of this local run rather than a fully portable build recipe.

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
