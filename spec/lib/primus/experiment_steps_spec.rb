require "tempfile"

RSpec.describe Primus::Experiment do
  def explicit_definition
    definition = Psych.safe_load(
      File.binread("spec/fixtures/experiments/page_56_totient_controls.yml")
    )
    definition["steps"] = [
      { "id" => "first", "operation" => "totient",
        "parameters" => { "modulus" => 29, "prime_start" => 2,
                          "skip_sequence" => [56] } },
      { "id" => "letters", "operation" => "latin", "parameters" => {} }
    ]
    definition
  end

  describe ".load" do
    it "rejects a duplicate YAML key inside a declared step" do
      source = <<~YAML
        schema_version: 2
        steps:
          - id: first
            operation: totient
            operation: latin
            parameters: {}
      YAML

      action = -> {
        Tempfile.create(["duplicate-step", ".yml"]) do |file|
          file.write(source)
          file.flush
          described_class.load(path: file.path)
        end
      }

      expect(action).to raise_error(Primus::Experiment::LoadError)
    end
  end

  describe "#valid?" do
    it "accepts a terminal Latin step without a totient layer" do
      definition = explicit_definition
      definition["steps"].shift
      experiment = described_class.from_data(definition)

      result = experiment.valid?

      expect(result).to be_truthy
    end

    it "accepts repeated independent totient layers" do
      definition = explicit_definition
      definition["steps"].insert(1, {
        "id" => "second", "operation" => "totient",
        "parameters" => { "modulus" => 29, "prime_start" => 3,
                          "skip_sequence" => [57] }
      })
      experiment = described_class.from_data(definition)

      result = experiment.valid?

      expect(result).to be_truthy
    end

    {
      "an empty chain" => [],
      "a missing Latin terminator" => [{ "id" => "first", "operation" => "totient",
                                          "parameters" => { "modulus" => 29,
                                                            "prime_start" => 2,
                                                            "skip_sequence" => [] } }],
      "Latin before the end" => [{ "id" => "letters", "operation" => "latin",
                                   "parameters" => {} },
                                  { "id" => "later", "operation" => "latin",
                                    "parameters" => {} }],
      "duplicate step IDs" => [{ "id" => "same", "operation" => "latin",
                                 "parameters" => {} },
                                { "id" => "same", "operation" => "latin",
                                  "parameters" => {} }],
      "a reserved original ID" => [{ "id" => "original", "operation" => "latin",
                                     "parameters" => {} }],
      "a reserved final ID" => [{ "id" => "final", "operation" => "latin",
                                  "parameters" => {} }],
      "an unsafe step ID" => [{ "id" => "../letters", "operation" => "latin",
                                "parameters" => {} }],
      "an unknown operation" => [{ "id" => "other", "operation" => "reverse",
                                   "parameters" => {} }],
      "an unknown step field" => [{ "id" => "letters", "operation" => "latin",
                                    "parameters" => {}, "direction" => "backward" }],
      "missing parameters" => [{ "id" => "letters", "operation" => "latin" }],
      "nonmapping parameters" => [{ "id" => "letters", "operation" => "latin",
                                    "parameters" => [] }],
      "Latin parameters" => [{ "id" => "letters", "operation" => "latin",
                               "parameters" => { "direction" => "backward" } }]
    }.each do |case_name, steps|
      it "rejects #{case_name}" do
        definition = explicit_definition
        definition["steps"] = steps
        experiment = described_class.from_data(definition)

        experiment.valid?

        expect(experiment.errors.attribute_names).to include(:steps)
      end
    end

    {
      "a composite prime start" => { "prime_start" => 4 },
      "a non-29 modulus" => { "modulus" => 31 },
      "duplicate skips" => { "skip_sequence" => [56, 56] },
      "a negative skip" => { "skip_sequence" => [-1] },
      "an out-of-range skip" => { "skip_sequence" => [85] },
      "an unknown parameter" => { "direction" => "add" }
    }.each do |case_name, change|
      it "rejects #{case_name} in an explicit totient step" do
        definition = explicit_definition
        definition.fetch("steps").first.fetch("parameters").merge!(change)
        experiment = described_class.from_data(definition)

        experiment.valid?

        expect(experiment.errors.attribute_names).to include(:steps)
      end
    end

    it "rejects an old draft recipe instead of silently migrating it" do
      definition = explicit_definition
      definition.delete("steps")
      definition["recipe"] = { "id" => "totient-latin",
                               "parameters" => { "modulus" => 29,
                                                 "prime_start" => 2,
                                                 "skip_sequence" => [56] } }
      experiment = described_class.from_data(definition)

      result = experiment.valid?

      expect(result).to be_falsy
    end

    it "accepts a totient step that skips every current GP rune" do
      definition = explicit_definition
      definition.fetch("steps").first.fetch("parameters")["skip_sequence"] = (0...85).to_a
      experiment = described_class.from_data(definition)

      result = experiment.valid?

      expect(result).to be_truthy
    end
  end

  describe "#canonical_configuration" do
    it "normalizes skip ordering in explicit steps" do
      definition = explicit_definition
      definition.fetch("steps").first.fetch("parameters")["skip_sequence"] = [57, 56]
      experiment = described_class.from_data(definition)

      configuration = experiment.canonical_configuration

      expect(configuration.fetch("steps").first.fetch("parameters").fetch("skip_sequence")).to eq([56, 57])
    end

    it "retains step order in identity-bearing configuration" do
      definition = explicit_definition
      definition.fetch("steps").insert(1, {
        "id" => "second", "operation" => "totient",
        "parameters" => { "modulus" => 29, "prime_start" => 3,
                          "skip_sequence" => [] }
      })
      experiment = described_class.from_data(definition)

      configuration = experiment.canonical_configuration

      expect(configuration.fetch("steps").map { |step| step.fetch("id") }).to eq(%w[first second letters])
    end

    it "changes identity-bearing configuration when a step ID changes" do
      first_definition = explicit_definition
      second_definition = explicit_definition
      second_definition.fetch("steps").first["id"] = "renamed"
      first = described_class.from_data(first_definition)
      second = described_class.from_data(second_definition)

      configurations = [first.canonical_configuration, second.canonical_configuration]

      expect(configurations.first).not_to eq(configurations.last)
    end

    it "changes identity-bearing configuration when a layer parameter changes" do
      first_definition = explicit_definition
      second_definition = explicit_definition
      second_definition.fetch("steps").first.fetch("parameters")["prime_start"] = 3
      first = described_class.from_data(first_definition)
      second = described_class.from_data(second_definition)

      configurations = [first.canonical_configuration, second.canonical_configuration]

      expect(configurations.first).not_to eq(configurations.last)
    end
  end

  describe "#persisted_configuration" do
    it "records normalized explicit steps instead of a recipe" do
      definition = explicit_definition
      definition.fetch("steps").first.fetch("parameters")["skip_sequence"] = [57, 56]
      experiment = described_class.from_data(definition)

      configuration = experiment.persisted_configuration

      expect(configuration.fetch("steps").first.fetch("parameters").fetch("skip_sequence")).to eq([56, 57])
    end
  end
end
