RSpec.describe "Primus::Analysis::SymbolStatistics" do
  GP_ALPHABET = %w[ᚠ ᚢ ᚦ ᚩ ᚱ ᚳ ᚷ ᚹ ᚻ ᚾ ᛁ ᛄ ᛇ ᛈ ᛉ ᛋ ᛏ ᛒ ᛖ ᛗ ᛚ ᛝ ᛟ ᛞ ᚪ ᚫ ᚣ ᛡ ᛠ].freeze
  LATIN_ALPHABET = ("a".."z").to_a.freeze

  def statistics(symbols, alphabet, representation)
    Primus::Analysis::SymbolStatistics.new(
      symbols: symbols, alphabet: alphabet, declaration_id: "sample",
      representation: representation,
    ).to_result.to_h
  end

  describe "#to_result" do
    it "counts repeated GP runes as exact raw matching pairs" do
      symbols = %w[ᚠ ᚠ ᚢ ᚢ]

      result = statistics(symbols, GP_ALPHABET, "gp-runes-v1")

      expect(result.fetch("ic")).to include(
        "status" => "computed", "normalization" => "none",
        "numerator" => 4, "denominator" => 12, "value" => (1.0 / 3),
      )
    end

    it "counts identical symbols with raw IC one" do
      symbols = %w[ᚠ ᚠ ᚠ]

      result = statistics(symbols, GP_ALPHABET, "gp-runes-v1")

      expect(result.fetch("ic").fetch("value")).to eq(1.0)
    end

    it "counts distinct symbols with raw IC zero" do
      symbols = %w[ᚠ ᚢ ᚦ]

      result = statistics(symbols, GP_ALPHABET, "gp-runes-v1")

      expect(result.fetch("ic")).to include(
        "numerator" => 0, "denominator" => 6, "value" => 0.0,
      )
    end

    it "counts a digraph rune once in its 29-symbol space" do
      symbols = %w[ᚦ ᚪ ᚦ]

      result = statistics(symbols, GP_ALPHABET, "gp-runes-v1")

      expect(result).to include("sample_size" => 3, "distinct_count" => 2,
                                "alphabet_size" => 29,
                                "ic" => include("numerator" => 2,
                                                "denominator" => 6,
                                                "value" => (1.0 / 3)))
    end

    it "counts expanded Latin letters in their own 26-letter space" do
      symbols = %w[t h a t h]

      result = statistics(symbols, LATIN_ALPHABET, "gp-expanded-latin-v1")

      expect(result).to include("sample_size" => 5, "distinct_count" => 3,
                                "alphabet_size" => 26,
                                "ic" => include("numerator" => 4,
                                                "denominator" => 20,
                                                "value" => (1.0 / 5)))
    end

    it "returns every alphabet bin in declared order, including zeros" do
      symbols = %w[t h a t h]

      result = statistics(symbols, LATIN_ALPHABET, "gp-expanded-latin-v1")
      bins = result.fetch("frequencies")

      expect(bins).to eq(LATIN_ALPHABET.each_with_index.map do |letter, index|
        count = { "a" => 1, "h" => 2, "t" => 2 }.fetch(letter, 0)
        { "index" => index, "symbol" => letter, "count" => count,
          "relative_frequency" => count / 5.0 }
      end)
    end

    it "retains zero bins and null proportions for an empty sample" do
      symbols = []

      result = statistics(symbols, GP_ALPHABET, "gp-runes-v1")

      expect(result.fetch("frequencies")).to eq(
        GP_ALPHABET.each_with_index.map do |rune, index|
          { "index" => index, "symbol" => rune, "count" => 0,
            "relative_frequency" => nil }
        end,
      )
    end

    it "marks empty-sample IC insufficient with an exact zero denominator" do
      symbols = []

      result = statistics(symbols, GP_ALPHABET, "gp-runes-v1")

      expect(result.fetch("ic")).to include(
        "status" => "insufficient_sample", "normalization" => "none",
        "numerator" => 0, "denominator" => 0, "value" => nil,
      )
    end

    it "gives the sole observed symbol frequency one while IC is undefined" do
      symbols = %w[ᚦ]

      result = statistics(symbols, GP_ALPHABET, "gp-runes-v1")

      expect(result.fetch("frequencies").fetch(2)).to eq(
        "index" => 2, "symbol" => "ᚦ", "count" => 1,
        "relative_frequency" => 1.0,
      )
    end

    it "marks a one-symbol sample insufficient without serializing NaN" do
      symbols = %w[ᚦ]

      result = statistics(symbols, GP_ALPHABET, "gp-runes-v1")

      expect(result.fetch("ic")).to include(
        "status" => "insufficient_sample", "numerator" => 0,
        "denominator" => 0, "value" => nil,
      )
    end

    it "does not attach a language or pass/fail judgment" do
      symbols = %w[ᚠ ᚠ]

      result = statistics(symbols, GP_ALPHABET, "gp-runes-v1")

      expect(result.keys & %w[comparison match mismatch pass fail
                              language likelihood ranking]).to be_empty
    end

    it "returns owned immutable nested measurement data" do
      symbols = %w[ᚠ ᚠ]

      result = Primus::Analysis::SymbolStatistics.new(
        symbols: symbols, alphabet: GP_ALPHABET, declaration_id: "sample",
        representation: "gp-runes-v1",
      ).to_result

      expect(result.frequencies.first).to be_frozen
    end
  end
end
