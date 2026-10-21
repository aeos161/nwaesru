require "digest"
require "fileutils"
require "open3"

module SavedCheckpointAnalysisHelper
  def with_checkpoint_analysis_run(root, source_body: "ᚳᚻ ᛇᛒ\n",
                                   final_text: nil, failure: false)
    repository = File.join(root, "repository")
    _stdout, stderr, status = Open3.capture3(
      "git", "clone", "--quiet", "--local", "--no-hardlinks", Dir.pwd, repository
    )
    raise "Test repository clone failed: #{stderr}" unless status.success?

    source = File.join(repository, "data/encoded/liber_primus/page_99.yml")
    expected = File.join(repository, "experiments/expected/synthetic-chain.txt")
    File.binwrite(source, Psych.dump("body" => source_body))
    final_text ||= source_body == "ᚦᚪᚦ" ? "ealf" : "thr iw"
    File.binwrite(expected, final_text)
    steps = [
      { "id" => "first", "operation" => "totient",
        "parameters" => { "modulus" => 29, "prime_start" => 2,
                          "skip_sequence" => [1] } },
      { "id" => "second", "operation" => "totient",
        "parameters" => { "modulus" => 29, "prime_start" => 3,
                          "skip_sequence" => [2] } },
      { "id" => "letters", "operation" => "latin", "parameters" => {} }
    ]
    definition = {
      "schema_version" => 2, "id" => "synthetic-chain", "title" => "Independent chain",
      "purpose" => "Check retained checkpoint symbol statistics.",
      "input" => { "id" => "page-99", "sha256" => Digest::SHA256.file(source).hexdigest },
      "steps" => steps, "output" => { "policy" => "gp-latin-compatibility-v1" },
      "checks" => [{ "id" => "check-1", "strategy" => "plaintext",
                     "expectation" => { "path" => "experiments/expected/synthetic-chain.txt",
                                        "sha256" => Digest::SHA256.hexdigest(final_text),
                                        "provenance" => "Independent literal control." } }]
    }
    definition_path = File.join(repository, "experiments/definitions/synthetic-chain.yml")
    File.write(definition_path, Psych.dump(definition))
    Dir.chdir(repository) do
      experiment = Primus::Experiment.load(path: definition_path)
      output_path = File.join(root, "runs")
      runner = Primus::Experiment::Runner.new(experiment: experiment, output_path: output_path)
      if failure
        calls = 0
        allow(Primus::Document::TotientShift).to receive(:new).and_wrap_original do |original, *args|
          calls += 1
          raise "second layer failed" if calls == 2

          original.call(*args)
        end
        begin
          runner.run
        rescue RuntimeError
          nil
        end
      else
        runner.run
      end
      yield output_path, experiment.id, runner.log_entry.run_id
    end
  end

  def checkpoint_analysis_definition(root, stage:, representations: %w[gp-runes-v1 gp-expanded-latin-v1])
    analyses = representations.each_with_index.map do |representation, index|
      { "id" => "count-#{index}", "analyzer" => "symbol-statistics", "version" => 1,
        "target" => { "stage" => stage, "representation" => representation } }
    end
    path = File.join(root, "analysis.yml")
    File.write(path, Psych.dump("schema_version" => 1, "id" => "checkpoint-count",
                                "analyses" => analyses))
    path
  end
end
