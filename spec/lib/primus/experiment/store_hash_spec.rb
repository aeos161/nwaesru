require "fileutils"
require "tmpdir"

RSpec.describe Primus::Experiment::Store do
  def hash_fixture
    "spec/fixtures/experiments/page_57_hash_valid.yml"
  end

  describe "#review" do
    it "hydrates historical four-key plaintext assessments unchanged" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(
          path: "spec/fixtures/experiments/page_57_valid.yml",
        )
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        runner.run
        store = Primus::Experiment::Store.new(output_path: output_path)

        reviewed = store.review(id: "page-57-latin",
                                run_id: runner.log_entry.run_id)

        expect(reviewed.assessment.to_h).to eq(
          "comparison" => "match", "first_difference_byte" => nil,
          "actual_length" => 124, "expected_length" => 124
        )
      end
    end

    it "hydrates the nested hash Assessment evidence" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(path: hash_fixture)
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        runner.run
        store = Primus::Experiment::Store.new(output_path: output_path)

        reviewed = store.review(id: "page-57-latin-sha512",
                                run_id: runner.log_entry.run_id)

        expect(reviewed.assessment.to_h.fetch("hash_check")).to eq(
          runner.assessment.to_h.fetch("hash_check"),
        )
      end
    end

    it "reviews saved hash evidence after the definition is removed" do
      Dir.mktmpdir do |directory|
        path = File.join(directory, "temporary-hash.yml")
        FileUtils.cp(hash_fixture, path)
        experiment = Primus::Experiment.load(path: path)
        output_path = File.join(directory, "runs")
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        runner.run
        File.delete(path)
        store = Primus::Experiment::Store.new(output_path: output_path)

        reviewed = store.review(id: "page-57-latin-sha512",
                                run_id: runner.log_entry.run_id)

        expect(reviewed.assessment.comparison).to eq("match")
      end
    end
  end
end
