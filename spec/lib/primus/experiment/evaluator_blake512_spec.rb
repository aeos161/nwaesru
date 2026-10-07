RSpec.describe Primus::Experiment::Evaluator do
  def blake512_expectation(digest)
    { "kind" => "hash", "algorithm" => "blake512", "digest" => digest,
      "provenance" => "@noble/hashes blake1 1.8.0 verified abc vector" }
  end

  describe "#assess" do
    it "hashes the exact page-57 bytes to the independent oracle" do
      bytes = File.binread("experiments/expected/page-57-latin.txt")
      observation = Primus::Experiment::Observation.new(output_bytes: bytes)
      experiment = Primus::Experiment.load(
        path: "spec/fixtures/experiments/page_57_blake512_valid.yml",
      )
      digest = "999826f07ba989ae4d25d57acfc5fb2b" \
               "16102289d5bbc0a427cf2997a8ff89ac" \
               "84bc545e6a8e06108794975fd88cb6dc" \
               "7c7c64f967d4248b6d2a73cbb67cb3e7"

      assessment = Primus::Experiment::Evaluator.new.assess(
        observation: observation, expectation: experiment.expectation,
        policy: "gp-latin-compatibility-v1"
      )
      hash_check = assessment.to_h.fetch("hash_check")

      expect(hash_check.fetch("observed_digest")).to eq(digest)
    end

    it "matches the original BLAKE-512 abc vector" do
      digest = "14266c7c704a3b58fb421ee69fd005fc" \
               "c6eeff742136be67435df995b7c986e7" \
               "cbde4dbde135e7689c354d2bc5b8d260" \
               "536c554b4f84c118e61efc576fed7cd3"
      observation = Primus::Experiment::Observation.new(output_bytes: "abc")

      assessment = Primus::Experiment::Evaluator.new.assess(
        observation: observation, expectation: blake512_expectation(digest),
        policy: "gp-latin-compatibility-v1"
      )

      expect(assessment.comparison).to eq("match")
    end

    it "detects one additional output byte as a mismatch" do
      digest = "14266c7c704a3b58fb421ee69fd005fc" \
               "c6eeff742136be67435df995b7c986e7" \
               "cbde4dbde135e7689c354d2bc5b8d260" \
               "536c554b4f84c118e61efc576fed7cd3"
      observation = Primus::Experiment::Observation.new(output_bytes: "abc\n")

      assessment = Primus::Experiment::Evaluator.new.assess(
        observation: observation, expectation: blake512_expectation(digest),
        policy: "gp-latin-compatibility-v1"
      )

      expect(assessment.comparison).to eq("mismatch")
    end

    it "preserves the four hash-check fields" do
      digest = "14266c7c704a3b58fb421ee69fd005fc" \
               "c6eeff742136be67435df995b7c986e7" \
               "cbde4dbde135e7689c354d2bc5b8d260" \
               "536c554b4f84c118e61efc576fed7cd3"
      observation = Primus::Experiment::Observation.new(output_bytes: "abc")

      assessment = Primus::Experiment::Evaluator.new.assess(
        observation: observation, expectation: blake512_expectation(digest),
        policy: "gp-latin-compatibility-v1"
      )

      expect(assessment.to_h.fetch("hash_check")).to eq(
        "algorithm" => "blake512", "policy" => "gp-latin-compatibility-v1",
        "expected_digest" => digest, "observed_digest" => digest
      )
    end

    it "does not mutate the original binary input" do
      bytes = "\x00\xff\x80\n".b
      observation = Primus::Experiment::Observation.new(output_bytes: bytes)

      Primus::Experiment::Evaluator.new.assess(
        observation: observation, expectation: blake512_expectation("0" * 128),
        policy: "gp-latin-compatibility-v1"
      )

      expect(bytes).to eq("\x00\xff\x80\n".b)
    end
  end
end
