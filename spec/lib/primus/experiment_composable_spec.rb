require "tmpdir"

RSpec.describe Primus::Experiment do
  def page_56_totient_definition
    Psych.safe_load(File.binread("spec/fixtures/experiments/page_56_totient_controls.yml"))
  end

  def load_definition(check, another_check = nil)
    Dir.mktmpdir do |directory|
      path = File.join(directory, "composition.yml")
      File.write(path, <<~YAML)
        schema_version: 2
        id: page-57-composed
        title: Page 57 Latin check
        purpose: Compare the whole-page Latin result.
        input:
          id: page-57
          sha256: c7055db0173e43eb231608812f5d52569e4c0817934b1a65427cebf332759fff
        recipe:
          id: latin
        output:
          policy: gp-latin-compatibility-v1
        checks:
          - id: check-1
      YAML
      File.open(path, "a") do |file|
        file.write(check.lines.map { |line| "    #{line}" }.join)
        file.write(another_check.to_s.lines.map { |line| "  #{line}" }.join)
      end
      yield Primus::Experiment.load(path: path)
    end
  end

  SHA512_CHECK = <<~YAML
        strategy: hash
        algorithm: sha512
        expectation:
          digest: f3fac0115ab06d1a4075731e77fe157ad52b837b9068bf942c95784160578f43a1a72e770f2e2c1b00a1bc2fad39dc66fa78efd28c5cd976ed3a35f3e400bcab
          provenance: Independent known answer.
  YAML

  describe "#valid?" do
    it "accepts the four independent page 56 checks with explicit skip 56" do
      experiment = Primus::Experiment.from_data(page_56_totient_definition)

      expect(experiment).to be_valid
    end

    it "uses page-independent defaults when the totient parameter mapping is absent" do
      definition = page_56_totient_definition
      definition.fetch("recipe").delete("parameters")
      experiment = Primus::Experiment.from_data(definition)

      experiment.valid?

      expect(experiment.canonical_configuration.fetch("recipe")).to eq(
        "id" => "totient-latin",
        "parameters" => { "modulus" => 29, "prime_start" => 2,
                          "skip_sequence" => [] }
      )
    end

    it "fills omitted totient keys without changing an explicit skip" do
      definition = page_56_totient_definition
      definition.fetch("recipe")["parameters"] = { "skip_sequence" => [56] }
      experiment = Primus::Experiment.from_data(definition)

      experiment.valid?

      expect(experiment.canonical_configuration.fetch("recipe").fetch("parameters")).to eq(
        "modulus" => 29, "prime_start" => 2, "skip_sequence" => [56]
      )
    end

    it "sorts a valid set of GP skip ordinals in canonical configuration" do
      definition = page_56_totient_definition
      definition.fetch("recipe").fetch("parameters")["skip_sequence"] = [57, 56]
      experiment = Primus::Experiment.from_data(definition)

      experiment.valid?

      expect(experiment.canonical_configuration.fetch("recipe").fetch("parameters").fetch("skip_sequence")).to eq([56, 57])
    end

    it "accepts the last page 56 GP ordinal as a skip" do
      definition = page_56_totient_definition
      definition.fetch("recipe").fetch("parameters")["skip_sequence"] = [84]
      experiment = Primus::Experiment.from_data(definition)

      expect(experiment).to be_valid
    end

    it "accepts a custom prime value as the start" do
      definition = page_56_totient_definition
      definition.fetch("recipe").fetch("parameters")["prime_start"] = 263
      experiment = Primus::Experiment.from_data(definition)

      expect(experiment).to be_valid
    end

    {
      "a null parameter mapping" => nil,
      "a list instead of a parameter mapping" => [],
      "an unknown parameter" => { "modulus" => 29, "surprise" => 1 },
      "a numeric-string prime" => { "prime_start" => "2" },
      "a composite prime start" => { "prime_start" => 4 },
      "a non-29 modulus" => { "modulus" => 31 },
      "duplicate skip ordinals" => { "skip_sequence" => [56, 56] },
      "the first out-of-range GP ordinal" => { "skip_sequence" => [85] },
      "a negative skip ordinal" => { "skip_sequence" => [-1] },
      "a floating skip ordinal" => { "skip_sequence" => [56.0] },
      "a null skip ordinal" => { "skip_sequence" => [nil] }
    }.each do |case_name, parameters|
      it "rejects #{case_name}" do
        definition = page_56_totient_definition
        definition.fetch("recipe")["parameters"] = parameters
        experiment = Primus::Experiment.from_data(definition)

        expect(experiment).not_to be_valid
      end
    end

    it "accepts two independent checks in declaration order" do
      another_check = <<~YAML
          - id: check-2
            strategy: plaintext
            expectation:
              path: experiments/expected/page-57-latin.txt
              sha256: 2d450628c6431f9497a6709f5af25d3dad2aa509c31d99ec3a00b07a42eb9a39
              provenance: Independent plaintext answer.
      YAML
      load_definition(SHA512_CHECK, another_check) do |experiment|
        result = experiment.valid?

        expect(result).to be(true)
      end
    end

    it "rejects a 32-byte target for a 64-byte SHA-512 check" do
      check = <<~YAML
            strategy: hash
            algorithm: sha512
            expectation:
              digest: #{'a' * 64}
              provenance: Independent known answer.
      YAML
      load_definition(check) do |experiment|
        experiment.valid?

        expect(experiment.errors.attribute_names).to include(:checks)
      end
    end

    it "rejects an unsupported hash algorithm" do
      check = <<~YAML
            strategy: hash
            algorithm: sha256
            expectation:
              digest: #{'a' * 64}
              provenance: Independent known answer.
      YAML
      load_definition(check) do |experiment|
        experiment.valid?

        expect(experiment.errors.attribute_names).to include(:checks)
      end
    end

    it "requires expectation provenance in YAML" do
      check = <<~YAML
            strategy: hash
            algorithm: sha512
            expectation:
              digest: f3fac0115ab06d1a4075731e77fe157ad52b837b9068bf942c95784160578f43a1a72e770f2e2c1b00a1bc2fad39dc66fa78efd28c5cd976ed3a35f3e400bcab
      YAML
      load_definition(check) do |experiment|
        experiment.valid?

        expect(experiment.errors.attribute_names).to include(:checks)
      end
    end
  end
end
