require "digest"
require "json"
require "tmpdir"

RSpec.describe Primus::Experiment::Runner do
  def saved_run(definition, output_path)
    experiment = Primus::Experiment.load(path: definition)
    runner = described_class.new(experiment: experiment, output_path: output_path)
    runner.run
    path = File.join(output_path, experiment.id, runner.log_entry.run_id,
                     "record.json")
    JSON.parse(File.binread(path))
  end

  describe "#run" do
    it "declares the two supported final representations" do
      Dir.mktmpdir do |output_path|
        record = saved_run("spec/fixtures/experiments/page_57_valid.yml",
                           output_path)

        profiles = record.fetch("observation").fetch("representations")

        expect(profiles.keys).to eq(%w[gp-runes-v1 gp-expanded-latin-v1])
      end
    end

    it "binds both profiles to the bytes actually saved" do
      Dir.mktmpdir do |output_path|
        record = saved_run("spec/fixtures/experiments/page_57_valid.yml",
                           output_path)
        profiles = record.fetch("observation").fetch("representations")
        artifacts = record.fetch("artifacts")
        output = File.binread(artifacts.fetch("output.txt").fetch("path"))
        provenance = File.binread(artifacts.fetch("provenance.json").fetch("path"))
        expected = [Digest::SHA256.hexdigest(output),
                    Digest::SHA256.hexdigest(provenance)]

        digests = profiles.values.map do |profile|
          profile.values_at("output_sha256", "provenance_sha256")
        end

        expect(digests).to eq([expected, expected])
      end
    end

    it "records the ordered 29 GP symbols for the decoded rune profile" do
      Dir.mktmpdir do |output_path|
        record = saved_run("spec/fixtures/experiments/page_57_valid.yml",
                           output_path)

        alphabet = record.fetch("observation").fetch("representations").
                   fetch("gp-runes-v1").fetch("alphabet")

        expect(alphabet).to eq(%w[ᚠ ᚢ ᚦ ᚩ ᚱ ᚳ ᚷ ᚹ ᚻ ᚾ ᛁ ᛄ ᛇ ᛈ ᛉ ᛋ ᛏ ᛒ ᛖ ᛗ ᛚ ᛝ ᛟ ᛞ ᚪ ᚫ ᚣ ᛡ ᛠ])
      end
    end

    it "records the complete 26-letter Latin alphabet" do
      Dir.mktmpdir do |output_path|
        record = saved_run("spec/fixtures/experiments/page_57_valid.yml",
                           output_path)

        alphabet = record.fetch("observation").fetch("representations").
                   fetch("gp-expanded-latin-v1").fetch("alphabet")

        expect(alphabet).to eq(("a".."z").to_a)
      end
    end

    it "snapshots the canonical GP expansion choices" do
      Dir.mktmpdir do |output_path|
        record = saved_run("spec/fixtures/experiments/page_57_valid.yml",
                           output_path)

        map = record.fetch("observation").fetch("representations").
              fetch("gp-expanded-latin-v1").fetch("expansion_map")

        expect(map.values_at("ᚢ", "ᚳ", "ᛋ", "ᚦ", "ᛝ", "ᛡ", "ᚫ", "ᛠ")).to eq(
          %w[u c s th ng io ae ea],
        )
      end
    end

    it "keeps original and decoded page-56 runes distinct in saved provenance" do
      Dir.mktmpdir do |output_path|
        record = saved_run("spec/fixtures/experiments/page_56_totient_controls.yml",
                           output_path)
        path = record.fetch("artifacts").fetch("provenance.json").fetch("path")
        profile = record.fetch("observation").fetch("representations").
                  fetch("gp-runes-v1")

        row = JSON.parse(File.binread(path)).fetch(57)

        expect([row.values_at("ordinal", "rune", profile.fetch("symbol_field"),
                              "latin", "page_number", "rune_index"),
                profile.fetch("sample_size")]).to eq([
                               [57, "ᚫ", "ᛖ", "e", 56, 57],
                               85,
                             ])
      end
    end

    it "counts only final GP tokens in the page-56 rune profile" do
      Dir.mktmpdir do |output_path|
        record = saved_run("spec/fixtures/experiments/page_56_totient_controls.yml",
                           output_path)

        profile = record.fetch("observation").fetch("representations").
                  fetch("gp-runes-v1")

        expect(profile).to include("schema_version" => 1,
                                   "stage" => "final",
                                   "artifact" => "provenance.json",
                                   "symbol_field" => "decoded_rune",
                                   "sample_size" => 85)
      end
    end

    it "excludes the page-56 hexadecimal passthrough from Latin sample size" do
      Dir.mktmpdir do |output_path|
        record = saved_run("spec/fixtures/experiments/page_56_totient_controls.yml",
                           output_path)

        profile = record.fetch("observation").fetch("representations").
                  fetch("gp-expanded-latin-v1")

        expect(profile.fetch("sample_size")).to eq(91)
      end
    end
  end
end
