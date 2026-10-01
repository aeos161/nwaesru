RSpec.describe "Primus::Experiment::Evaluator" do
  describe "#assess" do
    it "reports an exact byte match" do
      observation = Primus::Experiment::Observation.new(
        output_bytes: "parable.lice",
      )
      evaluator = Primus::Experiment::Evaluator.new

      assessment = evaluator.assess(
        observation: observation, expectation: "parable.lice",
      )

      expect(assessment).to have_attributes(comparison: "match",
                                            first_difference_byte: nil)
    end

    it "reports the first differing byte" do
      observation = Primus::Experiment::Observation.new(
        output_bytes: "parable.lice",
      )
      evaluator = Primus::Experiment::Evaluator.new

      assessment = evaluator.assess(
        observation: observation, expectation: "parable.lace",
      )

      expect(assessment).to have_attributes(comparison: "mismatch",
                                            first_difference_byte: 9)
    end

    it "does not change observed output during assessment" do
      observation = Primus::Experiment::Observation.new(
        output_bytes: "parable.lice",
      )
      evaluator = Primus::Experiment::Evaluator.new

      evaluator.assess(observation: observation, expectation: "parable.lace")

      expect(observation.output_bytes).to eq("parable.lice")
    end

    it "reports a trailing byte as a mismatch with both lengths" do
      observation = Primus::Experiment::Observation.new(output_bytes: "abc\n")
      evaluator = Primus::Experiment::Evaluator.new

      assessment = evaluator.assess(
        observation: observation, expectation: "abc",
      )

      expect(assessment).to have_attributes(comparison: "mismatch",
                                            first_difference_byte: 3,
                                            actual_length: 4,
                                            expected_length: 3)
    end
  end
end
