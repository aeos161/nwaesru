require "tmpdir"

RSpec.describe Primus::Experiment::Runner do
  def hash_experiment
    Primus::Experiment.load(
      path: "spec/fixtures/experiments/page_57_hash_valid.yml",
    )
  end

  def failing_evaluator
    evaluator = instance_double(Primus::Experiment::Evaluator)
    allow(Primus::Experiment::Evaluator).to receive(:new).and_return(evaluator)
    allow(evaluator).to receive(:assess).and_raise("test hash failure")
  end

  describe "#run" do
    it "surfaces a hash computation failure after a valid run begins" do
      Dir.mktmpdir do |output_path|
        runner = Primus::Experiment::Runner.new(experiment: hash_experiment,
                                                output_path: output_path)
        failing_evaluator

        expect { runner.run }.to raise_error(RuntimeError,
                                             "test hash failure")
      end
    end

    it "retains the produced Observation when hash evaluation fails" do
      Dir.mktmpdir do |output_path|
        runner = Primus::Experiment::Runner.new(experiment: hash_experiment,
                                                output_path: output_path)
        known_text = File.binread("experiments/expected/page-57-latin.txt")
        failing_evaluator

        begin
          runner.run
        rescue RuntimeError
          nil
        end

        expect(runner.observation.output_bytes).to eq(known_text)
      end
    end

    it "never records an execution error as a hash mismatch" do
      Dir.mktmpdir do |output_path|
        runner = Primus::Experiment::Runner.new(experiment: hash_experiment,
                                                output_path: output_path)
        failing_evaluator

        begin
          runner.run
        rescue RuntimeError
          nil
        end

        expect(runner.log_entry.data).to include(
          "status" => "error", "comparison" => "not_checked",
          "assessment" => nil
        )
      end
    end
  end
end
