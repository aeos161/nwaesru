require "digest"
require "fileutils"
require "json"
require "open3"
require "psych"
require "rbconfig"
require "shellwords"
require "tmpdir"

RSpec.describe Primus::Commands::Experiments do
  BLAKE2B512_DIGEST = "2e205b4c5686b98f55de31b2aac81512ba7e034a7c2c11ddfb97fea2d57ef9d6a395367c2e98da2f86677e41713dc65d9d2af7e81eb8a54c749a1dd9fe844454"
  SHA512_DIGEST = "f3fac0115ab06d1a4075731e77fe157ad52b837b9068bf942c95784160578f43a1a72e770f2e2c1b00a1bc2fad39dc66fa78efd28c5cd976ed3a35f3e400bcab"

  def cli(repository, *arguments)
    Open3.capture3(RbConfig.ruby, "-Ilib", "bin/primus", "experiments",
                   *arguments, chdir: repository)
  end

  def with_repository
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      _output, error, status = Open3.capture3(
        "git", "clone", "--quiet", "--local", "--no-hardlinks", Dir.pwd,
        repository
      )
      raise "Test repository clone failed: #{error}" unless status.success?
      yield repository, File.join(directory, "runs")
    end
  end

  def saved_records(output_path)
    Dir.glob("#{output_path}/**/record.json").map do |path|
      JSON.parse(File.binread(path))
    end
  end

  def plaintext_options
    ["--input", "page-57", "--recipe", "latin", "--expect-text",
     "experiments/expected/page-57-latin.txt", "--expect-provenance",
     "Independent decoded page-57 control."]
  end

  def page_56_totient_options
    oracle = JSON.parse(File.binread("spec/fixtures/experiments/page_56_totient_oracle.json"))
    ["--input", "page-56", "--recipe", "totient-latin",
     "--recipe-param", "skip_sequence=[56]",
     "--hash", "sha512", "--hash", "blake2b512", "--hash", "blake512",
     "--expect-digest", "sha512=#{oracle.fetch('digests').fetch('sha512')}",
     "--expect-digest", "blake2b512=#{oracle.fetch('digests').fetch('blake2b512')}",
     "--expect-digest", "blake512=#{oracle.fetch('digests').fetch('blake512')}",
     "--expect-text", "experiments/expected/page-56-totient-latin.txt",
     "--expect-provenance", "Independent page-56 oracle packet."]
  end

  def page_56_plaintext_options
    ["--input", "page-56", "--recipe", "totient-latin",
     "--expect-text", "experiments/expected/page-56-totient-latin.txt",
     "--expect-provenance", "Independent page-56 oracle packet."]
  end

  def write_small_totient_definition(repository, page_id, experiment_id)
    source_path = "data/encoded/liber_primus/#{page_id.tr('-', '_')}.yml"
    File.write(File.join(repository, source_path), "---\nbody: |\n  ᚦ-ᚠ 9A\n  ᚢ\n")
    expected_path = "experiments/expected/#{experiment_id}.txt"
    File.write(File.join(repository, expected_path), "f f 9A\ny")
    definition = {
      "schema_version" => 2, "id" => experiment_id,
      "title" => "Small totient control", "purpose" => "Check a page-independent recipe.",
      "input" => { "id" => page_id,
                   "sha256" => Digest::SHA256.file(File.join(repository, source_path)).hexdigest },
      "recipe" => { "id" => "totient-latin",
                    "parameters" => { "prime_start" => 3, "skip_sequence" => [1] } },
      "output" => { "policy" => "gp-latin-compatibility-v1" },
      "checks" => [{ "id" => "check-1", "strategy" => "plaintext",
                     "expectation" => { "path" => expected_path,
                                        "sha256" => "3ff0b3f387873e098a47011c2f9c5793c378a0ddd6353ec2b132ee604c48f62e",
                                        "provenance" => "Hand-calculated small rune control." } }]
    }
    path = File.join(repository, "experiments/definitions/#{experiment_id}.yml")
    File.write(path, Psych.dump(definition))
  end

  def write_v2_definition(repository)
    path = File.join(repository,
                     "experiments/definitions/page-57-composed.yml")
    File.write(path, <<~YAML)
      schema_version: 2
      id: page-57-composed
      title: Page 57 Latin plaintext
      purpose: Compare Latin output with the independent plaintext control.
      input:
        id: page-57
        sha256: c7055db0173e43eb231608812f5d52569e4c0817934b1a65427cebf332759fff
      recipe:
        id: latin
      output:
        policy: gp-latin-compatibility-v1
      checks:
        - id: check-1
          strategy: plaintext
          expectation:
            path: experiments/expected/page-57-latin.txt
            sha256: 2d450628c6431f9497a6709f5af25d3dad2aa509c31d99ec3a00b07a42eb9a39
            provenance: Independent decoded page-57 control.
    YAML
  end

  describe "#validate" do
    it "accepts typed repeated totient parameters in both flag forms" do
      with_repository do |repository, _output_path|
        _stdout, _stderr, status = cli(
          repository, "validate", "--input", "page-56", "--recipe", "totient-latin",
          "--recipe-param", "modulus=29", "--recipe-param=prime_start=2",
          "--recipe-param", "skip_sequence=[56]",
          "--expect-text", "experiments/expected/page-56-totient-latin.txt"
        )

        expect(status).to be_success
      end
    end

    it "validates the four-check page 56 YAML control" do
      with_repository do |repository, _output_path|
        path = File.join(repository, "experiments/definitions/page-56-totient-controls.yml")
        FileUtils.cp("spec/fixtures/experiments/page_56_totient_controls.yml", path)

        _stdout, _stderr, status = cli(repository, "validate", "page-56-totient-controls")

        expect(status).to be_success
      end
    end

    it "accepts a small whole page under an unrelated experiment ID" do
      with_repository do |repository, _output_path|
        write_small_totient_definition(repository, "page-99", "moon-phase-control")

        _stdout, _stderr, status = cli(repository, "validate", "moon-phase-control")

        expect(status).to be_success
      end
    end

    it "rejects a recipe parameter with a positional preset" do
      with_repository do |repository, _output_path|
        _stdout, _stderr, status = cli(repository, "validate", "page-57-latin",
                                       "--recipe-param", "prime_start=2")

        expect(status).not_to be_success
      end
    end

    {
      "duplicate parameter keys" => ["modulus=29", "modulus=29"],
      "malformed JSON" => ["skip_sequence=[56"],
      "a missing parameter key" => ["=29"],
      "an unknown parameter key" => ["surprise=2"]
    }.each do |case_name, values|
      it "rejects #{case_name} at the CLI boundary" do
        with_repository do |repository, _output_path|
          flags = values.flat_map { |value| ["--recipe-param", value] }

          _stdout, _stderr, status = cli(repository, "validate",
                                         *page_56_plaintext_options, *flags)

          expect(status).not_to be_success
        end
      end
    end

    it "rejects recipe parameters without a selected recipe" do
      with_repository do |repository, _output_path|
        _stdout, _stderr, status = cli(repository, "validate", "--input", "page-56",
                                       "--recipe-param", "prime_start=2",
                                       "--expect-text", "experiments/expected/page-56-totient-latin.txt")

        expect(status).not_to be_success
      end
    end

    it "rejects even an empty parameter mapping for the Latin recipe" do
      with_repository do |repository, _output_path|
        _stdout, _stderr, status = cli(repository, "validate", "--input", "page-57",
                                       "--recipe", "latin", "--recipe-param",
                                       "skip_sequence=[]", "--expect-text",
                                       "experiments/expected/page-57-latin.txt")

        expect(status).not_to be_success
      end
    end

    it "accepts a whole-page Latin composition with an independent plaintext oracle" do
      with_repository do |repository, _output_path|
        _stdout, _stderr, status = cli(repository, "validate", *plaintext_options)

        expect(status).to be_success
      end
    end

    it "accepts the equivalent version-two YAML composition" do
      with_repository do |repository, _output_path|
        write_v2_definition(repository)

        _stdout, _stderr, status = cli(repository, "validate",
                                       "page-57-composed")

        expect(status).to be_success
      end
    end
  end

  describe "#execute" do
    it "assigns the same ad-hoc ID to implicit and explicit totient defaults" do
      with_repository do |repository, output_path|
        implicit = File.join(output_path, "implicit")
        explicit = File.join(output_path, "explicit")
        cli(repository, "run", *page_56_plaintext_options, "--output-path", implicit)
        cli(repository, "run", *page_56_plaintext_options,
            "--recipe-param", "modulus=29", "--recipe-param", "prime_start=2",
            "--recipe-param", "skip_sequence=[]", "--output-path", explicit)
        first = saved_records(implicit).find { |record| record["configuration"] }
        second = saved_records(explicit).find { |record| record["configuration"] }

        expect(second.fetch("experiment_id")).to eq(first.fetch("experiment_id"))
      end
    end

    it "keeps ad-hoc identity independent of parameter flag order" do
      with_repository do |repository, output_path|
        forward = File.join(output_path, "forward")
        reversed = File.join(output_path, "reversed")
        cli(repository, "run", *page_56_plaintext_options,
            "--recipe-param", "prime_start=3", "--recipe-param", "skip_sequence=[56]",
            "--output-path", forward)
        cli(repository, "run", *page_56_plaintext_options,
            "--recipe-param", "skip_sequence=[56]", "--recipe-param", "prime_start=3",
            "--output-path", reversed)
        first = saved_records(forward).find { |record| record["configuration"] }
        second = saved_records(reversed).find { |record| record["configuration"] }

        expect(second.fetch("experiment_id")).to eq(first.fetch("experiment_id"))
      end
    end

    it "resolves equivalent CLI and YAML totient parameters identically" do
      with_repository do |repository, output_path|
        definition = File.join(repository, "experiments/definitions/page-56-totient-controls.yml")
        FileUtils.cp("spec/fixtures/experiments/page_56_totient_controls.yml", definition)
        cli_path = File.join(output_path, "cli")
        yaml_path = File.join(output_path, "yaml")

        cli(repository, "run", *page_56_totient_options, "--output-path", cli_path)
        cli(repository, "run", "page-56-totient-controls", "--output-path", yaml_path)
        cli_record = saved_records(cli_path).find { |record| record["configuration"] }
        yaml_record = saved_records(yaml_path).find { |record| record["configuration"] }

        expect(cli_record.fetch("configuration").fetch("recipe")).to eq(
          yaml_record.fetch("configuration").fetch("recipe")
        )
      end
    end

    it "keeps non-GP separators while shifting a small page from prime 3" do
      with_repository do |repository, output_path|
        write_small_totient_definition(repository, "page-99", "moon-phase-control")

        cli(repository, "run", "moon-phase-control", "--output-path", output_path)
        outputs = Dir.glob("#{output_path}/**/output.txt").map { |path| File.binread(path) }

        expect(outputs).to eq(["f f 9A\ny"])
      end
    end

    it "distinguishes equal source bytes selected as different pages" do
      with_repository do |repository, output_path|
        write_small_totient_definition(repository, "page-98", "first-small-control")
        write_small_totient_definition(repository, "page-99", "second-small-control")
        first_path = File.join(output_path, "first")
        second_path = File.join(output_path, "second")

        cli(repository, "run", "first-small-control", "--output-path", first_path)
        cli(repository, "run", "second-small-control", "--output-path", second_path)
        first = saved_records(first_path).find { |record| record["configuration"] }
        second = saved_records(second_path).find { |record| record["configuration"] }

        expect(second.fetch("execution_identity")).not_to eq(first.fetch("execution_identity"))
      end
    end

    it "completes four independent page 56 checks" do
      with_repository do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "run", *page_56_totient_options,
                                        "--output-path", output_path)

        expect(stdout).to include("completed (matches: 4, mismatches: 0, errors: 0)")
      end
    end

    it "saves exactly one observation for the four page 56 checks" do
      with_repository do |repository, output_path|
        cli(repository, "run", *page_56_totient_options,
            "--output-path", output_path)

        observations = saved_records(output_path).select { |record| record["configuration"] }

        expect(observations.size).to eq(1)
      end
    end

    it "prints the generated identity of an ad-hoc composition" do
      with_repository do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "run", *plaintext_options,
                                       "--output-path", output_path)
        record = saved_records(output_path).fetch(0)

        expect(stdout).to include(
          "experiment ID: #{record.fetch('experiment_id')}\n"
        )
      end
    end

    it "reviews the saved ad-hoc attempt through the printed command" do
      with_repository do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "run", *plaintext_options,
                                       "--output-path", output_path)
        record = saved_records(output_path).fetch(0)
        command = stdout.lines.find { |line| line.start_with?("review: ") }
        argv = Shellwords.split(command.delete_prefix("review: "))

        review, _error, _status = cli(repository, *argv.drop(2))

        expect(review).to include(
          "#{record.fetch('experiment_id')} #{record.fetch('run_id')}: matched match"
        )
      end
    end

    it "prints the named version-two identity from the saved attempt" do
      with_repository do |repository, output_path|
        write_v2_definition(repository)

        stdout, _stderr, _status = cli(repository, "run", "page-57-composed",
                                       "--output-path", output_path)
        record = saved_records(output_path).fetch(0)

        expect(stdout).to include(
          "experiment ID: #{record.fetch('experiment_id')}\n"
        )
      end
    end

    it "reviews only the intended version-two attempt after a second run" do
      with_repository do |repository, output_path|
        write_v2_definition(repository)
        cli(repository, "run", "page-57-composed", "--output-path",
            output_path)
        first_id = saved_records(output_path).fetch(0).fetch("run_id")
        stdout, _stderr, _status = cli(repository, "run", "page-57-composed",
                                       "--output-path", output_path)
        record = saved_records(output_path).detect do |item|
          item.fetch("run_id") != first_id
        end
        command = stdout.lines.find { |line| line.start_with?("review: ") }
        argv = Shellwords.split(command.delete_prefix("review: "))

        review, _error, _status = cli(repository, *argv.drop(2))

        expect(review.scan(/^page-57-composed [^:]+: matched match$/)).to eq(
          ["page-57-composed #{record.fetch('run_id')}: matched match"]
        )
      end
    end

    it "retains the original version-one configuration and identity field" do
      with_repository do |repository, output_path|
        cli(repository, "run", "page-57-latin", "--output-path", output_path)

        record = saved_records(output_path).fetch(0)

        expect(record).to include(
          "schema_version" => 1,
          "configuration" => include("schema_version" => 1,
                                     "id" => "page-57-latin"),
          "execution_fingerprint" => match(/\A[0-9a-f]{64}\z/)
        )
      end
    end

    it "saves exact whole-page Latin bytes for an ad-hoc plaintext check" do
      with_repository do |repository, output_path|
        expected_path = File.join(repository,
                                  "experiments/expected/page-57-latin.txt")
        cli(repository, "run", *plaintext_options,
            "--output-path", output_path)

        outputs = Dir.glob("#{output_path}/**/output.txt").map do |path|
          File.binread(path)
        end

        expect(outputs).to eq([File.binread(expected_path)])
      end
    end

    it "saves version-two canonical choices and a distinct execution identity" do
      with_repository do |repository, output_path|
        cli(repository, "run", *plaintext_options,
            "--output-path", output_path)

        records = saved_records(output_path)

        expect(records).to contain_exactly(include(
          "schema_version" => 2,
          "configuration" => include(
            "input" => include("id" => "page-57"),
            "recipe" => include("id" => "latin"),
            "output" => { "policy" => "gp-latin-compatibility-v1" },
            "checks" => [include("strategy" => "plaintext")]
          ),
          "execution_identity" => match(/\A[0-9a-f]{64}\z/)
        ))
      end
    end

    it "normalizes equivalent CLI and YAML compositions to the same choices" do
      with_repository do |repository, output_path|
        write_v2_definition(repository)
        cli_runs = File.join(output_path, "cli")
        yaml_runs = File.join(output_path, "yaml")
        cli(repository, "run", *plaintext_options,
            "--output-path", cli_runs)
        cli(repository, "run", "page-57-composed", "--output-path",
            yaml_runs)

        choices = [cli_runs, yaml_runs].flat_map do |path|
          saved_records(path)
        end.map do |record|
          record.fetch("configuration").slice("input", "recipe", "output",
                                               "checks")
        end

        expect(choices).to eq([choices.first] * 2)
      end
    end

    it "keeps execution identity when only the check changes" do
      with_repository do |repository, output_path|
        plaintext_runs = File.join(output_path, "plaintext")
        hash_runs = File.join(output_path, "hash")
        cli(repository, "run", *plaintext_options,
            "--output-path", plaintext_runs)
        cli(repository, "run", "--input", "page-57", "--recipe", "latin",
            "--hash", "sha512", "--expect-digest", SHA512_DIGEST,
            "--output-path", hash_runs)

        identities = [plaintext_runs, hash_runs].flat_map do |path|
          saved_records(path)
        end.map do |record|
          record.fetch("execution_identity")
        end

        expect(identities).to eq([identities.first] * 2)
      end
    end

    it "matches the independently prepared SHA-512 digest without a hash preset" do
      with_repository do |repository, output_path|
        stdout, _stderr, _status = cli(
          repository, "run", "--input", "page-57", "--recipe", "latin",
          "--hash", "sha512", "--expect-digest", SHA512_DIGEST,
          "--output-path", output_path
        )

        expect(stdout).to include("matched (match)")
      end
    end
  end

  describe "#execute with multiple checks" do
    it "accumulates repeated hash flags and retains their declaration order" do
      with_repository do |repository, output_path|
        cli(repository, "run", "--input", "page-57", "--recipe", "latin",
            "--hash=sha512", "--hash", "blake2b512",
            "--expect-digest", "sha512=#{SHA512_DIGEST}",
            "--expect-digest=blake2b512=#{'0' * 128}",
            "--output-path", output_path)
        run = saved_records(output_path).find { |record| record["configuration"] }

        expect(run.fetch("configuration").fetch("checks").map { |check|
          [check.fetch("id"), check.fetch("algorithm")]
        }).to eq([["check-1", "sha512"], ["check-2", "blake2b512"]])
      end
    end

    it "reports a match after an earlier mismatch" do
      with_repository do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "run", "--input", "page-57",
                                       "--recipe", "latin", "--hash", "blake2b512",
                                      "--hash", "sha512", "--expect-digest",
                                      "blake2b512=#{'0' * 128}", "--expect-digest",
                                      "sha512=#{SHA512_DIGEST}",
                                      "--output-path", output_path)

        expect(stdout).to include("completed (matches: 1, mismatches: 1, errors: 0)",
                                  "matching outcome: matched", "check-1", "check-2")
      end
    end

    it "exits successfully after every comparison mismatches" do
      with_repository do |repository, output_path|
        _stdout, _stderr, status = cli(repository, "run", "--input", "page-57",
                                       "--recipe", "latin", "--hash", "sha512",
                                      "--hash", "blake2b512", "--expect-digest",
                                      '0' * 128, "--output-path", output_path)

        expect(status).to be_success
      end
    end

    it "reports every match with qualified digests" do
      with_repository do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "run", "--input", "page-57",
                                       "--recipe", "latin", "--hash", "sha512",
                                      "--hash", "blake2b512", "--expect-digest",
                                      "sha512=#{SHA512_DIGEST}", "--expect-digest",
                                      "blake2b512=#{BLAKE2B512_DIGEST}",
                                      "--output-path", output_path)

        expect(stdout).to include("completed (matches: 2, mismatches: 0, errors: 0)",
                                  "matching outcome: matched")
      end
    end

    it "canonicalizes equivalent shared and qualified expectations identically" do
      with_repository do |repository, output_path|
        shared_runs = File.join(output_path, "shared")
        qualified_runs = File.join(output_path, "qualified")
        common = ["run", "--input", "page-57", "--recipe", "latin",
                  "--hash", "sha512", "--hash", "blake2b512"]
        cli(repository, *common, "--expect-digest", SHA512_DIGEST,
            "--output-path", shared_runs)
        cli(repository, *common, "--expect-digest", "sha512=#{SHA512_DIGEST}",
            "--expect-digest", "blake2b512=#{SHA512_DIGEST}",
            "--output-path", qualified_runs)
        shared = saved_records(shared_runs).find { |record| record["configuration"] }
        qualified = saved_records(qualified_runs).find { |record| record["configuration"] }

        expect(shared.fetch("configuration").fetch("checks")).to eq(
          qualified.fetch("configuration").fetch("checks")
        )
      end
    end

    it "appends a plaintext check after hashes regardless of flag position" do
      with_repository do |repository, output_path|
        cli(repository, "run", "--input", "page-57", "--recipe", "latin",
            "--expect-text", "experiments/expected/page-57-latin.txt",
            "--hash", "sha512", "--hash", "blake2b512",
            "--expect-digest", SHA512_DIGEST, "--output-path", output_path)
        run = saved_records(output_path).find { |record| record["configuration"] }

        expect(run.fetch("configuration").fetch("checks").map { |check|
          [check.fetch("id"), check.fetch("strategy")]
        }).to eq([["check-1", "hash"], ["check-2", "hash"],
                 ["check-3", "plaintext"]])
      end
    end

  end

  describe "#validate with multiple checks" do
    it "rejects a duplicate selected algorithm" do
      with_repository do |repository, _output_path|
        _stdout, _stderr, status = cli(repository, "validate", "--input", "page-57",
                                       "--recipe", "latin", "--hash", "sha512",
                                       "--hash", "sha512", "--expect-digest",
                                       SHA512_DIGEST)

        expect(status).not_to be_success
      end
    end

    it "rejects a mixture of shared and qualified expectations" do
      with_repository do |repository, _output_path|
        _stdout, _stderr, status = cli(repository, "validate", "--input", "page-57",
                                       "--recipe", "latin", "--hash", "sha512",
                                       "--hash", "blake2b512", "--expect-digest",
                                       "sha512=#{SHA512_DIGEST}", "--expect-digest",
                                       SHA512_DIGEST)

        expect(status).not_to be_success
      end
    end

    it "rejects repeated plaintext oracle flags" do
      with_repository do |repository, _output_path|
        _stdout, _stderr, status = cli(repository, "validate", "--input", "page-57",
                                       "--recipe", "latin", "--expect-text",
                                       "experiments/expected/page-57-latin.txt",
                                       "--expect-text",
                                       "experiments/expected/page-57-latin.txt")

        expect(status).not_to be_success
      end
    end
  end

  describe "#execute collection records" do
    it "saves two relative assessment record references" do
      with_repository do |repository, output_path|
        cli(repository, "run", "--input", "page-57", "--recipe", "latin",
            "--hash", "sha512", "--hash", "blake2b512",
            "--expect-digest", SHA512_DIGEST, "--output-path", output_path)
        run = saved_records(output_path).find { |record| record["configuration"] }

        expect(run.fetch("assessment_records")).to contain_exactly(
          a_string_matching(%r{\Aassessments/[^/]+/record\.json\z}),
          a_string_matching(%r{\Aassessments/[^/]+/record\.json\z})
        )
      end
    end

    it "records an all-mismatch outcome separately from completed execution" do
      with_repository do |repository, output_path|
        cli(repository, "run", "--input", "page-57", "--recipe", "latin",
            "--hash", "sha512", "--hash", "blake2b512",
            "--expect-digest", '0' * 128, "--output-path", output_path)
        run = saved_records(output_path).find { |record| record["configuration"] }

        expect(run).to include("status" => "completed",
                               "comparison" => "not_applicable",
                               "matching_outcome" => "no_match",
                               "completion_summary" => {
                                 "match" => 0, "mismatch" => 2, "error" => 0
                               })
      end
    end

    it "gives distinct assessment IDs to repeated attempts on the same checks" do
      with_repository do |repository, output_path|
        arguments = ["run", "--input", "page-57", "--recipe", "latin",
                     "--hash", "sha512", "--hash", "blake2b512",
                     "--expect-digest", SHA512_DIGEST, "--output-path", output_path]
        cli(repository, *arguments)
        cli(repository, *arguments)
        records = saved_records(output_path).select { |record|
          record["assessment_id"]
        }

        expect(records.map { |record| record.fetch("assessment_id") }.uniq.length).to eq(4)
      end
    end
  end

  describe "#review of multiple checks" do
    it "reads every saved result after the current source and oracle disappear" do
      with_repository do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "run", "--input", "page-57",
                                       "--recipe", "latin", "--hash", "sha512",
                                       "--hash", "blake2b512", "--expect-digest",
                                       "sha512=#{SHA512_DIGEST}", "--expect-digest",
                                       "blake2b512=#{BLAKE2B512_DIGEST}",
                                       "--output-path", output_path)
        File.delete(File.join(repository, "data/encoded/liber_primus/page_57.yml"))
        File.delete(File.join(repository, "experiments/expected/page-57-latin.txt"))
        command = stdout.lines.find { |line| line.start_with?("review: ") }
        argv = Shellwords.split(command.delete_prefix("review: "))

        review, _error, _status = cli(repository, *argv.drop(2))

        expect(review).to include("check-1", "check-2", SHA512_DIGEST,
                                  BLAKE2B512_DIGEST)
      end
    end

    it "uses a shell-escaped review command for a path containing spaces" do
      with_repository do |repository, output_path|
        spaced_output = File.join(output_path, "runs with spaces")
        stdout, _stderr, _status = cli(repository, "run", "--input", "page-57",
                                       "--recipe", "latin", "--hash", "sha512",
                                       "--hash", "blake2b512", "--expect-digest",
                                       SHA512_DIGEST, "--output-path", spaced_output)
        command = stdout.lines.find { |line| line.start_with?("review: ") }
        argv = Shellwords.split(command.delete_prefix("review: "))

        review, _error, _status = cli(repository, *argv.drop(2))

        expect(review).to include("check-2")
      end
    end
  end

  describe "#review" do
    it "shows four saved page 56 matches after the named control runs" do
      with_repository do |repository, output_path|
        definition = File.join(repository, "experiments/definitions/page-56-totient-controls.yml")
        FileUtils.cp("spec/fixtures/experiments/page_56_totient_controls.yml", definition)
        cli(repository, "run", "page-56-totient-controls", "--output-path", output_path)

        review, _stderr, _status = cli(repository, "review", "page-56-totient-controls",
                                        "--output-path", output_path)

        expect(review).to include("checks: 4 matches, 0 mismatches, 0 errors")
      end
    end

    it "shows the saved strategy and literal SHA-512 comparison" do
      with_repository do |repository, output_path|
        _stdout, _stderr, _status = cli(
          repository, "run", "--input", "page-57", "--recipe", "latin",
          "--hash", "sha512", "--expect-digest", SHA512_DIGEST,
          "--output-path", output_path
        )
        experiment_ids = saved_records(output_path).map do |record|
          record.fetch("experiment_id")
        end

        review = experiment_ids.map do |experiment_id|
          cli(repository, "review", experiment_id,
              "--output-path", output_path).first
        end.join

        expect(review).to include("sha512", SHA512_DIGEST, "match")
      end
    end
  end
end
