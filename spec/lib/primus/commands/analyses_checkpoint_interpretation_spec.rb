require "open3"
require "tmpdir"

RSpec.describe Primus::Commands::Analyses do
  include SavedCheckpointAnalysisHelper

  describe "#execute" do
    it "prints a comparison for both representations at every retained stage and terminal alias" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, experiment_id, run_id|
          stages = %w[original first second letters final]

          comparison_counts = stages.map do |stage|
            definition = checkpoint_analysis_definition(root, stage: stage)
            stdout, stderr, status = Open3.capture3(
              "bin/primus", "analyses", "run", experiment_id, run_id,
              "--definition", definition, "--output-path", output_path,
            )
            raise stderr unless status.success?

            stdout.scan("English comparison:").length
          end

          expect(comparison_counts).to eq([2, 2, 2, 2, 2])
        end
      end
    end
  end
end
