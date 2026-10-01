require "open3"
require "rbconfig"
require "tmpdir"
require "json"

RSpec.describe "Primus::Commands::Experiments" do
  describe "validate" do
    it "accepts the tracked page 56 totient definition" do
      definition = "experiments/definitions/page-56-totient-latin.yml"

      _stdout, _stderr, status = Open3.capture3(
        RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "validate",
        definition
      )

      expect(status).to be_success
    end

    it "accepts a valid saved page 57 definition" do
      definition = "spec/fixtures/experiments/page_57_valid.yml"

      _stdout, _stderr, status = Open3.capture3(
        RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "validate",
        definition
      )

      expect(status).to be_success
    end

    it "reports duplicate YAML keys" do
      definition = "spec/fixtures/experiments/page_57_duplicate.yml"

      stdout, stderr, _status = Open3.capture3(
        RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "validate",
        definition
      )

      expect("#{stdout}#{stderr}").to match(/duplicate/i)
    end

    it "reports model validation failures by field" do
      definition = "spec/fixtures/experiments/page_57_unsupported.yml"

      stdout, stderr, _status = Open3.capture3(
        RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "validate",
        definition
      )

      expect("#{stdout}#{stderr}").to include("operation")
    end
  end

  describe "run" do
    it "matches the page 56 experiment through the command" do
      Dir.mktmpdir do |output_path|
        definition = "spec/fixtures/experiments/page_56_valid.yml"

        stdout, _stderr, _status = Open3.capture3(
          RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "run",
          definition, "--output-path", output_path
        )

        expect(stdout).to match(/matched \(match\)/)
      end
    end

    it "writes an attempt to the requested output directory" do
      Dir.mktmpdir do |output_path|
        definition = "spec/fixtures/experiments/page_57_valid.yml"

        _stdout, _stderr, _status = Open3.capture3(
          RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "run",
          definition, "--output-path", output_path
        )

        expect(Dir.glob("#{output_path}/**/record.json").size).to eq(1)
      end
    end

    it "reports a valid but mismatching oracle" do
      Dir.mktmpdir do |output_path|
        definition = "spec/fixtures/experiments/page_57_mismatch.yml"

        stdout, _stderr, _status = Open3.capture3(
          RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "run",
          definition, "--output-path", output_path
        )

        expect(stdout).to match(/mismatch/i)
      end
    end

    it "exits unsuccessfully for a valid but mismatching oracle" do
      Dir.mktmpdir do |output_path|
        definition = "spec/fixtures/experiments/page_57_mismatch.yml"

        _stdout, _stderr, status = Open3.capture3(
          RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "run",
          definition, "--output-path", output_path
        )

        expect(status).not_to be_success
      end
    end

    it "reports an invalid model by integrity category" do
      Dir.mktmpdir do |output_path|
        definition = "spec/fixtures/experiments/page_57_wrong_digest.yml"

        stdout, stderr, _status = Open3.capture3(
          RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "run",
          definition, "--output-path", output_path
        )
        message = "#{stdout}#{stderr}"

        expect(message).to match(/sha|digest/i)
      end
    end

    it "retains a failed definition load as an invalid attempt" do
      Dir.mktmpdir do |output_path|
        definition = "spec/fixtures/experiments/page_57_duplicate.yml"

        _stdout, _stderr, _status = Open3.capture3(
          RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "run",
          definition, "--output-path", output_path
        )
        records = Dir.glob("#{output_path}/**/record.json")
        saved_statuses = records.map do |path|
          JSON.parse(File.read(path)).fetch("status")
        end

        expect(saved_statuses).to eq(["invalid"])
      end
    end
  end

  describe "review" do
    it "reports a saved page 56 match by its own ID" do
      Dir.mktmpdir do |output_path|
        definition = "spec/fixtures/experiments/page_56_valid.yml"
        Open3.capture3(
          RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "run",
          definition, "--output-path", output_path
        )

        stdout, _stderr, _status = Open3.capture3(
          RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "review",
          "page-56-totient-latin", "--output-path", output_path
        )

        expect(stdout).to match(/page-56-totient-latin.*matched match/)
      end
    end

    it "reports the saved attempt by ID" do
      Dir.mktmpdir do |output_path|
        definition = "spec/fixtures/experiments/page_57_valid.yml"
        Open3.capture3(
          RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "run",
          definition, "--output-path", output_path
        )

        stdout, _stderr, _status = Open3.capture3(
          RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "review",
          "page-57-latin", "--output-path", output_path
        )

        expect(stdout).to include("page-57-latin", "match")
      end
    end

    it "identifies a missing saved output artifact" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(
          path: "spec/fixtures/experiments/page_57_valid.yml",
        )
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        runner.run
        record_path = Dir.glob("#{output_path}/**/record.json").fetch(0)
        record = JSON.parse(File.read(record_path))
        output = record.fetch("artifacts").fetch("output.txt").fetch("path")
        File.delete(output)

        stdout, stderr, _status = Open3.capture3(
          RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "review",
          "page-57-latin", "--output-path", output_path
        )

        message = "#{stdout}#{stderr}"

        expect(message).to match(/output\.txt.*missing|missing.*output\.txt/i)
      end
    end
  end
end
