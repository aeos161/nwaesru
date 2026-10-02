# Direct Primus executable startup

## Goal

Run `bin/primus` directly from the repository root without an external
`bundle exec ruby -Ilib` wrapper. This is the first of two distinct changes;
experiment argument signatures remain exactly as they are today.

## Acceptance criteria

- With the configured Ruby and bundle installed and available on PATH,
  `bin/primus help` starts successfully.
- Direct startup succeeds without inherited Bundler injection or RUBYLIB.
- Direct `bin/primus experiments validate
  experiments/definitions/page-56-totient-latin.yml` succeeds using the
  existing path argument and writes no attempt.
- The executable retains its existing executable permission and env Ruby
  shebang; existing command options and signatures remain unchanged.
- README commands use direct invocation and retain existing definition-path
  arguments for validate/run and ID arguments for review.

## Approach

- `bin/primus`: load Bundler before external gems; add the library directory
  relative to the executable to the load path, then require Primus. The file
  already has executable permission and an env Ruby shebang.
- Manually smoke-check direct help and existing path-based validation without
  inherited Bundler injection or RUBYLIB. Put the configured Ruby's executable
  directory on PATH; do not invoke the child via Ruby, -Ilib, or bundle exec.
  No new bin specs are needed for this change.
- `README.md`: document repository-root invocation and installed runtime/bundle
  prerequisites, currently Ruby 2.7.4 in .tool-versions. Remove invocation
  wrappers from examples without changing their arguments.
- Keep this a small bootstrap change; no preparatory refactor is needed.

## Verification

Run direct executable smoke checks and the full existing suite. Identity specs
clone committed HEAD, and runs reject dirty executable/dependency files;
perform final verification after the authorized implementation commit in a
clean checkout. Do not weaken the provenance gate. Existing path-based
experiment runs should still match using temporary output directories.

## Edge cases

- A bundle-exec test parent can conceal missing startup setup unless its
  injection is removed from the child environment.
- Direct invocation still needs the project Ruby selected on PATH and its
  dependencies installed. Do not hardcode developer paths or install gems
  from the executable.
- Do not change working directory: relative data/output behavior remains
  repository-root based.

## Out of scope

Experiment ID resolution/signature changes, CLI fixture migration to IDs,
installed-gem distribution, dependency upgrades, arbitrary-working-directory
support, other command refactors, and provenance changes.

## Open questions

None blocking. Handle this change independently first. The separate
`experiment-id-cli.md` plan describes the later ID change and must be
reconciled against the merged startup change before implementation.
