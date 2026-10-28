require "digest"
require "json"
require "tmpdir"

RSpec.describe "Repeated n-gram saved analysis" do
  include SavedAnalysisHelper

  def repeated_definition(root, stage:, representation:)
    path = File.join(root, "repeated.yml")
    entry = { "id" => "repeats", "analyzer" => "repeated-ngrams", "version" => 1,
              "parameters" => { "lengths" => [2, 3],
                                "boundary_policy" => "continuous-gp-v1" },
              "target" => { "stage" => stage, "representation" => representation } }
    File.write(path, Psych.dump("schema_version" => 1, "id" => "repeated-check",
                                "analyses" => [entry]))
    path
  end

  def run_repeated(root, runes:, letters:, output:, stage:, representation:)
    id, run_id = independent_three_rune_observation(root, runes: runes,
                                                     letters: letters, output: output)
    definition_path = repeated_definition(root, stage: stage,
                                          representation: representation)
    definition = Primus::Analysis::Definition.new(path: definition_path)
    observation = Primus::Analysis::ObservationReader.new(
      output_path: root, experiment_id: id, run_id: run_id, stage: stage,
    ).to_observation
    runner = Primus::Analysis::Runner.new(definition: definition, observation: observation)
    runner.run
    runner.log_entry
  end

  describe "#run" do
    it "retains the original GP pair denominator without a false repeat" do
      Dir.mktmpdir do |root|
        entry = run_repeated(root, runes: %w[ᚦ ᚪ ᚦ], letters: %w[th a th],
                            output: "thath", stage: "original",
                            representation: "gp-runes-v1")

        pair = entry.to_h.fetch("results").first.fetch("result").
               fetch("length_groups").first

        expect(pair).to include("candidate_count" => 2,
                                "distinct_pattern_count" => 2,
                                "repeated_pattern_count" => 0,
                                "repeated_occurrence_count" => 0,
                                "patterns" => [])
      end
    end

    it "finds repeated th inside two expanded runes" do
      Dir.mktmpdir do |root|
        entry = run_repeated(root, runes: %w[ᚦ ᚪ ᚦ], letters: %w[th a th],
                            output: "thath", stage: "original",
                            representation: "gp-expanded-latin-v1")

        pair = entry.to_h.fetch("results").first.fetch("result").
               fetch("length_groups").first

        expect(pair.fetch("patterns")).to include(
          "symbols" => %w[t h], "count" => 2,
          "occurrences" => [{ "start_index" => 0, "end_index" => 2 },
                            { "start_index" => 3, "end_index" => 5 }],
          "gaps" => [3],
        )
      end
    end

    it "maps both letters of an expanded th to one original rune" do
      Dir.mktmpdir do |root|
        entry = run_repeated(root, runes: %w[ᚦ ᚪ ᚦ], letters: %w[th a th],
                            output: "thath", stage: "original",
                            representation: "gp-expanded-latin-v1")

        positions = entry.to_h.fetch("results").first.fetch("result").
                    fetch("position_map")

        expect(positions.first(2)).to eq([
          { "rune_ordinal" => 0, "page_number" => 57, "occurrence" => 0,
            "rune_index" => 0, "byte_start" => 0, "byte_end" => 3,
            "character_start" => 0, "character_end" => 1,
            "line" => 0, "column" => 0,
            "expansion_offset" => 0, "expansion_length" => 2 },
          { "rune_ordinal" => 0, "page_number" => 57, "occurrence" => 0,
            "rune_index" => 0, "byte_start" => 0, "byte_end" => 3,
            "character_start" => 0, "character_end" => 1,
            "line" => 0, "column" => 0,
            "expansion_offset" => 1, "expansion_length" => 2 },
        ])
      end
    end

    it "distinguishes a th formed by adjacent source runes" do
      Dir.mktmpdir do |root|
        entry = run_repeated(root, runes: %w[ᛏ ᚻ ᛏ ᚻ],
                            letters: %w[t h t h], output: "thth",
                            stage: "original",
                            representation: "gp-expanded-latin-v1")

        positions = entry.to_h.fetch("results").first.fetch("result").
                    fetch("position_map")

        expect(positions.map { |position| position.fetch("rune_ordinal") }).
          to eq([0, 1, 2, 3])
      end
    end

    it "retains declared analyzer parameters and checkpoint identity" do
      Dir.mktmpdir do |root|
        entry = run_repeated(root, runes: %w[ᚦ ᚪ ᚦ], letters: %w[th a th],
                            output: "thath", stage: "final",
                            representation: "gp-expanded-latin-v1")

        envelope = entry.to_h.fetch("results").first

        expect(envelope).to include(
          "analyzer" => "repeated-ngrams", "version" => 1,
          "parameters" => { "lengths" => [2, 3],
                            "boundary_policy" => "continuous-gp-v1" },
          "stage" => "final", "checkpoint_step_id" => "letters",
          "representation" => "gp-expanded-latin-v1",
        )
      end
    end

    it "keeps the saved definition digest tied to exact bytes" do
      Dir.mktmpdir do |root|
        entry = run_repeated(root, runes: %w[ᚦ ᚪ ᚦ], letters: %w[th a th],
                            output: "thath", stage: "original",
                            representation: "gp-runes-v1")
        bytes = File.binread(File.join(root, "repeated.yml"))

        digest = entry.definition_sha256

        expect(digest).to eq(Digest::SHA256.hexdigest(bytes))
      end
    end
  end

  describe "#review" do
    it "restores the same measurements after the live definition changes" do
      Dir.mktmpdir do |root|
        entry = run_repeated(root, runes: %w[ᚦ ᚪ ᚦ], letters: %w[th a th],
                            output: "thath", stage: "original",
                            representation: "gp-expanded-latin-v1")
        File.binwrite(File.join(root, "repeated.yml"), "changed")
        directory = File.join(root, entry.experiment_id, entry.run_id)
        store = Primus::Analysis::Store.new(directory: File.realpath(directory))

        restored = store.review(entry.analysis_run_id).first

        expect(restored.measurements.first.to_h).to eq(entry.measurements.first.to_h)
      end
    end
  end
end
