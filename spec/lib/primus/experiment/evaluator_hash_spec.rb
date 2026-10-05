RSpec.describe Primus::Experiment::Evaluator do
  def hash_expectation(digest)
    { "kind" => "hash", "algorithm" => "sha512", "digest" => digest,
      "provenance" => "independent test vector" }
  end

  describe "#assess" do
    it "matches the independently published SHA-512 abc vector" do
      digest = "ddaf35a193617abacc417349ae204131" \
               "12e6fa4e89a97ea20a9eeee64b55d39a" \
               "2192992a274fc1a836ba3c23a3feebbd" \
               "454d4423643ce80e2a9ac94fa54ca49f"
      observation = Primus::Experiment::Observation.new(output_bytes: "abc")
      evaluator = Primus::Experiment::Evaluator.new

      assessment = evaluator.assess(
        observation: observation, expectation: hash_expectation(digest),
        policy: "gp-latin-compatibility-v1"
      )

      expect(assessment.comparison).to eq("match")
    end

    it "retains the scientific digest evidence and exact byte length" do
      digest = "ddaf35a193617abacc417349ae204131" \
               "12e6fa4e89a97ea20a9eeee64b55d39a" \
               "2192992a274fc1a836ba3c23a3feebbd" \
               "454d4423643ce80e2a9ac94fa54ca49f"
      observation = Primus::Experiment::Observation.new(output_bytes: "abc")
      evaluator = Primus::Experiment::Evaluator.new

      assessment = evaluator.assess(
        observation: observation, expectation: hash_expectation(digest),
        policy: "gp-latin-compatibility-v1"
      )

      expect(assessment.to_h).to eq(
        "comparison" => "match", "first_difference_byte" => nil,
        "actual_length" => 3, "expected_length" => nil,
        "hash_check" => { "algorithm" => "sha512",
                          "policy" => "gp-latin-compatibility-v1",
                          "expected_digest" => digest,
                          "observed_digest" => digest }
      )
    end

    it "reports a one-byte output change as a scientific mismatch" do
      digest = "ddaf35a193617abacc417349ae204131" \
               "12e6fa4e89a97ea20a9eeee64b55d39a" \
               "2192992a274fc1a836ba3c23a3feebbd" \
               "454d4423643ce80e2a9ac94fa54ca49f"
      observation = Primus::Experiment::Observation.new(output_bytes: "abd")
      evaluator = Primus::Experiment::Evaluator.new

      assessment = evaluator.assess(
        observation: observation, expectation: hash_expectation(digest),
        policy: "gp-latin-compatibility-v1"
      )

      expect(assessment.comparison).to eq("mismatch")
    end

    it "treats a trailing newline as a different byte sequence" do
      digest = "ddaf35a193617abacc417349ae204131" \
               "12e6fa4e89a97ea20a9eeee64b55d39a" \
               "2192992a274fc1a836ba3c23a3feebbd" \
               "454d4423643ce80e2a9ac94fa54ca49f"
      observation = Primus::Experiment::Observation.new(output_bytes: "abc\n")
      evaluator = Primus::Experiment::Evaluator.new

      assessment = evaluator.assess(
        observation: observation, expectation: hash_expectation(digest),
        policy: "gp-latin-compatibility-v1"
      )

      expect(assessment.comparison).to eq("mismatch")
    end

    it "does not change the observation while hashing" do
      observation = Primus::Experiment::Observation.new(output_bytes: "abc\r\n")
      evaluator = Primus::Experiment::Evaluator.new
      expectation = hash_expectation("0" * 128)

      evaluator.assess(observation: observation, expectation: expectation,
                       policy: "gp-latin-compatibility-v1")

      expect(observation.output_bytes).to eq("abc\r\n")
    end

    it "hashes empty bytes rather than treating them as absent" do
      digest = "cf83e1357eefb8bdf1542850d66d8007" \
               "d620e4050b5715dc83f4a921d36ce9ce" \
               "47d0d13c5d85f2b0ff8318d2877eec2f" \
               "63b931bd47417a81a538327af927da3e"
      observation = Primus::Experiment::Observation.new(output_bytes: "")
      evaluator = Primus::Experiment::Evaluator.new

      assessment = evaluator.assess(
        observation: observation, expectation: hash_expectation(digest),
        policy: "gp-latin-compatibility-v1"
      )

      expect(assessment.comparison).to eq("match")
    end
  end
end
