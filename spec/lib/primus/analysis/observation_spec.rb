RSpec.describe "Primus::Analysis::Observation" do
  def observation(symbols:, profiles:, evidence:)
    Primus::Analysis::Observation.new(
      experiment_id: "tiny-final",
      run_id: "20261009T000000-000000000001",
      directory: "/tmp/tiny-final/20261009T000000-000000000001",
      symbols_by_representation: symbols, profiles: profiles,
      evidence: evidence,
    )
  end

  describe "#symbols" do
    it "returns the requested verified sample space" do
      symbols = { "gp-runes-v1" => %w[ᚦ ᚪ ᚦ],
                  "gp-expanded-latin-v1" => %w[t h a t h] }
      input = observation(symbols: symbols, profiles: {}, evidence: {})

      result = input.symbols("gp-expanded-latin-v1")

      expect(result).to eq(%w[t h a t h])
    end

    it "keeps the captured sequence after its caller mutates the source" do
      runes = %w[ᚦ ᚪ ᚦ]
      input = observation(symbols: { "gp-runes-v1" => runes },
                          profiles: {}, evidence: {})

      runes << "ᚠ"

      expect(input.symbols("gp-runes-v1")).to eq(%w[ᚦ ᚪ ᚦ])
    end
  end

  describe "#alphabet" do
    it "returns the selected representation's declared alphabet" do
      profiles = { "gp-expanded-latin-v1" => { "alphabet" => ("a".."z").to_a } }
      input = observation(symbols: {}, profiles: profiles, evidence: {})

      result = input.alphabet("gp-expanded-latin-v1")

      expect(result).to eq(("a".."z").to_a)
    end

    it "keeps alphabet data after its caller changes the original profile" do
      alphabet = %w[ᚠ ᚢ ᚦ]
      profiles = { "gp-runes-v1" => { "alphabet" => alphabet } }
      input = observation(symbols: {}, profiles: profiles, evidence: {})

      alphabet << "?"

      expect(input.alphabet("gp-runes-v1")).to eq(%w[ᚠ ᚢ ᚦ])
    end
  end

  describe "#profile" do
    it "returns the requested versioned profile" do
      profiles = { "gp-runes-v1" => { "schema_version" => 1,
                                     "sample_size" => 3, "alphabet" => %w[ᚠ ᚢ ᚦ] } }
      input = observation(symbols: {}, profiles: profiles, evidence: {})

      result = input.profile("gp-runes-v1")

      expect(result).to include("schema_version" => 1, "sample_size" => 3)
    end
  end

  describe "#evidence" do
    it "keeps nested artifact identity after its caller mutates the source" do
      output = { "sha256" => "captured-digest", "bytes" => 5 }
      input = observation(symbols: {}, profiles: {},
                          evidence: { "observation_output" => output })

      output["sha256"] = "changed-digest"

      expect(input.evidence.fetch("observation_output").fetch("sha256")).to eq(
        "captured-digest",
      )
    end

    it "exposes frozen nested measurement evidence" do
      evidence = { "observation_output" => { "sha256" => "captured-digest" } }
      input = observation(symbols: {}, profiles: {}, evidence: evidence)

      result = input.evidence.fetch("observation_output")

      expect(result).to be_frozen
    end
  end

  describe "#experiment_id" do
    it "identifies the selected saved experiment" do
      input = observation(symbols: {}, profiles: {}, evidence: {})

      result = input.experiment_id

      expect(result).to eq("tiny-final")
    end
  end

  describe "#run_id" do
    it "identifies the selected saved run" do
      input = observation(symbols: {}, profiles: {}, evidence: {})

      result = input.run_id

      expect(result).to eq("20261009T000000-000000000001")
    end
  end

  describe "#directory" do
    it "locates the selected saved run" do
      input = observation(symbols: {}, profiles: {}, evidence: {})

      result = input.directory

      expect(result).to eq("/tmp/tiny-final/20261009T000000-000000000001")
    end
  end

  describe "#record" do
    it "does not expose the raw observation record" do
      input = observation(symbols: {}, profiles: {}, evidence: {})

      available = input.respond_to?(:record)

      expect(available).to be_falsy
    end
  end

  describe "#record_bytes" do
    it "does not expose raw record bytes" do
      input = observation(symbols: {}, profiles: {}, evidence: {})

      available = input.respond_to?(:record_bytes)

      expect(available).to be_falsy
    end
  end
end
