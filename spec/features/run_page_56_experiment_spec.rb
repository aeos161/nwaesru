require "tmpdir"

RSpec.describe "page 56 experiment lifecycle" do
  def tracked_definition
    "experiments/definitions/page-56-totient-latin.yml"
  end

  def fixture_definition
    "spec/fixtures/experiments/page_56_valid.yml"
  end

  it "matches the tracked independent page 56 oracle" do
    Dir.mktmpdir do |output_path|
      experiment = Primus::Experiment.load(path: tracked_definition)
      runner = Primus::Experiment::Runner.new(experiment: experiment,
                                              output_path: output_path)

      runner.run

      expect(runner.assessment.comparison).to eq("match")
    end
  end

  it "produces the exact independently recorded page 56 bytes" do
    Dir.mktmpdir do |output_path|
      experiment = Primus::Experiment.load(path: fixture_definition)
      runner = Primus::Experiment::Runner.new(experiment: experiment,
                                              output_path: output_path)

      runner.run

      expect(runner.observation.output_bytes).to eq(
        File.binread("spec/fixtures/experiments/page_56_expected.txt"),
      )
    end
  end

  it "reviews saved page 56 output from the attempt snapshot" do
    Dir.mktmpdir do |output_path|
      experiment = Primus::Experiment.load(path: fixture_definition)
      runner = Primus::Experiment::Runner.new(experiment: experiment,
                                              output_path: output_path)
      runner.run
      run_id = runner.log_entry.run_id
      store = Primus::Experiment::Store.new(output_path: output_path)

      reviewed = store.review(id: "page-56-totient-latin", run_id: run_id)

      expect(reviewed.observation.output_bytes).to eq(
        File.binread("spec/fixtures/experiments/page_56_expected.txt"),
      )
    end
  end
end
