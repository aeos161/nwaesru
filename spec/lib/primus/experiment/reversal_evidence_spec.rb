require "digest"
require "fileutils"
require "json"
require "open3"
require "tmpdir"

RSpec.describe Primus::Experiment::CheckpointEvidence do
  def with_saved_reversal
    root = Dir.mktmpdir
    begin
      repository = File.join(root, "repository")
      _stdout, stderr, status = Open3.capture3(
        "git", "clone", "--quiet", "--local", "--no-hardlinks", Dir.pwd, repository
      )
      raise "Test repository clone failed: #{stderr}" unless status.success?

      Dir.chdir(repository) do
        selections = ["ᚠ-ᚢ", "ᚦᚣ"].each_with_index.map do |body, index|
          number = 99 + index
          path = "data/encoded/liber_primus/page_#{number}.yml"
          File.binwrite(path, Psych.dump("body" => body))
          { "id" => "page-#{number}", "sha256" => Digest::SHA256.file(path).hexdigest }
        end
        definition = {
          "schema_version" => 2, "id" => "saved-reversal-control",
          "title" => "Saved reversal control", "purpose" => "Check ordered saved lineage.",
          "input" => { "pages" => selections },
          "steps" => [
            { "id" => "reverse", "operation" => "reverse-runes",
              "parameters" => { "scope" => "composed-input", "non_runes" => "fixed" } },
            { "id" => "letters", "operation" => "latin", "parameters" => {} }
          ],
          "output" => { "policy" => "gp-latin-compatibility-v1" },
          "checks" => [{ "id" => "check-1", "strategy" => "hash",
                         "algorithm" => "sha512",
                         "expectation" => { "digest" => "0" * 128,
                                            "provenance" => "Deliberate negative check." } }]
        }
        definition_path = "experiments/definitions/saved-reversal-control.yml"
        File.binwrite(definition_path, Psych.dump(definition))
        experiment = Primus::Experiment.load(path: definition_path)
        output_path = File.join(root, "runs")
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        runner.run
        record_path = File.join(output_path, experiment.id, runner.log_entry.run_id,
                                "record.json")
        yield output_path, runner, record_path
      end
    ensure
      FileUtils.rm_rf(root)
    end
  end

  def rewrite_artifact(item, key, value)
    metadata = item.fetch(key)
    bytes = key == "output" ? value.b : JSON.pretty_generate(value)
    File.binwrite(metadata.fetch("path"), bytes)
    metadata["bytes"] = bytes.bytesize
    metadata["sha256"] = Digest::SHA256.hexdigest(bytes)
  end

  describe "#verify!" do
    it "accepts the declared cross-page rune permutation with fixed non-rune slots" do
      with_saved_reversal do |_output_path, _runner, record_path|
        record = JSON.parse(File.binread(record_path))
        evidence = described_class.new(record_path: record_path, data: record)

        result = evidence.verify!

        expect(result).to be_nil
      end
    end

    it "rejects an arbitrary rune permutation even after artifact hashes are repaired" do
      with_saved_reversal do |_output_path, _runner, record_path|
        record = JSON.parse(File.binread(record_path))
        reversal = record.fetch("checkpoints")[1]
        lexemes = JSON.parse(File.binread(reversal.fetch("lexemes").fetch("path")))
        symbols = JSON.parse(File.binread(reversal.fetch("symbols").fetch("path")))
        positions = lexemes.each_index.select { |index| lexemes[index]["kind"] == "rune" }
        first, second = positions.first(2)
        first_span = lexemes[first].values_at("output_byte_start", "output_byte_end")
        second_span = lexemes[second].values_at("output_byte_start", "output_byte_end")
        lexemes[first], lexemes[second] = lexemes[second], lexemes[first]
        lexemes[first]["output_byte_start"], lexemes[first]["output_byte_end"] = first_span
        lexemes[second]["output_byte_start"], lexemes[second]["output_byte_end"] = second_span
        symbols[0], symbols[1] = symbols[1], symbols[0]
        symbols[0]["ordinal"], symbols[1]["ordinal"] = 0, 1
        rewrite_artifact(reversal, "lexemes", lexemes)
        rewrite_artifact(reversal, "symbols", symbols)
        rewrite_artifact(reversal, "output", lexemes.map { |token| token.fetch("lexeme") }.join)
        File.binwrite(record_path, JSON.pretty_generate(record))
        evidence = described_class.new(record_path: record_path, data: record)

        action = -> { evidence.verify! }

        expect(action).to raise_error(described_class::Invalid)
      end
    end
  end

  describe "Primus::Analysis::ObservationReader#to_observation" do
    it "reads the saved reversal after the live input pages disappear" do
      with_saved_reversal do |output_path, runner, _record_path|
        File.delete("data/encoded/liber_primus/page_99.yml")
        File.delete("data/encoded/liber_primus/page_100.yml")
        reader = Primus::Analysis::ObservationReader.new(
          output_path: output_path, experiment_id: "saved-reversal-control",
          run_id: runner.log_entry.run_id, stage: "reverse"
        )

        runes = reader.to_observation.symbols("gp-runes-v1")

        expect(runes).to eq(%w[ᚣ ᚦ ᚢ ᚠ])
      end
    end

    it "expands saved Latin symbols from moved rune identity" do
      with_saved_reversal do |output_path, runner, _record_path|
        reader = Primus::Analysis::ObservationReader.new(
          output_path: output_path, experiment_id: "saved-reversal-control",
          run_id: runner.log_entry.run_id, stage: "reverse"
        )

        letters = reader.to_observation.symbols("gp-expanded-latin-v1")

        expect(letters).to eq(%w[y t h u f])
      end
    end
  end
end
