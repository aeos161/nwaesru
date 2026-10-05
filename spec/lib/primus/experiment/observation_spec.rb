RSpec.describe Primus::Experiment::Observation do
  describe "#output_bytes" do
    it "exposes non-ASCII UTF-8 input with binary encoding" do
      input = "café"

      observation = Primus::Experiment::Observation.new(output_bytes: input)

      expect(observation.output_bytes.encoding).to eq(Encoding::BINARY)
    end

    it "preserves the exact non-ASCII bytes" do
      input = "café"

      observation = Primus::Experiment::Observation.new(output_bytes: input)

      expect(observation.output_bytes.bytes).to eq([99, 97, 102, 195, 169])
    end

    it "owns an independent output copy after the caller changes its input" do
      input = "café"
      observation = Primus::Experiment::Observation.new(output_bytes: input)

      input.replace("other")

      expect(observation.output_bytes.bytes).to eq([99, 97, 102, 195, 169])
    end

    it "freezes the owned output bytes" do
      input = "café"

      observation = Primus::Experiment::Observation.new(output_bytes: input)

      expect(observation.output_bytes).to be_frozen
    end

    it "leaves the caller's input encoding unchanged" do
      input = "café"

      Primus::Experiment::Observation.new(output_bytes: input)

      expect(input.encoding).to eq(Encoding::UTF_8)
    end

    it "does not freeze the caller's input" do
      input = "café"

      Primus::Experiment::Observation.new(output_bytes: input)

      expect(input).not_to be_frozen
    end
  end
end
