require "digest"
require "fileutils"
require "json"
require "open3"
require "tmpdir"

RSpec.describe "Repeated n-grams across ordered source pages" do
  def with_repeated_pages
    root = Dir.mktmpdir
    begin
      repository = File.join(root, "repository")
      _stdout, stderr, status = Open3.capture3(
        "git", "clone", "--quiet", "--local", "--no-hardlinks", Dir.pwd,
        repository,
      )
      raise "Test repository clone failed: #{stderr}" unless status.success?

      Dir.chdir(repository) do
        pages = [[99, "ᚪ"], [98, "ᚠ"], [99, "ᚪ"], [98, "ᚠ"]].map do |number, body|
          path = "data/encoded/liber_primus/page_#{number}.yml"
          File.binwrite(path, Psych.dump("body" => body))
          { "id" => "page-#{number}", "sha256" => Digest::SHA256.file(path).hexdigest }
        end
        experiment_data = {
          "schema_version" => 2, "id" => "repeated-pages-control",
          "title" => "Repeated ordered pages", "purpose" => "Check GP source order.",
          "input" => { "pages" => pages },
          "steps" => [{ "id" => "letters", "operation" => "latin", "parameters" => {} }],
          "output" => { "policy" => "gp-latin-compatibility-v1" },
          "checks" => [{ "id" => "check-1", "strategy" => "hash",
                         "algorithm" => "sha512",
                         "expectation" => { "digest" => "0" * 128,
                                            "provenance" => "Synthetic negative control." } }],
        }
        experiment = Primus::Experiment.from_data(experiment_data)
        output_path = File.join(root, "runs")
        experiment_runner = Primus::Experiment::Runner.new(
          experiment: experiment, output_path: output_path,
        )
        experiment_runner.run
        path = File.join(root, "repeated.yml")
        declaration = { "id" => "rune-repeats", "analyzer" => "repeated-ngrams",
                        "version" => 1,
                        "parameters" => { "lengths" => [2, 3],
                                          "boundary_policy" => "continuous-gp-v1" },
                        "target" => { "stage" => "original",
                                      "representation" => "gp-runes-v1" } }
        File.write(path, Psych.dump("schema_version" => 1, "id" => "page-repeats",
                                    "analyses" => [declaration]))
        definition = Primus::Analysis::Definition.new(path: path)
        observation = Primus::Analysis::ObservationReader.new(
          output_path: output_path, experiment_id: experiment.id,
          run_id: experiment_runner.log_entry.run_id, stage: "original",
        ).to_observation
        analysis_runner = Primus::Analysis::Runner.new(
          definition: definition, observation: observation,
        )
        analysis_runner.run
        yield analysis_runner.log_entry.to_h.fetch("results").first.fetch("result")
      end
    ensure
      FileUtils.rm_rf(root)
    end
  end

  describe "Primus::Analysis::Runner#run" do
    it "retains a pair repeated across page boundaries" do
      with_repeated_pages do |result|
        pair = result.fetch("length_groups").first

        expect(pair.fetch("patterns")).to include(
          "symbols" => %w[ᚪ ᚠ], "count" => 2,
          "occurrences" => [{ "start_index" => 0, "end_index" => 2 },
                            { "start_index" => 2, "end_index" => 4 }],
          "gaps" => [2],
        )
      end
    end

    it "keeps declared page order and repeated occurrences in the source map" do
      with_repeated_pages do |result|
        positions = result.fetch("position_map")
        identities = positions.map do |position|
          position.values_at("rune_ordinal", "page_number", "occurrence",
                             "rune_index", "byte_start", "byte_end")
        end

        expect(identities).to eq([
          [0, 99, 0, 0, 0, 3], [1, 98, 1, 0, 0, 3],
          [2, 99, 2, 0, 0, 3], [3, 98, 3, 0, 0, 3],
        ])
      end
    end
  end
end
