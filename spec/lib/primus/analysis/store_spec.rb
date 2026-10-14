require "json"
require "open3"
require "tmpdir"

RSpec.describe "Primus::Analysis::Store" do
  include SavedAnalysisHelper

  def saved_store(root)
    experiment_id, run_id = independent_three_rune_observation(root)
    directory = File.join(root, experiment_id, run_id)
    Open3.capture3(
      "bin/primus", "analyses", "run", experiment_id, run_id,
      "--definition", "experiments/analyses/final-symbol-statistics.yml",
      "--output-path", root,
    )
    Primus::Analysis::Store.new(directory: File.realpath(directory))
  end

  describe "#review" do
    it "returns retained entries with direct analysis-run identity" do
      Dir.mktmpdir do |root|
        store = saved_store(root)

        entry = store.review.fetch(0)

        expect(entry.analysis_run_id).to match(
          /\A[0-9]{8}T[0-9]{6}-[a-f0-9]{12}\z/,
        )
      end
    end

    it "selects one named analysis attempt by its retained ID" do
      Dir.mktmpdir do |root|
        store = saved_store(root)
        first_id = Dir.glob(File.join(store.directory, "analyses", "*", "record.json")).
                   map { |path| File.basename(File.dirname(path)) }.fetch(0)

        entries = store.review(first_id)

        expect(entries.map(&:analysis_run_id)).to eq([first_id])
      end
    end

    it "rejects a changed definition snapshot before restoring an entry" do
      Dir.mktmpdir do |root|
        store = saved_store(root)
        path = Dir.glob(File.join(store.directory, "analyses", "*", "definition.yml")).fetch(0)
        File.open(path, "ab") { |file| file.write("\nchanged") }

        action = -> { store.review }

        expect(action).to raise_error(Primus::Analysis::Store::Error)
      end
    end
  end
end
