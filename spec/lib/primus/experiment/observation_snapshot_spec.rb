RSpec.describe Primus::Experiment::Observation do
  describe "#initialize" do
    it "owns nested source-coordinate arrays independently of caller mutation" do
      coordinates = [0, 3]
      provenance = [{ "source" => { "byte_span" => coordinates } }]
      observation = described_class.new(output_bytes: "f", provenance: provenance)

      coordinates[0] = 9

      expect(observation.provenance.first.fetch("source").fetch("byte_span")).to eq([0, 3])
    end

    it "owns nested provenance strings independently of caller mutation" do
      rune = +"ᚠ"
      provenance = [{ "rune" => rune }]
      observation = described_class.new(output_bytes: "f", provenance: provenance)

      rune.replace("ᚢ")

      expect(observation.provenance.first.fetch("rune")).to eq("ᚠ")
    end

    it "does not freeze the caller's provenance collection" do
      provenance = [{ "rune" => "ᚠ" }]

      described_class.new(output_bytes: "f", provenance: provenance)

      expect(provenance).not_to be_frozen
    end
  end
end
