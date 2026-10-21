require "tmpdir"

RSpec.describe Primus::Analysis::RecordValidator do
  include SavedAnalysisHelper

  def running_record
    { "schema_version" => 1, "experiment_id" => "tiny-final",
      "run_id" => "20261009T000000-000000000001",
      "analysis_run_id" => "20261010T000000-000000000002",
      "status" => "running", "results" => [] }
  end

  def completed_record(root)
    id, run_id = independent_three_rune_observation(root)
    observation = Primus::Analysis::ObservationReader.new(
      output_path: root, experiment_id: id, run_id: run_id
    ).to_observation
    definition = Primus::Analysis::Definition.new(
      path: "experiments/analyses/final-symbol-statistics.yml"
    )
    runner = Primus::Analysis::Runner.new(definition: definition, observation: observation)
    runner.run
    data = JSON.parse(JSON.generate(runner.log_entry.to_h))
    run_path = File.join(root, id, run_id, "record.json")
    run_record = JSON.parse(File.binread(run_path))
    data["checkpoint"] = run_record.fetch("checkpoints").last.merge(
      "requested_stage" => "final"
    )
    data
  end

  describe "#validate!" do
    it "accepts a retained running attempt with no measurements" do
      validator = Primus::Analysis::RecordValidator.new(running_record)

      action = -> { validator.validate! }

      expect(action).not_to raise_error
    end

    it "rejects an unsupported retained schema" do
      data = running_record.merge("schema_version" => 2)
      validator = Primus::Analysis::RecordValidator.new(data)

      action = -> { validator.validate! }

      expect(action).to raise_error(Primus::Analysis::RecordValidator::Error)
    end

    it "rejects an invalid analysis run identity" do
      data = running_record.merge("analysis_run_id" => "../outside")
      validator = Primus::Analysis::RecordValidator.new(data)

      action = -> { validator.validate! }

      expect(action).to raise_error(Primus::Analysis::RecordValidator::Error)
    end

    it "rejects a result whose representation disagrees with its envelope" do
      data = running_record
      data["status"] = "completed"
      data["results"] = [{
        "declaration_id" => "rune-statistics", "analyzer" => "symbol-statistics",
        "version" => 1, "stage" => "final", "representation" => "gp-runes-v1",
        "result" => { "representation" => "gp-expanded-latin-v1",
                      "sample_size" => 3, "frequencies" => [], "ic" => {} },
      }]
      validator = Primus::Analysis::RecordValidator.new(data)

      action = -> { validator.validate! }

      expect(action).to raise_error(Primus::Analysis::RecordValidator::Error)
    end

    it "rejects a requested checkpoint that contradicts its result stage" do
      Dir.mktmpdir do |root|
        data = completed_record(root)
        data.fetch("checkpoint")["requested_stage"] = "original"
        validator = described_class.new(data)

        action = -> { validator.validate! }

        expect(action).to raise_error(described_class::Error)
      end
    end

    it "rejects malformed selected output artifact metadata" do
      Dir.mktmpdir do |root|
        data = completed_record(root)
        data.fetch("checkpoint").fetch("output")["bytes"] = -1
        validator = described_class.new(data)

        action = -> { validator.validate! }

        expect(action).to raise_error(described_class::Error)
      end
    end

    it "rejects a profile tied to a different checkpoint stage" do
      Dir.mktmpdir do |root|
        data = completed_record(root)
        data.fetch("results").first.fetch("profile")["stage"] = "original"
        validator = described_class.new(data)

        action = -> { validator.validate! }

        expect(action).to raise_error(described_class::Error)
      end
    end
  end
end
