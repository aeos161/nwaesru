require "digest"
require "tmpdir"

RSpec.describe "Saved analysis checkpoint operation parity" do
  WARNING_SOURCE_SHA256 = "86a0a2a4d68c2fff1af86d3e7aa62bec05eb46a2bdbc480d4243bcf282561718"
  WARNING_LATIN_SHA256 = "8d130adee72285dbde3a94576cba6a1492660286fcd764561bd1215b0f8d7222"

  def run_warning(root, operation:, parameters:)
    definition = {
      "schema_version" => 2, "id" => "warning-analysis-parity",
      "title" => "Saved Warning analysis", "purpose" => "Verify supported checkpoints.",
      "input" => { "id" => "page-warning", "sha256" => WARNING_SOURCE_SHA256 },
      "steps" => [
        { "id" => "changed", "operation" => operation, "parameters" => parameters },
        { "id" => "letters", "operation" => "latin", "parameters" => {} },
      ],
      "output" => { "policy" => "gp-latin-compatibility-v1" },
      "checks" => [{ "id" => "check-1", "strategy" => "plaintext",
                     "expectation" => {
                       "path" => "spec/fixtures/experiments/warning_atbash_latin.txt",
                       "sha256" => WARNING_LATIN_SHA256,
                       "provenance" => "Saved independent Warning control." } }],
    }
    experiment = Primus::Experiment.from_data(definition)
    runner = Primus::Experiment::Runner.new(experiment: experiment, output_path: root)
    runner.run
    runner.log_entry
  end

  def analyze_changed(root, experiment_entry)
    id = experiment_entry.data.fetch("experiment_id")
    run_id = experiment_entry.run_id
    observation = Primus::Analysis::ObservationReader.new(
      output_path: root, experiment_id: id, run_id: run_id, stage: "changed",
    ).to_observation
    path = File.join(root, "statistics.yml")
    declaration = { "id" => "counts", "analyzer" => "symbol-statistics",
                    "version" => 1,
                    "target" => { "stage" => "changed",
                                  "representation" => "gp-runes-v1" } }
    File.write(path, Psych.dump("schema_version" => 1, "id" => "checkpoint-count",
                                "analyses" => [declaration]))
    definition = Primus::Analysis::Definition.new(path: path)
    runner = Primus::Analysis::Runner.new(definition: definition, observation: observation)
    runner.run
    runner.log_entry
  end

  describe "Primus::Analysis::Runner#run" do
    it "retains an analysis of an Atbash checkpoint" do
      Dir.mktmpdir do |root|
        experiment_entry = run_warning(root, operation: "atbash",
                                       parameters: { "alphabet" => "gematria-primus",
                                                     "modulus" => 29 })

        analysis_entry = analyze_changed(root, experiment_entry)
        directory = File.join(root, experiment_entry.data.fetch("experiment_id"),
                              experiment_entry.run_id)
        store = Primus::Analysis::Store.new(directory: File.realpath(directory))

        reviewed = store.review(analysis_entry.analysis_run_id).first

        expect(reviewed.to_h.fetch("checkpoint")).to include(
          "operation" => "atbash", "step_id" => "changed",
          "requested_stage" => "changed",
        )
      end
    end

    it "retains an analysis of a rune reversal checkpoint" do
      Dir.mktmpdir do |root|
        experiment_entry = run_warning(root, operation: "reverse-runes",
                                       parameters: { "scope" => "composed-input",
                                                     "non_runes" => "fixed" })

        analysis_entry = analyze_changed(root, experiment_entry)
        directory = File.join(root, experiment_entry.data.fetch("experiment_id"),
                              experiment_entry.run_id)
        store = Primus::Analysis::Store.new(directory: File.realpath(directory))

        reviewed = store.review(analysis_entry.analysis_run_id).first

        expect(reviewed.to_h.fetch("checkpoint")).to include(
          "operation" => "reverse-runes", "step_id" => "changed",
          "requested_stage" => "changed",
        )
      end
    end
  end
end
