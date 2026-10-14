require "tmpdir"

RSpec.describe "Primus::Analysis::Runner" do
  include SavedAnalysisHelper

  def runner_for(root)
    experiment_id, run_id = independent_three_rune_observation(root)
    observation = Primus::Analysis::ObservationReader.new(
      output_path: root, experiment_id: experiment_id, run_id: run_id,
    ).to_observation
    definition = Primus::Analysis::Definition.new(
      path: "experiments/analyses/final-symbol-statistics.yml",
    )
    Primus::Analysis::Runner.new(definition: definition, observation: observation)
  end

  describe "#run" do
    it "remains a nil-returning command" do
      Dir.mktmpdir do |root|
        runner = runner_for(root)

        returned = runner.run

        expect(returned).to be_nil
      end
    end
  end

  describe "#log_entry" do
    it "exposes the completed execution status" do
      Dir.mktmpdir do |root|
        runner = runner_for(root)
        runner.run

        status = runner.log_entry.status

        expect(status).to eq("completed")
      end
    end

    it "exposes separate rune and expanded-Latin measurements" do
      Dir.mktmpdir do |root|
        runner = runner_for(root)
        runner.run

        sizes = runner.log_entry.measurements.map(&:sample_size)

        expect(sizes).to eq([3, 5])
      end
    end

    it "does not claim unsaved completion after persistence fails" do
      Dir.mktmpdir do |root|
        runner = runner_for(root)
        directory = File.join(root, "tiny-final", "20261009T000000-000000000001")
        File.write(File.join(directory, "analyses"), "not a directory")

        begin
          runner.run
        rescue Primus::Analysis::Store::Error
          nil
        end

        expect(runner.log_entry&.status).not_to eq("completed")
      end
    end
  end
end
