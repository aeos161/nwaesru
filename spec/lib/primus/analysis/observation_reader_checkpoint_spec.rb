require "json"
require "tmpdir"

RSpec.describe Primus::Analysis::ObservationReader do
  include SavedCheckpointAnalysisHelper

  def reader(output_path, id, run_id, stage)
    described_class.new(output_path: output_path, experiment_id: id,
                        run_id: run_id, stage: stage)
  end

  def run_record(output_path, id, run_id)
    path = File.join(output_path, id, run_id, "record.json")
    [path, JSON.parse(File.binread(path))]
  end

  def rewrite_checkpoint_coordinates(path, record)
    record.fetch("checkpoints").each do |checkpoint|
      %w[symbols lexemes].each do |kind|
        artifact = checkpoint.fetch(kind)
        rows = JSON.parse(File.binread(artifact.fetch("path")))
        yield kind, rows
        bytes = JSON.pretty_generate(rows)
        File.binwrite(artifact.fetch("path"), bytes)
        artifact["bytes"] = bytes.bytesize
        artifact["sha256"] = Digest::SHA256.hexdigest(bytes)
      end
    end
    File.binwrite(path, JSON.pretty_generate(record))
  end

  describe "#to_observation" do
    it "returns original captured GP symbols" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          selection = reader(output_path, id, run_id, "original")

          observation = selection.to_observation

          expect(observation.symbols("gp-runes-v1")).to eq(%w[ᚳ ᚻ ᛇ ᛒ])
        end
      end
    end

    it "returns canonical expanded Latin from the selected rune rows" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          selection = reader(output_path, id, run_id, "second")

          observation = selection.to_observation

          expect(observation.symbols("gp-expanded-latin-v1")).to eq(%w[t h r i w])
        end
      end
    end

    it "reads a transformed checkpoint without rerunning its operation" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          allow(Primus::Document::TotientShift).to receive(:new).and_raise("transformation reran")
          selection = reader(output_path, id, run_id, "first")

          observation = selection.to_observation

          expect(observation.symbols("gp-runes-v1")).to eq(%w[ᚱ ᚻ ᛁ ᛈ])
        end
      end
    end

    it "keeps the original capture distinct after its source file disappears" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          _path, record = run_record(output_path, id, run_id)
          File.delete(record.fetch("source_path"))
          selection = reader(output_path, id, run_id, "original")

          observation = selection.to_observation

          expect(observation.symbols("gp-runes-v1")).to eq(%w[ᚳ ᚻ ᛇ ᛒ])
        end
      end
    end

    it "rejects corruption in an unselected sibling checkpoint" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          _path, record = run_record(output_path, id, run_id)
          sibling = record.fetch("checkpoints").find { |item| item.fetch("step_id") == "second" }
          File.binwrite(sibling.fetch("symbols").fetch("path"), "[]")
          selection = reader(output_path, id, run_id, "original")

          action = -> { selection.to_observation }

          expect(action).to raise_error(described_class::Error)
        end
      end
    end

    it "rejects duplicate keys in selected checkpoint JSON despite updated metadata" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          path, record = run_record(output_path, id, run_id)
          artifact = record.fetch("checkpoints").first.fetch("symbols")
          bytes = File.binread(artifact.fetch("path"))
          changed = bytes.sub('"ordinal": 0,', '"ordinal": 0, "ordinal": 0,')
          File.binwrite(artifact.fetch("path"), changed)
          artifact["bytes"] = changed.bytesize
          artifact["sha256"] = Digest::SHA256.hexdigest(changed)
          File.binwrite(path, JSON.pretty_generate(record))
          selection = reader(output_path, id, run_id, "original")

          action = -> { selection.to_observation }

          expect(action).to raise_error(described_class::Error)
        end
      end
    end

    it "rejects noninteger source coordinates across an otherwise coherent chain" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          path, record = run_record(output_path, id, run_id)
          rewrite_checkpoint_coordinates(path, record) do |kind, rows|
            key = kind == "symbols" ? "page_number" : "source_page_number"
            rows[1][key] = "99"
          end
          selection = reader(output_path, id, run_id, "original")

          action = -> { selection.to_observation }

          expect(action).to raise_error(described_class::Error)
        end
      end
    end

    it "rejects duplicated source rune identities across an otherwise coherent chain" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          path, record = run_record(output_path, id, run_id)
          rewrite_checkpoint_coordinates(path, record) do |kind, rows|
            key = kind == "symbols" ? "rune_index" : "source_rune_index"
            rows[1][key] = 0
          end
          selection = reader(output_path, id, run_id, "original")

          action = -> { selection.to_observation }

          expect(action).to raise_error(described_class::Error)
        end
      end
    end

    it "does not reopen selected symbol bytes after verification" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          _path, record = run_record(output_path, id, run_id)
          artifact = record.fetch("checkpoints").first.fetch("symbols").fetch("path")
          allow(File).to receive(:binread).and_call_original
          selection = reader(output_path, id, run_id, "original")

          selection.to_observation

          expect(File).to have_received(:binread).with(artifact).once
        end
      end
    end

    it "keeps its selected symbols after artifact mutation" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          selection = reader(output_path, id, run_id, "first")
          observation = selection.to_observation
          _path, record = run_record(output_path, id, run_id)
          artifact = record.fetch("checkpoints")[1].fetch("symbols").fetch("path")

          File.binwrite(artifact, "[]")

          expect(observation.symbols("gp-runes-v1")).to eq(%w[ᚱ ᚻ ᛁ ᛈ])
        end
      end
    end

    it "rejects a final selection when a finished attempt never captured final" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root, failure: true) do |output_path, id, run_id|
          selection = reader(output_path, id, run_id, "final")

          action = -> { selection.to_observation }

          expect(action).to raise_error(described_class::Error)
        end
      end
    end
  end
end
