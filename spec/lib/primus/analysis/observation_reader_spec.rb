require "tmpdir"

RSpec.describe Primus::Analysis::ObservationReader do
  include SavedAnalysisHelper

  describe "#to_observation" do
    it "returns verified decoded GP symbols from the selected saved run" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)
        reader = Primus::Analysis::ObservationReader.new(
          output_path: root, experiment_id: experiment_id, run_id: run_id,
        )

        observation = reader.to_observation

        expect(observation.symbols("gp-runes-v1")).to eq(%w[ᚦ ᚪ ᚦ])
      end
    end

    it "returns canonical expanded Latin symbols from the same evidence" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)
        reader = Primus::Analysis::ObservationReader.new(
          output_path: root, experiment_id: experiment_id, run_id: run_id,
        )

        observation = reader.to_observation

        expect(observation.symbols("gp-expanded-latin-v1")).to eq(%w[t h a t h])
      end
    end

    it "returns captured record identity in its evidence snapshot" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)
        record_path = File.join(root, experiment_id, run_id, "record.json")
        expected_digest = Digest::SHA256.hexdigest(File.binread(record_path))
        reader = Primus::Analysis::ObservationReader.new(
          output_path: root, experiment_id: experiment_id, run_id: run_id,
        )

        observation = reader.to_observation

        expect(observation.evidence).to include(
          "observation_record_sha256" => expected_digest,
          "output_policy" => "gp-latin-compatibility-v1",
        )
      end
    end

    it "keeps verified symbols after the saved provenance file changes" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)
        reader = Primus::Analysis::ObservationReader.new(
          output_path: root, experiment_id: experiment_id, run_id: run_id,
        )
        observation = reader.to_observation
        path = File.join(root, experiment_id, run_id, "provenance.json")

        File.binwrite(path, "[]")

        expect(observation.symbols("gp-runes-v1")).to eq(%w[ᚦ ᚪ ᚦ])
      end
    end

    it "rejects corrupt output before returning any observation" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)
        output_path = File.join(root, experiment_id, run_id, "output.txt")
        File.binwrite(output_path, "changed")

        action = -> {
          Primus::Analysis::ObservationReader.new(
            output_path: root, experiment_id: experiment_id, run_id: run_id,
          ).to_observation
        }

        expect(action).to raise_error(Primus::Analysis::ObservationReader::Error)
      end
    end

    it "rejects a saved run without checkpoint metadata" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)
        path = File.join(root, experiment_id, run_id, "record.json")
        record = JSON.parse(File.binread(path))
        record.delete("checkpoints")
        File.binwrite(path, JSON.pretty_generate(record))

        action = -> {
          described_class.new(output_path: root, experiment_id: experiment_id,
                              run_id: run_id).to_observation
        }

        expect(action).to raise_error(described_class::Error)
      end
    end
  end
end
