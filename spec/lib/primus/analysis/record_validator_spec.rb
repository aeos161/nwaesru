RSpec.describe "Primus::Analysis::RecordValidator" do
  def running_record
    { "schema_version" => 1, "experiment_id" => "tiny-final",
      "run_id" => "20261009T000000-000000000001",
      "analysis_run_id" => "20261010T000000-000000000002",
      "status" => "running", "results" => [] }
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
  end
end
