require "digest"
require "fileutils"
require "open3"
require "tmpdir"

RSpec.describe "Repeated n-grams at transformed checkpoints" do
  def with_transformed_run
    root = Dir.mktmpdir
    begin
      repository = File.join(root, "repository")
      _stdout, stderr, status = Open3.capture3(
        "git", "clone", "--quiet", "--local", "--no-hardlinks", Dir.pwd,
        repository,
      )
      raise "Test repository clone failed: #{stderr}" unless status.success?

      Dir.chdir(repository) do
        source_path = "data/encoded/liber_primus/page_99.yml"
        File.binwrite(source_path, Psych.dump("body" => "ᚦᚪᚦᚪ"))
        experiment_data = {
          "schema_version" => 2, "id" => "mirror-repeat-control",
          "title" => "Mirrored repeats", "purpose" => "Check saved sequence positions.",
          "input" => { "id" => "page-99",
                       "sha256" => Digest::SHA256.file(source_path).hexdigest },
          "steps" => [
            { "id" => "mirror", "operation" => "atbash",
              "parameters" => { "alphabet" => "gematria-primus", "modulus" => 29 } },
            { "id" => "reverse", "operation" => "reverse-runes",
              "parameters" => { "scope" => "composed-input",
                                "non_runes" => "fixed" } },
            { "id" => "letters", "operation" => "latin", "parameters" => {} },
          ],
          "output" => { "policy" => "gp-latin-compatibility-v1" },
          "checks" => [{ "id" => "check-1", "strategy" => "hash",
                         "algorithm" => "sha512",
                         "expectation" => { "digest" => "0" * 128,
                                            "provenance" => "Synthetic negative control." } }],
        }
        experiment = Primus::Experiment.from_data(experiment_data)
        output_path = File.join(root, "runs")
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        runner.run
        yield root, output_path, experiment.id, runner.log_entry.run_id
      end
    ensure
      FileUtils.rm_rf(root)
    end
  end

  def result_at(root, output_path, id, run_id, stage)
    path = File.join(root, "analysis.yml")
    declaration = { "id" => "repeats", "analyzer" => "repeated-ngrams",
                    "version" => 1,
                    "parameters" => { "lengths" => [2, 3],
                                      "boundary_policy" => "continuous-gp-v1" },
                    "target" => { "stage" => stage,
                                  "representation" => "gp-runes-v1" } }
    File.write(path, Psych.dump("schema_version" => 1, "id" => "stage-repeats",
                                "analyses" => [declaration]))
    definition = Primus::Analysis::Definition.new(path: path)
    observation = Primus::Analysis::ObservationReader.new(
      output_path: output_path, experiment_id: id, run_id: run_id, stage: stage,
    ).to_observation
    analysis = Primus::Analysis::Runner.new(definition: definition,
                                            observation: observation)
    analysis.run
    analysis.log_entry.to_h.fetch("results").first.fetch("result")
  end

  describe "Primus::Analysis::Runner#run" do
    it "retains the literal mirrored pair at its transformed starts" do
      with_transformed_run do |root, output_path, id, run_id|
        result = result_at(root, output_path, id, run_id, "mirror")
        pair = result.fetch("length_groups").first

        expect(pair.fetch("patterns")).to include(
          "symbols" => %w[ᚣ ᚱ], "count" => 2,
          "occurrences" => [{ "start_index" => 0, "end_index" => 2 },
                            { "start_index" => 2, "end_index" => 4 }],
          "gaps" => [2],
        )
      end
    end

    it "retains the reversed pair label and mapped starts" do
      with_transformed_run do |root, output_path, id, run_id|
        result = result_at(root, output_path, id, run_id, "reverse")
        pair = result.fetch("length_groups").first

        expect(pair.fetch("patterns")).to include(
          "symbols" => %w[ᚱ ᚣ], "count" => 2,
          "occurrences" => [{ "start_index" => 0, "end_index" => 2 },
                            { "start_index" => 2, "end_index" => 4 }],
          "gaps" => [2],
        )
      end
    end

    it "keeps reversed current ordinals tied to descending original rune indices" do
      with_transformed_run do |root, output_path, id, run_id|
        result = result_at(root, output_path, id, run_id, "reverse")

        source_indices = result.fetch("position_map").map do |position|
          position.fetch("rune_index")
        end

        expect(source_indices).to eq([3, 2, 1, 0])
      end
    end
  end
end
