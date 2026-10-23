require "digest"
require "json"
require "tmpdir"

RSpec.describe Primus::Experiment do
  ENCODED_WARNING_SHA256 = "86a0a2a4d68c2fff1af86d3e7aa62bec05eb46a2bdbc480d4243bcf282561718"
  DECODED_WARNING_SHA256 = "d359714fdba2c8d3a557dd7c745659ffb1137cb58ce5844e28e830f0217c1d1f"
  ATBASH_RUNES_SHA256 = "bcebb8ea5cb8d1cf6902561c2b003147d366c9a31778313856941b21e9fde353"
  ATBASH_LATIN_SHA256 = "8d130adee72285dbde3a94576cba6a1492660286fcd764561bd1215b0f8d7222"

  def warning_definition
    { "schema_version" => 2, "id" => "warning-atbash-control",
      "title" => "Real Warning Atbash control",
      "purpose" => "Check the full Warning plaintext and source mapping.",
      "input" => { "id" => "page-warning", "sha256" => ENCODED_WARNING_SHA256 },
      "steps" => [
        { "id" => "mirror", "operation" => "atbash",
          "parameters" => { "alphabet" => "gematria-primus", "modulus" => 29 } },
        { "id" => "letters", "operation" => "latin", "parameters" => {} }
      ],
      "output" => { "policy" => "gp-latin-compatibility-v1" },
      "checks" => [{ "id" => "check-1", "strategy" => "plaintext",
                     "expectation" => {
                       "path" => "spec/fixtures/experiments/warning_atbash_latin.txt",
                       "sha256" => ATBASH_LATIN_SHA256,
                       "provenance" => "Full independently checked local Warning page." } }] }
  end

  def run_warning(output_path)
    experiment = described_class.from_data(warning_definition)
    runner = Primus::Experiment::Runner.new(experiment: experiment,
                                            output_path: output_path)
    runner.run
    runner
  end

  def checkpoint(runner, step_id)
    runner.log_entry.data.fetch("checkpoints").find do |item|
      item.fetch("step_id") == step_id
    end
  end

  describe "#valid?" do
    it "accepts the real page-warning selector with its source checksum" do
      experiment = described_class.from_data(warning_definition)

      result = experiment.valid?

      expect(result).to be_truthy
    end

    it "rejects a numeric page-zero alias for Warning" do
      definition = warning_definition
      definition.fetch("input")["id"] = "page-0"
      experiment = described_class.from_data(definition)

      result = experiment.valid?

      expect(result).to be_falsy
    end

    it "rejects an arbitrary named source selector" do
      definition = warning_definition
      definition.fetch("input")["id"] = "page-secret"
      experiment = described_class.from_data(definition)

      result = experiment.valid?

      expect(result).to be_falsy
    end
  end

  describe "#canonical_configuration" do
    it "retains a distinct identity for the wrong declared operation order" do
      first = described_class.from_data(warning_definition)
      reversed = warning_definition
      reversed.fetch("steps").insert(0, {
        "id" => "reverse", "operation" => "reverse-runes",
        "parameters" => { "scope" => "composed-input", "non_runes" => "fixed" }
      })
      second = described_class.from_data(reversed)

      configurations = [first.canonical_configuration, second.canonical_configuration]

      expect(configurations.first).not_to eq(configurations.last)
    end
  end

  describe "Primus::Experiment::Runner#run" do
    it "keeps distinct fingerprints for commuting Atbash and reversal orders" do
      Dir.mktmpdir do |output_path|
        first_definition = warning_definition
        reversal = { "id" => "reverse", "operation" => "reverse-runes",
                     "parameters" => { "scope" => "composed-input", "non_runes" => "fixed" } }
        first_definition.fetch("steps").insert(1, reversal)
        second_definition = warning_definition
        second_definition.fetch("steps").unshift(reversal)
        first = Primus::Experiment::Runner.new(
          experiment: described_class.from_data(first_definition), output_path: output_path
        )
        second = Primus::Experiment::Runner.new(
          experiment: described_class.from_data(second_definition), output_path: output_path
        )

        first.run
        second.run
        fingerprints = [first, second].map do |runner|
          runner.log_entry.data.fetch("execution_identity")
        end

        expect(fingerprints.uniq.size).to eq(2)
      end
    end

    it "matches the full verified Warning plaintext" do
      Dir.mktmpdir do |output_path|
        runner = run_warning(output_path)

        result = runner.assessment.comparison

        expect(result).to eq("match")
      end
    end

    it "writes the exact independently frozen Atbash rune checkpoint" do
      Dir.mktmpdir do |output_path|
        runner = run_warning(output_path)
        path = checkpoint(runner, "mirror").fetch("output").fetch("path")

        actual = File.binread(path)

        expect(actual).to eq(File.binread("spec/fixtures/experiments/warning_atbash_runes.txt"))
      end
    end

    it "writes the exact terminal Latin bytes with one trailing trim" do
      Dir.mktmpdir do |output_path|
        runner = run_warning(output_path)

        actual = runner.observation.output_bytes.b

        expect(actual).to eq(File.binread("spec/fixtures/experiments/warning_atbash_latin.txt"))
      end
    end

    it "keeps Warning as a string source identity in mirrored symbol coordinates" do
      Dir.mktmpdir do |output_path|
        runner = run_warning(output_path)
        path = checkpoint(runner, "mirror").fetch("symbols").fetch("path")

        rows = JSON.parse(File.binread(path)).first(2).map do |item|
          item.values_at("ordinal", "rune", "latin", "page_number", "occurrence",
                         "byte_start", "line", "column", "rune_index")
        end

        expect(rows).to eq([
          [0, "ᚪ", "a", "warning", 0, 0, 0, 0, 0],
          [1, "ᚹ", "w", "warning", 0, 4, 0, 2, 1]
        ])
      end
    end

    it "retains the exact original encoded body as the first checkpoint" do
      Dir.mktmpdir do |output_path|
        runner = run_warning(output_path)
        path = checkpoint(runner, "original").fetch("output").fetch("path")

        actual = File.binread(path)

        expect(actual).to eq(Psych.safe_load(File.binread(
          "data/encoded/liber_primus/page_warning.yml"
        )).fetch("body").b)
      end
    end

    it "retains the exact Warning path in saved source evidence" do
      Dir.mktmpdir do |output_path|
        runner = run_warning(output_path)

        path = checkpoint(runner, "original").fetch("source").fetch("path")

        expect(path).to eq("data/encoded/liber_primus/page_warning.yml")
      end
    end
  end

  describe "Primus::Analysis::ObservationReader#to_observation" do
    it "selects the saved Atbash stage by explicit step ID" do
      Dir.mktmpdir do |output_path|
        runner = run_warning(output_path)
        reader = Primus::Analysis::ObservationReader.new(
          output_path: output_path, experiment_id: runner.log_entry.data.fetch("experiment_id"),
          run_id: runner.log_entry.run_id, stage: "mirror"
        )

        runes = reader.to_observation.symbols("gp-runes-v1")

        expect(runes.first(4)).to eq(%w[ᚪ ᚹ ᚪ ᚱ])
      end
    end

    it "expands Latin from the saved Atbash rune checkpoint" do
      Dir.mktmpdir do |output_path|
        runner = run_warning(output_path)
        reader = Primus::Analysis::ObservationReader.new(
          output_path: output_path, experiment_id: runner.log_entry.data.fetch("experiment_id"),
          run_id: runner.log_entry.run_id, stage: "mirror"
        )

        letters = reader.to_observation.symbols("gp-expanded-latin-v1")

        expect(letters.first(5)).to eq(%w[a w a r n])
      end
    end
  end

  describe "warning oracle fixtures" do
    it "pins the encoded Warning source used by the control" do
      actual = Digest::SHA256.file("data/encoded/liber_primus/page_warning.yml").hexdigest

      expect(actual).to eq(ENCODED_WARNING_SHA256)
    end

    it "pins the independent decoded Warning source" do
      actual = Digest::SHA256.file("data/decoded/liber_primus/page_warning.yml").hexdigest

      expect(actual).to eq(DECODED_WARNING_SHA256)
    end

    it "pins the reviewed intermediate rune bytes" do
      actual = Digest::SHA256.file(
        "spec/fixtures/experiments/warning_atbash_runes.txt"
      ).hexdigest

      expect(actual).to eq(ATBASH_RUNES_SHA256)
    end
  end
end
