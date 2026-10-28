require "json"
require "fileutils"
require "tmpdir"

RSpec.describe Primus::Experiment::CheckpointEvidence do
  include SavedCheckpointAnalysisHelper

  def evidence_for(output_path, id, run_id)
    path = File.join(output_path, id, run_id, "record.json")
    data = JSON.parse(File.binread(path))
    [described_class.new(record_path: path, data: data), data]
  end

  describe "#verify!" do
    it "returns nil as a verification command" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          evidence, _data = evidence_for(output_path, id, run_id)

          result = evidence.verify!

          expect(result).to be_nil
        end
      end
    end

    it "verifies every checkpoint from a relative record path" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |_output_path, id, run_id|
          relative_path = File.join("..", "runs", id, run_id, "record.json")
          data = JSON.parse(File.binread(relative_path))
          evidence = described_class.new(record_path: relative_path, data: data)

          result = evidence.verify!

          expect(result).to be_nil
        end
      end
    end

    it "accepts a leading dot on an equivalent relative record path" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |_output_path, id, run_id|
          relative_path = File.join(".", "..", "runs", id, run_id, "record.json")
          data = JSON.parse(File.binread(relative_path))
          evidence = described_class.new(record_path: relative_path, data: data)

          result = evidence.verify!

          expect(result).to be_nil
        end
      end
    end

    it "rejects a sibling artifact path through a relative record path" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |_output_path, id, run_id|
          relative_path = File.join("..", "runs", id, run_id, "record.json")
          data = JSON.parse(File.binread(relative_path))
          item = data.fetch("checkpoints")[1]
          item.fetch("output")["path"] = item.fetch("symbols").fetch("path")
          evidence = described_class.new(record_path: relative_path, data: data)

          action = -> { evidence.verify! }

          expect(action).to raise_error(described_class::Invalid)
        end
      end
    end

    it "rejects changed checkpoint bytes through a relative record path" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |_output_path, id, run_id|
          relative_path = File.join("..", "runs", id, run_id, "record.json")
          data = JSON.parse(File.binread(relative_path))
          artifact = data.fetch("checkpoints")[1].fetch("output").fetch("path")
          File.binwrite(artifact, "changed")
          evidence = described_class.new(record_path: relative_path, data: data)

          action = -> { evidence.verify! }

          expect(action).to raise_error(described_class::Invalid)
        end
      end
    end

    it "rejects a checkpoint symlink escaping the run through a relative path" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |_output_path, id, run_id|
          relative_path = File.join("..", "runs", id, run_id, "record.json")
          data = JSON.parse(File.binread(relative_path))
          artifact = data.fetch("checkpoints")[1].fetch("output").fetch("path")
          FileUtils.rm(artifact)
          File.symlink(File.expand_path("experiments/expected/synthetic-chain.txt"), artifact)
          evidence = described_class.new(record_path: relative_path, data: data)

          action = -> { evidence.verify! }

          expect(action).to raise_error(described_class::Invalid)
        end
      end
    end
  end

  describe "#checkpoint" do
    it "returns the already verified bytes of one declared step" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          evidence, _data = evidence_for(output_path, id, run_id)
          evidence.verify!

          snapshot = evidence.checkpoint("first")

          expect(snapshot.fetch("output_bytes").bytes).to eq("ᚱᚻ ᛁᛈ\n".bytes)
        end
      end
    end

    it "retains the checkpoint step identity" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          evidence, _data = evidence_for(output_path, id, run_id)
          evidence.verify!

          snapshot = evidence.checkpoint("letters")

          expect(snapshot.fetch("step_id")).to eq("letters")
        end
      end
    end

    it "owns selected bytes after the artifact changes" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          evidence, data = evidence_for(output_path, id, run_id)
          evidence.verify!
          artifact = data.fetch("checkpoints").first.fetch("output").fetch("path")
          File.binwrite(artifact, "changed")

          snapshot = evidence.checkpoint("original")

          expect(snapshot.fetch("output_bytes").bytes).to eq("ᚳᚻ ᛇᛒ\n".bytes)
        end
      end
    end

    it "exposes no partial snapshot after full-chain verification fails" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          evidence, data = evidence_for(output_path, id, run_id)
          artifact = data.fetch("checkpoints")[2].fetch("output").fetch("path")
          File.binwrite(artifact, "changed")
          begin
            evidence.verify!
          rescue described_class::Invalid
            nil
          end

          action = -> { evidence.checkpoint("original") }

          expect(action).to raise_error(described_class::Invalid)
        end
      end
    end
  end
end
