RSpec.describe "Primus::Analysis::RepeatedNgrams" do
  def source_positions(count)
    Array.new(count) do |index|
      { "rune_ordinal" => index, "page_number" => 57, "occurrence" => 0,
        "rune_index" => index, "byte_start" => index * 3,
        "byte_end" => (index + 1) * 3, "character_start" => index,
        "character_end" => index + 1, "line" => 0, "column" => index }
    end
  end

  def measure(symbols, lengths: [2, 3])
    Primus::Analysis::RepeatedNgrams.new(
      symbols: symbols, alphabet: Primus::Analysis::RUNES,
      position_map: source_positions(symbols.size), lengths: lengths,
      boundary_policy: "continuous-gp-v1", declaration_id: "rune-repeats",
      representation: "gp-runes-v1",
    ).to_result.to_h
  end

  describe "#to_result" do
    it "counts every overlapping AAAA pair and consecutive start gap" do
      symbols = %w[ᚪ ᚪ ᚪ ᚪ]

      result = measure(symbols)
      pairs = result.fetch("length_groups").first

      expect(pairs).to include(
        "length" => 2, "candidate_count" => 3,
        "distinct_pattern_count" => 1, "repeated_pattern_count" => 1,
        "repeated_occurrence_count" => 3,
        "patterns" => [{ "symbols" => %w[ᚪ ᚪ], "count" => 3,
                         "occurrences" => [{ "start_index" => 0, "end_index" => 2 },
                                           { "start_index" => 1, "end_index" => 3 },
                                           { "start_index" => 2, "end_index" => 4 }],
                         "gaps" => [1, 1] }],
      )
    end

    it "counts overlapping AAAA triples with two candidate starts" do
      symbols = %w[ᚪ ᚪ ᚪ ᚪ]

      result = measure(symbols)
      triples = result.fetch("length_groups").last

      expect(triples).to include(
        "length" => 3, "candidate_count" => 2,
        "distinct_pattern_count" => 1, "repeated_pattern_count" => 1,
        "repeated_occurrence_count" => 2,
        "patterns" => [{ "symbols" => %w[ᚪ ᚪ ᚪ], "count" => 2,
                         "occurrences" => [{ "start_index" => 0, "end_index" => 3 },
                                           { "start_index" => 1, "end_index" => 4 }],
                         "gaps" => [1] }],
      )
    end

    it "retains only repeated ABABA pairs in alphabet order" do
      symbols = %w[ᚪ ᚠ ᚪ ᚠ ᚪ]

      result = measure(symbols, lengths: [2])
      pairs = result.fetch("length_groups").first

      expect(pairs).to include(
        "candidate_count" => 4, "distinct_pattern_count" => 2,
        "repeated_pattern_count" => 2, "repeated_occurrence_count" => 4,
        "patterns" => [
          { "symbols" => %w[ᚠ ᚪ], "count" => 2,
            "occurrences" => [{ "start_index" => 1, "end_index" => 3 },
                              { "start_index" => 3, "end_index" => 5 }], "gaps" => [2] },
          { "symbols" => %w[ᚪ ᚠ], "count" => 2,
            "occurrences" => [{ "start_index" => 0, "end_index" => 2 },
                              { "start_index" => 2, "end_index" => 4 }], "gaps" => [2] },
        ],
      )
    end

    it "excludes the singleton BAB triple while counting its candidate" do
      symbols = %w[ᚪ ᚠ ᚪ ᚠ ᚪ]

      result = measure(symbols, lengths: [3])
      triples = result.fetch("length_groups").first

      expect(triples).to include(
        "candidate_count" => 3, "distinct_pattern_count" => 2,
        "repeated_pattern_count" => 1, "repeated_occurrence_count" => 2,
        "patterns" => [{ "symbols" => %w[ᚪ ᚠ ᚪ], "count" => 2,
                         "occurrences" => [{ "start_index" => 0, "end_index" => 3 },
                                           { "start_index" => 2, "end_index" => 5 }],
                         "gaps" => [2] }],
      )
    end

    it "marks both groups insufficient for an empty sequence" do
      symbols = []

      result = measure(symbols)
      groups = result.fetch("length_groups")

      expect(groups).to eq([
        { "length" => 2, "status" => "insufficient_sample", "candidate_count" => 0,
          "distinct_pattern_count" => 0, "repeated_pattern_count" => 0,
          "repeated_occurrence_count" => 0, "patterns" => [] },
        { "length" => 3, "status" => "insufficient_sample", "candidate_count" => 0,
          "distinct_pattern_count" => 0, "repeated_pattern_count" => 0,
          "repeated_occurrence_count" => 0, "patterns" => [] },
      ])
    end

    it "marks a singleton sequence insufficient for pairs" do
      symbols = %w[ᚪ]

      result = measure(symbols, lengths: [2])
      group = result.fetch("length_groups").first

      expect(group).to include("status" => "insufficient_sample",
                               "candidate_count" => 0, "patterns" => [])
    end

    it "keeps a computed singleton candidate when N equals n" do
      symbols = %w[ᚪ ᚠ]

      result = measure(symbols, lengths: [2])
      group = result.fetch("length_groups").first

      expect(group).to include("status" => "computed", "candidate_count" => 1,
                               "distinct_pattern_count" => 1,
                               "repeated_pattern_count" => 0,
                               "repeated_occurrence_count" => 0,
                               "patterns" => [])
    end

    it "owns the source map independently of caller mutation" do
      symbols = %w[ᚪ ᚠ]
      positions = source_positions(2)
      analyzer = Primus::Analysis::RepeatedNgrams.new(
        symbols: symbols, alphabet: Primus::Analysis::RUNES, position_map: positions,
        lengths: [2], boundary_policy: "continuous-gp-v1",
        declaration_id: "rune-repeats", representation: "gp-runes-v1",
      )

      result = analyzer.to_result
      positions.first["page_number"] = 99

      expect(result.to_h.fetch("position_map").first.fetch("page_number")).to eq(57)
    end
  end
end
