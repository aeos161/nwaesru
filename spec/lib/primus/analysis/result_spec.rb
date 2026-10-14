RSpec.describe "Primus::Analysis::Result" do
  def result
    Primus::Analysis::SymbolStatistics.new(
      symbols: %w[ᚦ ᚪ ᚦ], alphabet: %w[ᚦ ᚪ ᚠ],
      declaration_id: "rune-statistics", representation: "gp-runes-v1",
    ).to_result
  end

  describe "#declaration_id" do
    it "identifies the analysis declaration that owns the measurement" do
      measurement = result

      declaration_id = measurement.declaration_id

      expect(declaration_id).to eq("rune-statistics")
    end
  end

  describe "#representation" do
    it "identifies the measured symbol space" do
      measurement = result

      representation = measurement.representation

      expect(representation).to eq("gp-runes-v1")
    end
  end

  describe "#alphabet_size" do
    it "reports the declared alphabet cardinality" do
      measurement = result

      alphabet_size = measurement.alphabet_size

      expect(alphabet_size).to eq(3)
    end
  end

  describe "#sample_size" do
    it "reports the number of measured GP symbols" do
      measurement = result

      sample_size = measurement.sample_size

      expect(sample_size).to eq(3)
    end
  end

  describe "#distinct_count" do
    it "reports observed symbols without treating a digraph as two" do
      measurement = result

      distinct_count = measurement.distinct_count

      expect(distinct_count).to eq(2)
    end
  end

  describe "#ic" do
    it "reports the raw pair-count measurement" do
      measurement = result

      ic = measurement.ic

      expect(ic).to include("normalization" => "none", "numerator" => 2,
                            "denominator" => 6, "value" => (1.0 / 3))
    end
  end
end
