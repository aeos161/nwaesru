require "digest"
require "tmpdir"

RSpec.describe Primus::Experiment::Store do
  include SavedCheckpointAnalysisHelper

  describe "#review" do
    it "retains the failed-step identity from an absolute partial chain" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root, failure: true) do |output_path, id, run_id|
          store = described_class.new(output_path: output_path)

          reviewed = store.review(id: id, run_id: run_id)

          expect(reviewed.data.fetch("failed_step").fetch("id")).to eq("second")
        end
      end
    end

    it "reads a partial failed checkpoint chain through a relative output root" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root, failure: true) do |_output_path, id, run_id|
          store = described_class.new(output_path: "../runs")

          reviewed = store.review(id: id, run_id: run_id)

          expect(reviewed.data.fetch("failed_step").fetch("id")).to eq("second")
        end
      end
    end

    it "returns equivalent saved results from relative and absolute output roots" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          relative_store = described_class.new(output_path: "../runs")
          absolute_store = described_class.new(output_path: output_path)

          relative = relative_store.review(id: id, run_id: run_id)
          absolute = absolute_store.review(id: id, run_id: run_id)

          expect(relative.data).to eq(absolute.data)
        end
      end
    end

    it "keeps every saved record and artifact byte unchanged after both reviews" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          run_directory = File.join(output_path, id, run_id)
          pattern = File.join(run_directory, "**", "*")
          before = Dir.glob(pattern).select { |path| File.file?(path) }.to_h do |path|
            [path, Digest::SHA256.file(path).hexdigest]
          end
          relative_store = described_class.new(output_path: "../runs")
          absolute_store = described_class.new(output_path: output_path)

          relative_store.review(id: id, run_id: run_id)
          absolute_store.review(id: id, run_id: run_id)
          after = Dir.glob(pattern).select { |path| File.file?(path) }.to_h do |path|
            [path, Digest::SHA256.file(path).hexdigest]
          end

          expect(after).to eq(before)
        end
      end
    end
  end
end
