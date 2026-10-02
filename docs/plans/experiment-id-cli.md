# Consistent experiment ID arguments

## Goal

Accept an experiment ID consistently in `bin/primus experiments validate ID`,
`run ID`, and `review ID [RUN_ID]`, resolving live definitions from
`experiments/definitions/<ID>.yml`. Keep explicit definition paths in the Ruby
API and preserve retained experiment history.

Reconciled against clean `main` and `origin/main` at `c0e93e4` (direct startup
already merged). This is a separate feature branch and change. Bootstrap
already loads Bundler and the local library; do not redo the direct-execution
plan or change `bin/primus`.

## Acceptance criteria

- Validate both tracked IDs (`page-56-totient-latin`, `page-57-latin`) using
  their conventional definitions. Successful validation writes no attempt.
- Run both IDs from a clean checkout and retain a matched attempt. Preserve
  `--output-path`, reuse of an identical execution, `--rerun`, required
  nonblank `--reason`, and prior-run links. Keep `run` mapped to `execute`.
- All three commands accept only IDs matching `\A[a-z0-9]+(?:-[a-z0-9]+)*\z`.
  Reject empty strings, whitespace, uppercase, dots/extensions, separators,
  absolute paths, traversal, and glob metacharacters without normalization or
  path fallback. Reject them before definition I/O or any history lookup or
  write; a rejected ID must not create a failed-load attempt.
- Lexical validity does not imply a supported recipe. Do not duplicate the
  model's recipe allowlist in the CLI. Existing model validation remains the
  authority for supported ID/page/path/operation combinations.
- A loaded definition must declare exactly the requested ID before validation,
  execution, or planned display. Reject missing, different, or unsafe declared
  IDs as definition-load failures; never let them reach Runner/Store under a
  different history key. Do not rewrite the declaration to the requested ID.
- A well-formed unknown ID resolves only to its conventional path. Missing
  files, malformed YAML (including duplicate keys), and declared-ID mismatch
  fail validate/run. Run retains the existing failed-load shape: `invalid`,
  `not_checked`, definition-stage error, under `failed-load`, with
  `definition_path` equal to the actual resolved relative path and exact
  definition snapshot when present. Validate remains read-only.
- A loadable definition with matching ID but invalid recipe or digest retains
  existing model-validation/integrity behavior; run records an invalid attempt
  through Runner. A valid wrong oracle still records `mismatched` and exits
  unsuccessfully. Do not collapse these into load failures.
- Review reads retained attempts first using the validated ID, preserving
  `--output-path` and optional `RUN_ID`. Archived attempts remain reviewable
  even if the definition is absent, malformed, model-invalid, or declares
  another ID. Do not load a live definition on this path.
- Without attempts and without `RUN_ID`, review displays the conventional
  definition's planned title/purpose after loading and checking its declared
  ID. Keep existing planned-display behavior: do not add model validation as
  a prerequisite. Missing or unloadable definitions produce a command error.
  An explicitly unknown `RUN_ID` remains a missing-attempt error, even when
  a live definition exists; it must not fall back to planned display.
- Thor help shows `validate ID`, `run ID`, `review ID [RUN_ID]`. Missing required
  arguments retain Thor's handling. README uses direct invocation and IDs.
- `Primus::Experiment.load(path: ...)` remains unchanged: explicit paths,
  fixture filenames, and model validation continue to work for Ruby callers.

## Approach

- `lib/primus/commands/experiments.rb`: change validate/execute argument names
  and help; share small private helpers for lexical validation, conventional
  path resolution, and live definition loading/declared-ID comparison. Use
  `Primus::Experiment::LoadError` for an ID/definition mismatch at this command
  boundary so run's existing failed-load recording remains applicable.
  Resolve and retain the actual path before load; syntax rejection must be a
  command error outside failed-load handling. Apply validation before creating
  or consulting Store in review. Handle planned-review load errors as Thor
  errors, while retaining Store's missing-run behavior.
- Keep orchestration in the command and persistence in existing Store/Runner.
  No prerequisite refactor is needed for these small boundary helpers. Respect
  Law of Demeter and the five-line method heuristic; if an additional object
  becomes necessary, use a focused noun name rather than a service namespace.
  Do not add a registry, duplicate model rules, or forwarding-only wrappers.
