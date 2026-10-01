require "fileutils"
require "json"
require "tmpdir"

RSpec.describe "Primus::Experiment::Store" do
  def create_completed_attempt(output_path)
    experiment = Primus::Experiment.load(
      path: "spec/fixtures/experiments/page_57_valid.yml",
    )
    runner = Primus::Experiment::Runner.new(experiment: experiment,
                                            output_path: output_path)
    runner.run
    Dir.glob("#{output_path}/**/record.json").fetch(0)
  end

  describe "#review" do
    it "keeps an interrupted attempt visibly incomplete" do
      Dir.mktmpdir do |output_path|
        path = create_completed_attempt(output_path)
        saved = JSON.parse(File.read(path))
        saved["status"] = "running"
        saved["comparison"] = "not_checked"
        saved["assessment"] = nil
        File.write(path, JSON.generate(saved))
        store = Primus::Experiment::Store.new(output_path: output_path)

        prior = store.review(id: "page-57-latin",
                             run_id: saved.fetch("run_id"))

        expect(prior.status).to eq("running")
      end
    end

    it "keeps an execution error distinct from a comparison mismatch" do
      Dir.mktmpdir do |output_path|
        path = create_completed_attempt(output_path)
        saved = JSON.parse(File.read(path))
        saved["status"] = "error"
        saved["comparison"] = "not_checked"
        saved["assessment"] = nil
        saved["errors"] = [{ "stage" => "execution", "type" => "RuntimeError",
                             "message" => "translator failed" }]
        File.write(path, JSON.generate(saved))
        store = Primus::Experiment::Store.new(output_path: output_path)

        prior = store.review(id: "page-57-latin",
                             run_id: saved.fetch("run_id"))

        expect(prior.status).to eq("error")
      end
    end

    it "identifies a corrupt saved record instead of inventing a result" do
      Dir.mktmpdir do |output_path|
        directory = File.join(output_path, "page-57-latin", "broken-001")
        FileUtils.mkdir_p(directory)
        File.write(File.join(directory, "record.json"), "{broken")
        store = Primus::Experiment::Store.new(output_path: output_path)

        action = -> { store.review(id: "page-57-latin", run_id: "broken-001") }

        expect(action).to raise_error(Primus::Experiment::Store::ReadError)
      end
    end
  end
end
