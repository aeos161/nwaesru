RSpec.describe Primus::Experiment::Chain do
  def two_page_transcription
    first = Primus::LiberPrimus::Page.new(number: 99, data: "ᚠ-ᚢ",
                                          source_body: "ᚠ-ᚢ")
    second = Primus::LiberPrimus::Page.new(number: 100, data: "ᚦᚣ",
                                           source_body: "ᚦᚣ")
    scans = [first, second].each_with_index.map do |page, occurrence|
      Primus::Lexer::SourceScan.new(page: page, strategy: :runic,
                                    occurrence: occurrence).to_transcription
    end
    Primus::Transcription.compose(scans)
  end

  def step(id, operation, parameters)
    { "id" => id, "operation" => operation, "parameters" => parameters }
  end

  def reversal_step
    step("reverse", "reverse-runes", { "scope" => "composed-input", "non_runes" => "fixed" })
  end

  def totient_step
    step("shift", "totient", { "modulus" => 29, "prime_start" => 2, "skip_sequence" => [] })
  end

  def atbash_step
    step("mirror", "atbash", { "alphabet" => "gematria-primus", "modulus" => 29 })
  end

  def latin_step
    step("letters", "latin", {})
  end

  def run_steps(steps)
    chain = described_class.new(steps: steps, transcription: two_page_transcription,
                                publisher: ->(_checkpoint) {})
    chain.run
    chain
  end

  def checkpoint(chain, step_id)
    chain.checkpoints.find { |item| item.step.fetch("id") == step_id }
  end

  describe "#run" do
    it "applies reversal across both pages before consuming global primes" do
      chain = run_steps([reversal_step, totient_step, latin_step])

      bytes = checkpoint(chain, "shift").output_bytes

      expect(bytes).to eq("ᚫ-ᚠᚣᛞ".b)
    end

    it "produces a distinct literal result when totient precedes reversal" do
      chain = run_steps([totient_step, reversal_step, latin_step])

      bytes = checkpoint(chain, "reverse").output_bytes

      expect(bytes).to eq("ᛚ-ᛡᛠᛠ".b)
    end

    it "renders expanded Latin runes after reversal then totient" do
      chain = run_steps([reversal_step, totient_step, latin_step])

      result = chain.observation.output_bytes

      expect(result).to eq("ae f\nyd")
    end

    it "moves the second page's last rune into the first processing slot" do
      chain = run_steps([reversal_step, totient_step, latin_step])

      first = checkpoint(chain, "reverse").symbols.first

      expect(first.values_at("ordinal", "rune", "page_number", "occurrence", "rune_index")).to eq(
        [0, "ᚣ", 100, 1, 1]
      )
    end

    it "keeps the moved rune's source identity through totient" do
      chain = run_steps([reversal_step, totient_step, latin_step])

      first = checkpoint(chain, "shift").symbols.first

      expect(first.values_at("ordinal", "rune", "page_number", "occurrence", "rune_index")).to eq(
        [0, "ᚫ", 100, 1, 1]
      )
    end

    it "keeps Atbash and reversal commutative at the rune output" do
      first = run_steps([atbash_step, reversal_step, latin_step])
      second = run_steps([reversal_step, atbash_step, latin_step])

      outputs = [checkpoint(first, "reverse").output_bytes,
                 checkpoint(second, "mirror").output_bytes]

      expect(outputs).to eq(["ᚦ-ᚣᛡᛠ".b, "ᚦ-ᚣᛡᛠ".b])
    end

    it "captures declared operation order in independent checkpoint histories" do
      first = run_steps([atbash_step, reversal_step, latin_step])
      second = run_steps([reversal_step, atbash_step, latin_step])

      histories = [first, second].map do |chain|
        chain.checkpoints.map { |item| item.step.fetch("operation") }
      end

      expect(histories).to eq([
        %w[capture atbash reverse-runes latin],
        %w[capture reverse-runes atbash latin]
      ])
    end
  end
end
