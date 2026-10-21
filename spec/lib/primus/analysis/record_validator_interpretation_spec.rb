require "json"
require "open3"
require "tmpdir"

RSpec.describe Primus::Analysis::RecordValidator do
  include SavedAnalysisHelper

  def completed_record(root)
    experiment_id, run_id = independent_three_rune_observation(root)
    _stdout, stderr, status = Open3.capture3(
      "bin/primus", "analyses", "run", experiment_id, run_id,
      "--definition", "experiments/analyses/final-symbol-statistics.yml",
      "--output-path", root,
    )
    raise stderr unless status.success?
    path = Dir.glob(File.join(root, experiment_id, run_id,
                              "analyses", "*", "record.json")).fetch(0)
    JSON.parse(File.binread(path))
  end

  def first_interpretation(record)
    record.fetch("results").first.fetch("result").fetch("interpretation")
  end

  describe "#validate!" do
    it "rejects an unsupported present interpretation version" do
      Dir.mktmpdir do |root|
        record = completed_record(root)
        first_interpretation(record)["schema_version"] = 999

        action = -> { described_class.new(record).validate! }

        expect(action).to raise_error(described_class::Error)
      end
    end

    it "rejects a present interpretation for another representation" do
      Dir.mktmpdir do |root|
        record = completed_record(root)
        first_interpretation(record)["representation"] = "gp-expanded-latin-v1"

        action = -> { described_class.new(record).validate! }

        expect(action).to raise_error(described_class::Error)
      end
    end

    it "rejects a present interpretation for another sample size" do
      Dir.mktmpdir do |root|
        record = completed_record(root)
        first_interpretation(record)["sample_size"] = 999

        action = -> { described_class.new(record).validate! }

        expect(action).to raise_error(described_class::Error)
      end
    end

    it "rejects a nonfinite numeric value in a present interpretation" do
      Dir.mktmpdir do |root|
        record = completed_record(root)
        differences = first_interpretation(record).fetch("differences")
        differences.values.first["numerator"] = Float::NAN

        action = -> { described_class.new(record).validate! }

        expect(action).to raise_error(described_class::Error)
      end
    end

    it "rejects a present interpretation with missing control provenance" do
      Dir.mktmpdir do |root|
        record = completed_record(root)
        first_interpretation(record).delete("provenance_digest")

        action = -> { described_class.new(record).validate! }

        expect(action).to raise_error(described_class::Error)
      end
    end

    it "rejects an impossible status and judgment combination" do
      Dir.mktmpdir do |root|
        record = completed_record(root)
        first_interpretation(record)["judgment_code"] = "insufficient_sample"

        action = -> { described_class.new(record).validate! }

        expect(action).to raise_error(described_class::Error)
      end
    end
  end
end
