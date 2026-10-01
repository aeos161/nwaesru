require "tmpdir"
require "json"

RSpec.describe "page 57 experiment failures" do
  def fixture(name)
    "spec/fixtures/experiments/#{name}"
  end

  context "with a stale source digest" do
    it "returns nil for an invalid run command" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(
          path: fixture("page_57_wrong_digest.yml"),
        )
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)

        command_return = runner.run

        expect(command_return).to be_nil
      end
    end

    it "does not execute an earlier invalid attempt again" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(
          path: fixture("page_57_wrong_digest.yml"),
        )
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        runner.run
        runner.run

        expect(Dir.glob("#{output_path}/**/record.json").size).to eq(1)
      end
    end

    it "persists model errors without a scientific result" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(
          path: fixture("page_57_wrong_digest.yml"),
        )
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)

        runner.run
        path = Dir.glob("#{output_path}/**/record.json").fetch(0)
        saved = JSON.parse(File.read(path))

        expect(saved).to include("status" => "invalid",
                                 "comparison" => "not_checked",
                                 "observation" => nil,
                                 "assessment" => nil,
                                 "errors" => [include("stage" => "integrity")])
      end
    end
  end

  context "with a different valid plaintext oracle" do
    it "assesses the valid run as a mismatch" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(
          path: fixture("page_57_mismatch.yml"),
        )
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)

        runner.run

        expect(runner.assessment.comparison).to eq("mismatch")
      end
    end

    it "retains the independent oracle artifact" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(
          path: fixture("page_57_mismatch.yml"),
        )
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)

        runner.run
        path = Dir.glob("#{output_path}/**/record.json").fetch(0)
        artifacts = JSON.parse(File.read(path)).fetch("artifacts")
        expected = File.binread(artifacts.fetch("expected.txt").fetch("path"))

        expect(expected).to eq("wrong")
      end
    end

    it "retains the actual output artifact" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(
          path: fixture("page_57_mismatch.yml"),
        )
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)

        runner.run
        path = Dir.glob("#{output_path}/**/record.json").fetch(0)
        artifacts = JSON.parse(File.read(path)).fetch("artifacts")
        actual = File.binread(artifacts.fetch("output.txt").fetch("path"))

        expect(actual).to start_with("parable")
      end
    end
  end
end
