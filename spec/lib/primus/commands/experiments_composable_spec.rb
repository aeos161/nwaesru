require "json"
require "open3"
require "rbconfig"
require "shellwords"
require "tmpdir"

RSpec.describe Primus::Commands::Experiments do
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

  describe "#review" do
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