- `spec/lib/primus/commands/experiments_spec.rb`: migrate the existing command
  scenarios to IDs and add the boundary cases above. Use tracked definitions
  for normal page 56/page 57 scenarios. For duplicate, unsupported, wrong
  digest, and wrong oracle fixtures, clone committed HEAD to a temporary
  repository, then copy the original fixture bytes to
  `experiments/definitions/page-57-latin.yml` there. Run with that checkout as
  working directory and a separate temporary output directory. The fixture's
  relative input/oracle paths remain valid because the full repo is present;
  do not rename YAML IDs or rewrite fixture content simply to fit filenames.
  Use an isolated conventional file for deliberate declared-ID mismatch.
- For command ordering checks, exercise `Primus::Commands::Experiments`
  directly with collaborators to establish that unsafe IDs never call the
  loader or Store. Keep persisted status/path/category and subprocess exit
  assertions in command/feature specs. Full class hierarchy belongs in class
  spec descriptions; use focused examples, predicate matchers, and avoid
  coupling model failures to exact error prose. Retain explicit-path library
  setup where it is genuinely preparing archived history, not calling the CLI.
- `spec/features/page_57_experiment_identity_spec.rb`: change all validate,
  run, and rerun arguments to `page-57-latin`. Point every definition edit
  (digest replacement, formatting annotation, parsed-purpose modification)
  at `experiments/definitions/page-57-latin.yml` in the clone. The tracked
  definition contains the existing purpose text used by the mutation helper.
  Continue using its tracked oracle; do not silently leave helpers editing an
  unused fixture. Preserve the exact-input snapshot, changed-source/digest,
  YAML-formatting reuse, parsed-field changes, Git HEAD, dirty executable,
  error reuse, interruption, and rerun-history scenarios.
- `README.md`: replace validate/run paths with IDs, retain direct executable
  examples, explain the conventional directory and ID-only CLI versus explicit
  Ruby API paths. Preserve output-path, rerun/reason, and review examples.
- Do not add tests of `bin/primus`, bootstrap, or executable permissions. The
  existing command/feature subprocess specs test command behavior and may
  continue using their configured Ruby invocation.

## Verification

This planning change does not run or write tests. The last reported baseline
is 376 examples, 0 failures, 12 pending; it has not been rerun for this plan.
Use Ruby 2.7.4 from `.tool-versions` and the installed bundle for implementation
verification. Run the focused command and execution-identity specs, then the
full suite and applicable project checks.

Clone-based specs use committed HEAD, and Runner rejects dirty executable or
dependency files. Commit authorized implementation work before final clean
checkout verification so clones exercise the actual change. Temporary
conventional definitions/data may change within clones without committing
because they are outside Runner's executable-code paths. Preserve deliberate
commits in identity scenarios that change executable code or HEAD; never stub
or disable provenance checks. Manually smoke-check direct ID validation, run,
rerun/reason, and review with temporary outputs without adding bin tests.

## Edge cases

- Safe unknown IDs are different from unsafe IDs: only the former may attempt
  loading and create the existing failed-load record. `failed-load` is itself
  a lexically valid history ID and remains reviewable without a live definition.
- Review's `RUN_ID` is still an exact match against retained entries, not a
  filesystem path; do not change its format or positional semantics.
- A definition containing a supported but different ID must fail at the CLI
  boundary; model validity alone cannot establish filename/ID agreement.
- Definitions copied into temporary conventional paths must preserve exact
  fixture bytes and oracle references, including intentionally wrong ones.
- Lexical checking covers CLI argument traversal and glob injection. Existing
  repository trust and symlink handling are not redesigned in this change.

## Out of scope

Bootstrap/executable changes and bin tests, dependency upgrades, arbitrary
working directories, installed-gem distribution, new recipes, registries,
Ruby API/model validation changes, Store/Runner redesign, provenance changes,
normalizing IDs, and backward compatibility for CLI definition-path arguments.

## Open questions

None blocking. The explicit boundary choices are lowercase hyphenated IDs,
exact filename/declaration agreement as a load failure, existing failed-load
storage, and history-first review with unchanged planned-display validation.
Review this reconciled plan before invoking the test-writer.
