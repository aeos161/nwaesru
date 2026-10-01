require "json"
require "tmpdir"

RSpec.describe "page 57 experiment lifecycle" do
  def fixture(name = "page_57_valid.yml")
    "spec/fixtures/experiments/#{name}"
  end

  def saved_record(output_path)
    path = Dir.glob("#{output_path}/**/record.json").fetch(0)
    JSON.parse(File.read(path))
  end

  it "validates a saved experiment" do
    experiment = Primus::Experiment.load(path: fixture)

    expect(experiment).to be_valid
  end

  it "runs the tracked page 57 definition against its tracked oracle" do
    Dir.mktmpdir do |output_path|
      experiment = Primus::Experiment.load(
        path: "experiments/definitions/page-57-latin.yml",
      )
      runner = Primus::Experiment::Runner.new(experiment: experiment,
                                              output_path: output_path)

      runner.run

      expect(runner.assessment.comparison).to eq("match")
    end
  end

  it "returns nil from the run command" do
    Dir.mktmpdir do |output_path|
      experiment = Primus::Experiment.load(path: fixture)
      runner = Primus::Experiment::Runner.new(experiment: experiment,
                                              output_path: output_path)

      command_return = runner.run

      expect(command_return).to be_nil
    end
  end

  it "produces the exact known page 57 Latin bytes" do
    Dir.mktmpdir do |output_path|
      experiment = Primus::Experiment.load(path: fixture)
      runner = Primus::Experiment::Runner.new(experiment: experiment,
                                              output_path: output_path)

      runner.run

      expect(runner.observation.output_bytes).to eq(
        "parable.lice the instar t\n" \
        "unnelng to the surface.\nwe must shed our own c\n" \
        "ircumferences.find th\ne diuinity within and emerge.",
      )
    end
  end

  it "saves the exact source YAML and extracted body separately" do
    Dir.mktmpdir do |output_path|
      experiment = Primus::Experiment.load(path: fixture)
      runner = Primus::Experiment::Runner.new(experiment: experiment,
                                              output_path: output_path)

      runner.run
      manifest = saved_record(output_path).fetch("artifacts")
      source = File.binread(manifest.fetch("input.yml").fetch("path"))
      body = File.binread(manifest.fetch("source-body.txt").fetch("path"))
      input_path = "data/encoded/liber_primus/page_57.yml"

      expect([source, body]).to eq(
        [File.binread(input_path),
         Psych.safe_load(File.read(input_path)).fetch("body").b],
      )
    end
  end

  it "reuses a prior attempt without making a new observation" do
    Dir.mktmpdir do |output_path|
      experiment = Primus::Experiment.load(path: fixture)
      runner = Primus::Experiment::Runner.new(experiment: experiment,
                                              output_path: output_path)
      runner.run
      first_id = runner.log_entry.run_id

      runner.run

      expect(runner.log_entry.run_id).to eq(first_id)
    end
  end

  it "clears the current observation when reusing a prior attempt" do
    Dir.mktmpdir do |output_path|
      experiment = Primus::Experiment.load(path: fixture)
      runner = Primus::Experiment::Runner.new(experiment: experiment,
                                              output_path: output_path)
      runner.run

      runner.run

      expect(runner.observation).to be_nil
    end
  end

  it "clears the current assessment when reusing a prior attempt" do
    Dir.mktmpdir do |output_path|
      experiment = Primus::Experiment.load(path: fixture)
      runner = Primus::Experiment::Runner.new(experiment: experiment,
                                              output_path: output_path)
      runner.run

      runner.run

      expect(runner.assessment).to be_nil
    end
  end

  it "does not save another attempt when reusing prior results" do
    Dir.mktmpdir do |output_path|
      experiment = Primus::Experiment.load(path: fixture)
      runner = Primus::Experiment::Runner.new(experiment: experiment,
                                              output_path: output_path)
      runner.run

      runner.run

      expect(Dir.glob("#{output_path}/**/record.json").size).to eq(1)
    end
  end

  it "records a reason and prior attempt for an explicit rerun" do
    Dir.mktmpdir do |output_path|
      experiment = Primus::Experiment.load(path: fixture)
      runner = Primus::Experiment::Runner.new(experiment: experiment,
                                              output_path: output_path)
      runner.run
      first_id = runner.log_entry.run_id

      runner.run(rerun: true, reason: "Check repeatability")

      expect(runner.log_entry).to have_attributes(
        rerun_reason: "Check repeatability", previous_run_ids: [first_id],
      )
    end
  end

  it "creates a new attempt for an explicit rerun" do
    Dir.mktmpdir do |output_path|
      experiment = Primus::Experiment.load(path: fixture)
      runner = Primus::Experiment::Runner.new(experiment: experiment,
                                              output_path: output_path)
      runner.run

      runner.run(rerun: true, reason: "Check repeatability")

      expect(Dir.glob("#{output_path}/**/record.json").size).to eq(2)
    end
  end

  it "reviews an earlier saved attempt after the oracle changes" do
    Dir.mktmpdir do |output_path|
      first_experiment = Primus::Experiment.load(path: fixture)
      first_runner = Primus::Experiment::Runner.new(
        experiment: first_experiment, output_path: output_path,
      )
      first_runner.run
      first_id = first_runner.log_entry.run_id
      changed_experiment = Primus::Experiment.load(
        path: fixture("page_57_mismatch.yml"),
      )
      Primus::Experiment::Runner.new(
        experiment: changed_experiment, output_path: output_path,
      ).run

      store = Primus::Experiment::Store.new(output_path: output_path)

      prior = store.review(id: "page-57-latin", run_id: first_id)

      expect(prior.status).to eq("matched")
    end
  end
end
