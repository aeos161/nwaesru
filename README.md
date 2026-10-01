# Primus

Primus is a library deciphering and investigating [Liber Primus].

## Install

Install the gem manually from your shell, run:

```shell
gem install primus
```

## Documentation

### Page 57 Latin experiment

The saved definition is `experiments/definitions/page-57-latin.yml`. Its
expected text is extracted from the existing decoded page 57 YAML body using
`rstrip`; the definition records the source YAML digest. The expected text is
independent of the transformation being tested.

```shell
bundle exec ruby -Ilib bin/primus experiments validate experiments/definitions/page-57-latin.yml
bundle exec ruby -Ilib bin/primus experiments run experiments/definitions/page-57-latin.yml
bundle exec ruby -Ilib bin/primus experiments review page-57-latin
```

`run` accepts `--output-path DIR` to retain attempts elsewhere. An unchanged
attempt is reused; `--rerun --reason "..."` creates a linked new attempt.
`review` also accepts a run ID. The default local history is
`experiments/runs/`, which Git ignores. Each attempt retains exact definition,
encoded YAML, extracted body, expected text, output when produced, provenance,
and a JSON record. Invalid and interrupted attempts remain visible. Validation
does not write an attempt.

The callable API is `Primus::Experiment.load(path: ...)`, then `valid?` and
`errors`; `Primus::Experiment::Runner.new(experiment: ..., output_path: ...)`
offers the `run` command and `observation`, `assessment`, and `log_entry`
readers. An ordinary `run` returns `nil`. A retained prior attempt is exposed
through `log_entry` without creating a new observation. A new comparison is
an `Assessment` against the independent expected bytes.

Runs require the executable and dependency files to match Git HEAD. The record
captures that commit and Ruby version, plus exact source and oracle digests.
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
