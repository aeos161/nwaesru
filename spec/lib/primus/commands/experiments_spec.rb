require "fileutils"
require "json"
require "open3"
require "rbconfig"
require "shellwords"
require "tmpdir"

RSpec.describe Primus::Commands::Experiments do
  def cli(repository, *arguments)
    Open3.capture3(RbConfig.ruby, "-Ilib", "bin/primus", "experiments",
                   *arguments, chdir: repository)
  end

  def clone_repository(repository)
    _out, error, status = Open3.capture3(
      "git", "clone", "--quiet", "--local", "--no-hardlinks", Dir.pwd,
      repository
    )
    raise "Test repository clone failed: #{error}" unless status.success?
  end

  def install_fixture(repository, fixture)
    source = File.join(repository, "spec/fixtures/experiments", fixture)
    destination = File.join(repository,
                            "experiments/definitions/page-57-latin.yml")
    FileUtils.cp(source, destination)
  end

  def prepare_checkout(directory, fixture)
    repository = File.join(directory, "repo")
    clone_repository(repository)
    install_fixture(repository, fixture) if fixture
    repository
  end

  def with_checkout(fixture = nil)
    Dir.mktmpdir do |directory|
      repository = prepare_checkout(directory, fixture)
      yield repository, File.join(directory, "runs")
    end
  end

  def ignore_thor_error
    yield
  rescue Thor::Error
    nil
  end

  def records(output_path)
    Dir.glob("#{output_path}/**/record.json").map do |path|
      JSON.parse(File.binread(path))
    end
  end

  describe "#validate" do
    it "accepts the tracked page 56 ID" do
      _out, _err, status = cli(Dir.pwd, "validate", "page-56-totient-latin")

      expect(status).to be_success
    end

    it "accepts the tracked page 57 ID" do
      _out, _err, status = cli(Dir.pwd, "validate", "page-57-latin")

      expect(status).to be_success
    end

    it "does not retain an attempt for successful validation" do
      with_checkout do |repository, _output_path|
        cli(repository, "validate", "page-57-latin")

        saved = Dir.glob("#{repository}/experiments/runs/**/record.json")

        expect(saved).to be_empty
      end
    end

    it "reports duplicate YAML keys at the conventional path" do
      with_checkout("page_57_duplicate.yml") do |repository, _output_path|
        stdout, stderr, _status = cli(repository, "validate", "page-57-latin")

        expect("#{stdout}#{stderr}").to match(/duplicate/i)
      end
    end

    it "reports unsupported recipes through model validation" do
      with_checkout("page_57_unsupported.yml") do |repository, _output_path|
        stdout, stderr, _status = cli(repository, "validate", "page-57-latin")

        expect("#{stdout}#{stderr}").to include("operation")
      end
    end

    it "rejects a definition declaring another supported ID" do
      with_checkout do |repository, _output_path|
        path = File.join(repository,
                         "experiments/definitions/page-57-latin.yml")
        File.write(path, File.read(path).sub("id: page-57-latin",
                                             "id: page-56-totient-latin"))

        _stdout, _stderr, status = cli(repository, "validate", "page-57-latin")

        expect(status).not_to be_success
      end
    end

    it "rejects missing declared IDs" do
      with_checkout do |repository, _output_path|
        path = File.join(repository,
                         "experiments/definitions/page-57-latin.yml")
        File.write(path, File.read(path).sub("id: page-57-latin\n", ""))

        _stdout, _stderr, status = cli(repository, "validate", "page-57-latin")

        expect(status).not_to be_success
      end
    end

    it "rejects a safe unknown ID with no conventional definition" do
      _stdout, _stderr, status = cli(Dir.pwd, "validate", "unknown-recipe")

      expect(status).not_to be_success
    end

    it "rejects unsafe IDs before loading a definition" do
      command = Primus::Commands::Experiments.new
      allow(Primus::Experiment).to receive(:load).and_call_original

      ["", "Page-57-latin", "page_57", "page.57", "page-57.yml",
       " page-57", "page-57 ", "../page-57", "foo/bar", "/tmp/foo",
       "page-*", "page?57", "page--57"].each do |id|
        ignore_thor_error { command.validate(id) }
      end

      expect(Primus::Experiment).not_to have_received(:load)
    end

    it "does not validate a definition declaring another ID" do
      experiment = instance_double(Primus::Experiment, id: "another-id",
                                                       errors: [])
      allow(Primus::Experiment).to receive(:load).and_return(experiment)
      allow(experiment).to receive(:valid?).and_return(false)
      command = Primus::Commands::Experiments.new

      ignore_thor_error { command.validate("page-57-latin") }

      expect(experiment).not_to have_received(:valid?)
    end

    it "advertises ID arguments in Thor help" do
      stdout, _stderr, _status = cli(Dir.pwd, "help")

      expect(stdout).to include("validate ID", "run ID", "review ID [RUN_ID]")
    end
  end

  describe "#execute" do
    it "keeps the saved status as the first output line" do
      with_checkout do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "run", "page-57-latin",
                                       "--output-path", output_path)
        run_id = records(output_path).fetch(0).fetch("run_id")

        expect(stdout.lines.first).to eq("#{run_id}: matched (match)\n")
      end
    end

    it "prints the saved identities and a direct review command in order" do
      with_checkout do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "run", "page-57-latin",
                                       "--output-path", output_path)
        record = records(output_path).fetch(0)
        run_id = record.fetch("run_id")
        experiment_id = record.fetch("experiment_id")

        expect(stdout.lines.drop(1)).to eq([
          "experiment ID: #{experiment_id}\n",
          "run ID: #{run_id}\n",
          "review: bin/primus experiments review #{experiment_id} " \
            "#{run_id} --output-path #{output_path}\n"
        ])
      end
    end

    it "makes the default output store explicit in the review command" do
      with_checkout do |repository, _output_path|
        stdout, _stderr, _status = cli(repository, "run", "page-57-latin")
        record = records(File.join(repository, "experiments/runs")).fetch(0)

        expect(stdout).to include(
          "review: bin/primus experiments review page-57-latin " \
            "#{record.fetch('run_id')} --output-path experiments/runs\n"
        )
      end
    end

    it "preserves and shell-escapes a relative path with shell characters" do
      with_checkout do |repository, _output_path|
        path = "runs with spaces/it's $money;done"
        stdout, _stderr, _status = cli(repository, "run", "page-57-latin",
                                       "--output-path", path)
        record = records(File.join(repository, path)).fetch(0)

        expect(stdout).to include(
          "review: bin/primus experiments review page-57-latin " \
            "#{record.fetch('run_id')} --output-path " \
            "runs\\ with\\ spaces/it\\'s\\ \\$money\\;done\n"
        )
      end
    end

    it "selects the saved attempt through its printed review command" do
      with_checkout do |repository, _output_path|
        output_path = "runs with spaces/it's $money;done"
        cli(repository, "run", "page-57-latin", "--output-path", output_path)
        stdout, _stderr, _status = cli(repository, "run", "page-57-latin",
                                       "--output-path", output_path,
                                       "--rerun", "--reason", "Compare again")
        record = records(File.join(repository, output_path)).detect do |item|
          item["rerun_reason"]
        end
        command = stdout.lines.find { |line| line.start_with?("review: ") }
        argv = Shellwords.split(command.delete_prefix("review: "))

        review, _error, _status = cli(repository, *argv.drop(2))

        expect(review.scan(/^page-57-latin [^:]+: matched match$/)).to eq(
          ["page-57-latin #{record.fetch('run_id')}: matched match"]
        )
      end
    end

    it "prints the returned prior attempt ID on a deduplicated run" do
      with_checkout do |repository, output_path|
        cli(repository, "run", "page-57-latin", "--output-path", output_path)
        prior_id = records(output_path).fetch(0).fetch("run_id")

        stdout, _stderr, _status = cli(repository, "run", "page-57-latin",
                                       "--output-path", output_path)

        expect(stdout).to include("run ID: #{prior_id}\n")
      end
    end

    it "prints the new attempt ID on a forced rerun" do
      with_checkout do |repository, output_path|
        cli(repository, "run", "page-57-latin", "--output-path", output_path)

        stdout, _stderr, _status = cli(repository, "run", "page-57-latin",
                                       "--output-path", output_path,
                                       "--rerun", "--reason", "Compare again")
        rerun = records(output_path).detect { |item| item["rerun_reason"] }

        expect(stdout).to include("run ID: #{rerun.fetch('run_id')}\n")
      end
    end

    it "prints reviewable identities before the mismatch error" do
      with_checkout("page_57_mismatch.yml") do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "run", "page-57-latin",
                                       "--output-path", output_path)
        record = records(output_path).fetch(0)

        expect(stdout).to include(
          "experiment ID: page-57-latin\nrun ID: #{record.fetch('run_id')}\n"
        )
      end
    end

    it "prints reviewable identities before the invalid-result error" do
      with_checkout("page_57_wrong_digest.yml") do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "run", "page-57-latin",
                                       "--output-path", output_path)
        record = records(output_path).fetch(0)

        expect(stdout).to include(
          "experiment ID: page-57-latin\nrun ID: #{record.fetch('run_id')}\n"
        )
      end
    end

    it "prints the identity of a returned recorded execution error" do
      with_checkout do |repository, output_path|
        cli(repository, "run", "page-57-latin", "--output-path", output_path)
        path = Dir.glob("#{output_path}/**/record.json").fetch(0)
        record = JSON.parse(File.read(path))
        record["status"] = "error"
        record["comparison"] = "not_checked"
        record["errors"] = [{ "stage" => "execution",
                              "message" => "translator failed" }]
        File.write(path, JSON.generate(record))

        stdout, _stderr, _status = cli(repository, "run", "page-57-latin",
                                       "--output-path", output_path)

        expect(stdout).to include("run ID: #{record.fetch('run_id')}\n")
      end
    end

    it "does not invent an identity for a failed definition load" do
      with_checkout("page_57_duplicate.yml") do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "run", "page-57-latin",
                                       "--output-path", output_path)

        expect(stdout).not_to include("experiment ID:", "run ID:",
                                      "review:")
      end
    end

    it "matches page 56 using its ID" do
      with_checkout do |repository, output_path|
        stdout, _stderr, _status = cli(
          repository, "run", "page-56-totient-latin", "--output-path",
          output_path
        )

        expect(stdout).to match(/matched \(match\)/)
      end
    end

    it "matches page 57 using its ID" do
      with_checkout do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "run", "page-57-latin",
                                       "--output-path", output_path)

        expect(stdout).to match(/matched \(match\)/)
      end
    end

    it "writes an ID-keyed attempt to the requested output directory" do
      with_checkout do |repository, output_path|
        cli(repository, "run", "page-57-latin", "--output-path", output_path)

        expect(records(output_path).first.fetch("experiment_id")).
          to eq("page-57-latin")
      end
    end

    it "reuses an identical execution" do
      with_checkout do |repository, output_path|
        2.times do
          cli(repository, "run", "page-57-latin", "--output-path", output_path)
        end

        expect(records(output_path).size).to eq(1)
      end
    end

    it "rejects rerun without a nonblank reason" do
      with_checkout do |repository, output_path|
        stdout, stderr, _status = cli(repository, "run", "page-57-latin",
                                      "--output-path", output_path, "--rerun",
                                      "--reason", " ")

        expect("#{stdout}#{stderr}").to match(/reason/i)
      end
    end

    it "retains a prior-run link for an intentional rerun" do
      with_checkout do |repository, output_path|
        cli(repository, "run", "page-57-latin", "--output-path", output_path)
        cli(repository, "run", "page-57-latin", "--output-path", output_path,
            "--rerun", "--reason", "Compare again")
        attempts = records(output_path)
        prior_id = attempts.detect { |record| record["rerun_reason"].nil? }.
                   fetch("run_id")
        rerun = attempts.detect { |record| record["rerun_reason"] }

        expect(rerun && rerun.fetch("previous_run_ids")).to include(prior_id)
      end
    end

    it "retains a mismatched attempt for a valid wrong oracle" do
      with_checkout("page_57_mismatch.yml") do |repository, output_path|
        cli(repository, "run", "page-57-latin", "--output-path", output_path)

        expect(records(output_path).map { |record| record["status"] }).
          to eq(["mismatched"])
      end
    end

    it "exits unsuccessfully for a valid wrong oracle" do
      with_checkout("page_57_mismatch.yml") do |repository, output_path|
        _out, _err, status = cli(repository, "run", "page-57-latin",
                                 "--output-path", output_path)

        expect(status).not_to be_success
      end
    end

    it "records a wrong digest through model validation" do
      with_checkout("page_57_wrong_digest.yml") do |repository, output_path|
        cli(repository, "run", "page-57-latin", "--output-path", output_path)

        stages = records(output_path).first.fetch("errors").map do |error|
          error.fetch("stage")
        end

        expect(stages).to include("integrity")
      end
    end

    it "retains duplicate YAML as a failed load" do
      with_checkout("page_57_duplicate.yml") do |repository, output_path|
        cli(repository, "run", "page-57-latin", "--output-path", output_path)

        expect(records(output_path).map { |record| record["status"] }).
          to eq(["invalid"])
      end
    end

    it "records the actual conventional definition path for a failed load" do
      with_checkout("page_57_duplicate.yml") do |repository, output_path|
        cli(repository, "run", "page-57-latin", "--output-path", output_path)

        expect(records(output_path).first.fetch("definition_path")).
          to eq("experiments/definitions/page-57-latin.yml")
      end
    end

    it "snapshots exact malformed definition bytes" do
      with_checkout("page_57_duplicate.yml") do |repository, output_path|
        source = File.join(repository,
                           "experiments/definitions/page-57-latin.yml")
        cli(repository, "run", "page-57-latin", "--output-path", output_path)
        snapshot = records(output_path).first.fetch("artifacts").
                   dig("definition.yml", "path")

        expect(snapshot && File.binread(snapshot)).to eq(File.binread(source))
      end
    end

    it "records a declared ID mismatch as a failed load" do
      with_checkout do |repository, output_path|
        path = File.join(repository,
                         "experiments/definitions/page-57-latin.yml")
        File.write(path, File.read(path).sub("id: page-57-latin",
                                             "id: page-56-totient-latin"))

        cli(repository, "run", "page-57-latin", "--output-path", output_path)

        expect(records(output_path).first.fetch("errors").first.fetch("stage")).
          to eq("definition")
      end
    end

    it "records the resolved path for a safe unknown ID" do
      with_checkout do |repository, output_path|
        cli(repository, "run", "unknown-recipe", "--output-path", output_path)

        expect(records(output_path).first.fetch("definition_path")).
          to eq("experiments/definitions/unknown-recipe.yml")
      end
    end

    it "rejects unsafe IDs before creating a Store" do
      Dir.mktmpdir do |output_path|
        command = Primus::Commands::Experiments.new(
          [], { output_path: output_path }
        )
        allow(Primus::Experiment::Store).to receive(:new).and_call_original

        ["", "Page-57", "a/b", "../page-57", "page-57.yml",
         "page*57"].each do |id|
          ignore_thor_error { command.execute(id) }
        end

        expect(Primus::Experiment::Store).not_to have_received(:new)
      end
    end
  end

  describe "#review" do
    it "shows the planned title when no attempts exist" do
      with_checkout do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "review", "page-57-latin",
                                       "--output-path", output_path)

        title = "Transform page 57 from runes to Latin characters"

        expect(stdout).to include(title)
      end
    end

    it "shows planned details without model validation" do
      with_checkout("page_57_unsupported.yml") do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "review", "page-57-latin",
                                       "--output-path", output_path)

        title = "Transform page 57 from runes to Latin characters"

        expect(stdout).to include(title)
      end
    end

    it "rejects planned display when the declaration has another ID" do
      with_checkout do |repository, output_path|
        path = File.join(repository,
                         "experiments/definitions/page-57-latin.yml")
        changed = File.read(path).sub("id: page-57-latin", "id: other-id")
        File.write(path, changed)

        _stdout, _stderr, status = cli(repository, "review", "page-57-latin",
                                       "--output-path", output_path)

        expect(status).not_to be_success
      end
    end

    it "reports a missing planned definition as a command error" do
      with_checkout do |repository, output_path|
        File.delete(File.join(repository,
                              "experiments/definitions/page-57-latin.yml"))

        _stdout, _stderr, status = cli(repository, "review", "page-57-latin",
                                       "--output-path", output_path)

        expect(status).not_to be_success
      end
    end

    it "shows retained history when the live definition is absent" do
      with_checkout do |repository, output_path|
        cli(repository, "run", "page-57-latin", "--output-path", output_path)
        File.delete(File.join(repository,
                              "experiments/definitions/page-57-latin.yml"))

        _stdout, _stderr, status = cli(repository, "review", "page-57-latin",
                                       "--output-path", output_path)

        expect(status).to be_success
      end
    end

    it "shows retained history when the live definition is malformed" do
      with_checkout do |repository, output_path|
        cli(repository, "run", "page-57-latin", "--output-path", output_path)
        path = File.join(repository,
                         "experiments/definitions/page-57-latin.yml")
        File.write(path, "id: [\n")

        _stdout, _stderr, status = cli(repository, "review", "page-57-latin",
                                       "--output-path", output_path)

        expect(status).to be_success
      end
    end

    it "shows retained history when the live definition declares another ID" do
      with_checkout do |repository, output_path|
        cli(repository, "run", "page-57-latin", "--output-path", output_path)
        path = File.join(repository,
                         "experiments/definitions/page-57-latin.yml")
        File.write(path,
                   File.read(path).sub("id: page-57-latin", "id: other-id"))

        stdout, _stderr, _status = cli(repository, "review", "page-57-latin",
                                       "--output-path", output_path)
        run_id = records(output_path).first.fetch("run_id")

        expect(stdout).to include(run_id)
      end
    end

    it "selects a retained attempt by RUN_ID" do
      with_checkout do |repository, output_path|
        cli(repository, "run", "page-57-latin", "--output-path", output_path)
        run_id = records(output_path).first.fetch("run_id")

        stdout, _stderr, _status = cli(repository, "review", "page-57-latin",
                                       run_id, "--output-path", output_path)

        expect(stdout).to include(run_id)
      end
    end

    it "does not fall back to planned display for an unknown RUN_ID" do
      with_checkout do |repository, output_path|
        _stdout, _stderr, status = cli(repository, "review", "page-57-latin",
                                       "unknown-run", "--output-path",
                                       output_path)

        expect(status).not_to be_success
      end
    end

    it "rejects unsafe IDs before consulting Store" do
      command = Primus::Commands::Experiments.new([], { output_path: "unused" })
      allow(Primus::Experiment::Store).to receive(:new).and_call_original

      ["", "Page-57", "../page-57", "page-57.yml", "page*57"].each do |id|
        ignore_thor_error { command.review(id) }
      end

      expect(Primus::Experiment::Store).not_to have_received(:new)
    end
  end
end
