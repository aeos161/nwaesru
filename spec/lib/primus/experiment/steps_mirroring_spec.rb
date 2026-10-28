RSpec.describe Primus::Experiment::Steps do
  def step(id, operation, parameters)
    { "id" => id, "operation" => operation, "parameters" => parameters }
  end

  def latin_step
    step("letters", "latin", {})
  end

  def atbash_step
    step("mirror", "atbash", { "alphabet" => "gematria-primus", "modulus" => 29 })
  end

  def reversal_step
    step("reverse", "reverse-runes", { "scope" => "composed-input", "non_runes" => "fixed" })
  end

  def totient_step
    step("shift", "totient", { "modulus" => 29, "prime_start" => 2, "skip_sequence" => [] })
  end

  describe "#valid?" do
    [
      %w[atbash reverse-runes totient latin],
      %w[totient atbash reverse-runes latin],
      %w[reverse-runes totient atbash latin]
    ].each do |operations|
      it "accepts the declared #{operations.join(', ')} order" do
        available = { "atbash" => atbash_step, "reverse-runes" => reversal_step,
                      "totient" => totient_step, "latin" => latin_step }
        steps = operations.map { |operation| available.fetch(operation) }

        result = described_class.new(steps).valid?

        expect(result).to be_truthy
      end
    end

    {
      "missing Atbash alphabet" => { "modulus" => 29 },
      "unsupported Atbash alphabet" => { "alphabet" => "other", "modulus" => 29 },
      "unsupported Atbash modulus" => { "alphabet" => "gematria-primus", "modulus" => 31 },
      "noninteger Atbash modulus" => { "alphabet" => "gematria-primus", "modulus" => "29" },
      "unknown Atbash parameter" => { "alphabet" => "gematria-primus", "modulus" => 29,
                                      "direction" => "backward" }
    }.each do |case_name, parameters|
      it "rejects #{case_name}" do
        steps = [step("mirror", "atbash", parameters), latin_step]

        result = described_class.new(steps).valid?

        expect(result).to be_falsy
      end
    end

    {
      "missing reversal scope" => { "non_runes" => "fixed" },
      "per-page reversal" => { "scope" => "page", "non_runes" => "fixed" },
      "moving delimiters" => { "scope" => "composed-input", "non_runes" => "reversed" },
      "unknown reversal parameter" => { "scope" => "composed-input", "non_runes" => "fixed",
                                        "direction" => "backward" }
    }.each do |case_name, parameters|
      it "rejects #{case_name}" do
        steps = [step("reverse", "reverse-runes", parameters), latin_step]

        result = described_class.new(steps).valid?

        expect(result).to be_falsy
      end
    end

    it "rejects a transformation after terminal Latin" do
      steps = [latin_step, atbash_step]

      result = described_class.new(steps).valid?

      expect(result).to be_falsy
    end

    it "rejects a repeated Atbash step ID" do
      steps = [atbash_step, atbash_step, latin_step]

      result = described_class.new(steps).valid?

      expect(result).to be_falsy
    end

    it "rejects a reserved reversal step ID" do
      steps = [step("original", "reverse-runes", reversal_step.fetch("parameters")), latin_step]

      result = described_class.new(steps).valid?

      expect(result).to be_falsy
    end
  end

  describe "#canonical" do
    it "retains each operation and its own parameters in declared order" do
      steps = [atbash_step, reversal_step, totient_step, latin_step]
      model = described_class.new(steps)

      result = model.canonical

      expect(result).to eq(steps)
    end
  end
end
