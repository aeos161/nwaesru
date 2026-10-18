RSpec.describe Primus::Experiment::Composition do
  describe "#experiment" do
    it "expands the Latin shortcut into a terminal explicit step" do
      options = { input: "page-57", recipe: "latin",
                  expect_text: "experiments/expected/page-57-latin.txt" }
      composition = described_class.new(options)

      experiment = composition.experiment
      steps = experiment.canonical_configuration.fetch("steps")
      operations = steps.map { |step| step.slice("operation", "parameters") }

      expect(operations).to eq([
        { "operation" => "latin", "parameters" => {} }
      ])
    end

    it "expands totient-Latin with page-independent defaults" do
      options = { input: "page-56", recipe: "totient-latin",
                  expect_text: "experiments/expected/page-56-totient-latin.txt" }
      composition = described_class.new(options)

      experiment = composition.experiment
      steps = experiment.canonical_configuration.fetch("steps")
      operations = steps.map { |step| step.slice("operation", "parameters") }

      expect(operations).to eq([
        { "operation" => "totient",
          "parameters" => { "modulus" => 29, "prime_start" => 2,
                            "skip_sequence" => [] } },
        { "operation" => "latin", "parameters" => {} }
      ])
    end

    it "retains explicit shortcut parameters in the expanded totient step" do
      options = { input: "page-56", recipe: "totient-latin",
                  recipe_param: ["prime_start=3", "skip_sequence=[57,56]"],
                  expect_text: "experiments/expected/page-56-totient-latin.txt" }
      composition = described_class.new(options)

      experiment = composition.experiment
      steps = experiment.canonical_configuration.fetch("steps")
      parameters = steps.first.fetch("parameters")

      expect(parameters).to eq(
        "modulus" => 29, "prime_start" => 3, "skip_sequence" => [56, 57]
      )
    end
  end
end
