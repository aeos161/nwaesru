require "json"
require "tempfile"
require "tmpdir"

RSpec.describe "page 57 SHA-512 experiment lifecycle" do
  def hash_experiment
    Primus::Experiment.load(
      path: "spec/fixtures/experiments/page_57_hash_valid.yml",
    )
  end

  def changed_digest_experiment
    path = "spec/fixtures/experiments/page_57_hash_valid.yml"
    definition = Psych.safe_load(File.read(path))
    definition.fetch("expectation")["digest"] = "0" * 128
    load_temp_definition(definition)
  end

  def load_temp_definition(definition)
    Tempfile.create(["different-page-57-digest", ".yml"]) do |file|
      file.write(Psych.dump(definition))
      file.flush
      Primus::Experiment.load(path: file.path)
    end
  end

  def saved_record(output_path, id: "page-57-latin-sha512")
    path = Dir.glob("#{output_path}/#{id}/*/record.json").fetch(0)
    JSON.parse(File.read(path))
  end

  it "matches the independently fixed digest from tracked page 57 text" do
    Dir.mktmpdir do |output_path|
      runner = Primus::Experiment::Runner.new(experiment: hash_experiment,
                                              output_path: output_path)

      runner.run

      expect(runner.assessment.comparison).to eq("match")
    end
  end

  it "retains the unchanged page 57 compatibility output bytes" do
    Dir.mktmpdir do |output_path|
      runner = Primus::Experiment::Runner.new(experiment: hash_experiment,
                                              output_path: output_path)
      known_text = File.binread("experiments/expected/page-57-latin.txt")

      runner.run

      expect(runner.observation.output_bytes).to eq(known_text)
    end
  end

  it "saves the exact output bytes for later review" do
    Dir.mktmpdir do |output_path|
      runner = Primus::Experiment::Runner.new(experiment: hash_experiment,
                                              output_path: output_path)
      known_text = File.binread("experiments/expected/page-57-latin.txt")

      runner.run
      output = saved_record(output_path).fetch("artifacts").
               fetch("output.txt").fetch("path")

      expect(File.binread(output)).to eq(known_text)
    end
  end

  it "retains the fixed and observed SHA-512 evidence in the record" do
    Dir.mktmpdir do |output_path|
      experiment = hash_experiment
      runner = Primus::Experiment::Runner.new(experiment: experiment,
                                              output_path: output_path)
      declared = experiment.expectation.fetch("digest")

      runner.run
      hash_check = saved_record(output_path).fetch("assessment").
                   fetch("hash_check")

      expect(hash_check).to eq(
        "algorithm" => "sha512", "policy" => "gp-latin-compatibility-v1",
        "expected_digest" => declared, "observed_digest" => declared
      )
    end
  end

  it "does not save a dummy expected plaintext artifact" do
    Dir.mktmpdir do |output_path|
      runner = Primus::Experiment::Runner.new(experiment: hash_experiment,
                                              output_path: output_path)

      runner.run
      artifacts = saved_record(output_path).fetch("artifacts")

      expect(artifacts.keys).to contain_exactly(
        "definition.yml", "input.yml", "source-body.txt", "output.txt",
        "provenance.json"
      )
    end
  end

  it "keeps the oracle SHA-256 identity nil for a hash run" do
    Dir.mktmpdir do |output_path|
      runner = Primus::Experiment::Runner.new(experiment: hash_experiment,
                                              output_path: output_path)

      runner.run
      record = saved_record(output_path)

      expect(record).to include(
        "status" => "matched", "oracle_path" => nil,
        "oracle_declared_sha256" => nil, "oracle_actual_sha256" => nil
      )
    end
  end

  it "records a valid changed digest as a scientific mismatch" do
    Dir.mktmpdir do |output_path|
      runner = Primus::Experiment::Runner.new(
        experiment: changed_digest_experiment, output_path: output_path,
      )

      runner.run

      expect(runner.log_entry.data).to include(
        "status" => "mismatched", "comparison" => "mismatch",
      )
    end
  end

  it "keeps hash and plaintext histories separate for equal output bytes" do
    Dir.mktmpdir do |output_path|
      plaintext = Primus::Experiment.load(
        path: "spec/fixtures/experiments/page_57_valid.yml",
      )
      Primus::Experiment::Runner.new(experiment: plaintext,
                                     output_path: output_path).run
      hash_runner = Primus::Experiment::Runner.new(
        experiment: hash_experiment, output_path: output_path,
      )

      hash_runner.run
      store = Primus::Experiment::Store.new(output_path: output_path)

      expect(store.attempts(id: "page-57-latin-sha512").map(&:status)).
        to eq(["matched"])
    end
  end

  it "reuses an unchanged hash attempt" do
    Dir.mktmpdir do |output_path|
      runner = Primus::Experiment::Runner.new(experiment: hash_experiment,
                                              output_path: output_path)
      runner.run
      original_id = runner.log_entry.run_id

      runner.run

      expect(runner.log_entry).to have_attributes(status: "matched",
                                                  run_id: original_id)
    end
  end

  it "links an intentional hash rerun to its previous attempt" do
    Dir.mktmpdir do |output_path|
      runner = Primus::Experiment::Runner.new(experiment: hash_experiment,
                                              output_path: output_path)
      runner.run
      original_id = runner.log_entry.run_id

      runner.run(rerun: true, reason: "Check reproducibility")

      expect(runner.log_entry).to have_attributes(
        status: "matched",
        rerun_reason: "Check reproducibility",
        previous_run_ids: [original_id],
      )
    end
  end

  it "changes execution identity when the saved digest changes" do
    Dir.mktmpdir do |output_path|
      first = Primus::Experiment::Runner.new(experiment: hash_experiment,
                                             output_path: output_path)
      first.run
      second = Primus::Experiment::Runner.new(
        experiment: changed_digest_experiment, output_path: output_path,
      )

      second.run

      expect(second.log_entry).to have_attributes(
        status: "mismatched",
        run_id: satisfy { |id| id != first.log_entry.run_id },
      )
    end
  end

  it "reviews saved hash evidence without consulting the current definition" do
    Dir.mktmpdir do |output_path|
      runner = Primus::Experiment::Runner.new(experiment: hash_experiment,
                                              output_path: output_path)
      runner.run
      run_id = runner.log_entry.run_id
      store = Primus::Experiment::Store.new(output_path: output_path)

      reviewed = store.review(id: "page-57-latin-sha512", run_id: run_id)

      expect(reviewed.assessment.to_h.fetch("hash_check")).to eq(
        runner.assessment.to_h.fetch("hash_check"),
      )
    end
  end
end
