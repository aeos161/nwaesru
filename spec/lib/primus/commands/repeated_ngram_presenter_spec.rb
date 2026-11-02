RSpec.describe Primus::Commands::RepeatedNgramPresenter do
  def result_for(representation:, sample_size:, groups:, positions: [])
    Primus::Analysis::RepeatedNgramResult.new(
      "declaration_id" => "rune-repeats",
      "representation" => representation,
      "sample_size" => sample_size,
      "boundary_policy" => "continuous-gp-v1",
      "length_groups" => groups,
      "position_map" => positions,
    )
  end

  def group_for(length:, status: "computed", patterns: [], candidates: 0,
                distinct: 0, repeated: 0, occurrences: 0)
    { "length" => length, "status" => status,
      "candidate_count" => candidates,
      "distinct_pattern_count" => distinct,
      "repeated_pattern_count" => repeated,
      "repeated_occurrence_count" => occurrences,
      "patterns" => patterns }
  end

  def pattern_for(symbols, starts)
    { "symbols" => symbols.chars, "count" => starts.length,
      "occurrences" => starts.map { |start| { "start_index" => start,
                                              "end_index" => start + symbols.length } },
      "gaps" => starts.each_cons(2).map { |first, second| second - first } }
  end

  describe "#lines" do
    it "summarizes saved aggregates as overlapping occurrences in GP units" do
      group = group_for(length: 2, candidates: 3, distinct: 1,
                        repeated: 1, occurrences: 3,
                        patterns: [pattern_for("ᚪᚪ", [0, 1, 2])])
      result = result_for(representation: "gp-runes-v1", sample_size: 4,
                          groups: [group])

      output = described_class.new(result: result, stage: "original").lines.join("\n")

      expect(output).to match(/GP runes.*sample size 4.*length 2.*candidate count 3.*distinct patterns 1.*repeated patterns 1.*overlapping occurrences 3/im)
    end

    it "ranks tied patterns in saved canonical order after higher counts" do
      patterns = [pattern_for("ᚪᚪ", [0, 4]), pattern_for("ᚠᚠ", [1, 5]),
                  pattern_for("ᚳᚳ", [2, 6, 10])]
      result = result_for(representation: "gp-runes-v1", sample_size: 12,
                          groups: [group_for(length: 2, patterns: patterns)])

      output = described_class.new(result: result, stage: "final").lines.join("\n")

      expect(output).to match(/ᚳᚳ.*ᚪᚪ.*ᚠᚠ/m)
    end

    it "shows exactly ten rows without an omission message" do
      patterns = %w[ᚠ ᚢ ᚦ ᚩ ᚱ ᚳ ᚷ ᚹ ᚻ ᚾ].each_with_index.map do |rune, index|
        pattern_for("ᚪ#{rune}", [index, index + 20])
      end
      result = result_for(representation: "gp-runes-v1", sample_size: 40,
                          groups: [group_for(length: 2, patterns: patterns)])

      output = described_class.new(result: result, stage: "final").lines.join("\n")

      expect(output).not_to match(/(?:1 pattern omitted|1 more pattern)/i)
    end

    it "caps eleven rows and reports the one omitted pattern" do
      patterns = %w[ᚠ ᚢ ᚦ ᚩ ᚱ ᚳ ᚷ ᚹ ᚻ ᚾ ᛁ].each_with_index.map do |rune, index|
        pattern_for("ᚪ#{rune}", [index, index + 20])
      end
      result = result_for(representation: "gp-runes-v1", sample_size: 40,
                          groups: [group_for(length: 2, patterns: patterns)])

      output = described_class.new(result: result, stage: "final").lines.join("\n")

      expect(output).to match(/(?:1 pattern omitted|1 more pattern)/i)
    end

    it "shows eight starts without truncating their cell" do
      starts = (0...8).to_a
      result = result_for(representation: "gp-runes-v1", sample_size: 9,
                          groups: [group_for(length: 2,
                                             patterns: [pattern_for("ᚪᚪ", starts)])])

      output = described_class.new(result: result, stage: "final").lines.join("\n")

      expect(output).not_to match(/(?:start[^\n]*1 omitted|start[^\n]*1 more)/i)
    end

    it "caps nine starts while retaining all eight consecutive gaps" do
      starts = (0...9).to_a
      result = result_for(representation: "gp-runes-v1", sample_size: 10,
                          groups: [group_for(length: 2,
                                             patterns: [pattern_for("ᚪᚪ", starts)])])

      output = described_class.new(result: result, stage: "final").lines.join("\n")

      expect(output).to match(/start[^\n]*0.*7.*1 (?:omitted|more)/i)
    end

    it "counts omitted gaps independently when there are ten starts" do
      starts = (0...10).to_a
      result = result_for(representation: "gp-runes-v1", sample_size: 11,
                          groups: [group_for(length: 2,
                                             patterns: [pattern_for("ᚪᚪ", starts)])])

      output = described_class.new(result: result, stage: "final").lines.join("\n")

      expect(output).to match(/gap[^\n]*1 (?:omitted|more)/i)
    end

    it "distinguishes an insufficient empty sample from computed repetition" do
      result = result_for(representation: "gp-runes-v1", sample_size: 0,
                          groups: [group_for(length: 2, status: "insufficient_sample")])

      output = described_class.new(result: result, stage: "original").lines.join("\n")

      expect(output).to match(/(?:insufficient sample|sample too short|N\s*<\s*2)/i)
    end

    it "explains a computed result without repeated patterns" do
      result = result_for(representation: "gp-runes-v1", sample_size: 2,
                          groups: [group_for(length: 2, candidates: 1, distinct: 1)])

      output = described_class.new(result: result, stage: "original").lines.join("\n")

      expect(output).to match(/(?:no repeated patterns|none repeated)/i)
    end

    it "labels Latin letters and explains repeats within one source rune" do
      result = result_for(representation: "gp-expanded-latin-v1", sample_size: 5,
                          groups: [group_for(length: 2, candidates: 4, distinct: 3,
                                             repeated: 1, occurrences: 2,
                                             patterns: [pattern_for("th", [0, 3])])])

      output = described_class.new(result: result, stage: "original").lines.join("\n")

      expect(output).to match(/Latin letters.*(?:within one source rune|inside one source rune)/im)
    end

    it "prints labeled coordinates for each expanded position in details" do
      positions = (0..1).map do |offset|
        { "rune_ordinal" => 0, "page_number" => 57, "occurrence" => 1,
          "rune_index" => 2, "byte_start" => 6, "byte_end" => 9,
          "character_start" => 2, "character_end" => 3,
          "line" => 0, "column" => 2,
          "expansion_offset" => offset, "expansion_length" => 2 }
      end
      result = result_for(representation: "gp-expanded-latin-v1", sample_size: 2,
                          groups: [group_for(length: 2)], positions: positions)

      output = described_class.new(result: result, stage: "original",
                                   details: true).lines.join("\n")

      expect(output).to match(/source (?:map )?0:.*page(?:_number)? 57.*expansion(?:_offset)? 0.*source (?:map )?1:.*expansion(?:_offset)? 1/im)
    end

    it "omits indexed source positions from the default overview" do
      position = { "rune_ordinal" => 0, "page_number" => 57,
                   "occurrence" => 0, "rune_index" => 0,
                   "byte_start" => 0, "byte_end" => 3,
                   "character_start" => 0, "character_end" => 1,
                   "line" => 0, "column" => 0 }
      result = result_for(representation: "gp-runes-v1", sample_size: 1,
                          groups: [group_for(length: 2, status: "insufficient_sample")],
                          positions: [position])

      output = described_class.new(result: result, stage: "original").lines.join("\n")

      expect(output).not_to match(/source map 0:|rune_ordinal.*page_number/i)
    end

    it "does not mutate saved canonical pattern order while presenting by frequency" do
      patterns = [pattern_for("ᚪᚪ", [0, 4]), pattern_for("ᚳᚳ", [2, 6, 10])]
      result = result_for(representation: "gp-runes-v1", sample_size: 12,
                          groups: [group_for(length: 2, patterns: patterns)])

      described_class.new(result: result, stage: "final").lines

      expect(result.length_groups.first.fetch("patterns").map { |item| item.fetch("symbols").join }).to eq(%w[ᚪᚪ ᚳᚳ])
    end
  end
end
