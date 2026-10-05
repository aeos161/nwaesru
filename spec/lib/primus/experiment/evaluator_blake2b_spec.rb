require "openssl"

RSpec.describe Primus::Experiment::Evaluator do
  def blake_expectation(digest)
    { "kind" => "hash", "algorithm" => "blake2b512", "digest" => digest,
      "provenance" => "BLAKE2 official KAT" }
  end

  def assess_blake(bytes, digest)
    observation = Primus::Experiment::Observation.new(output_bytes: bytes)
    Primus::Experiment::Evaluator.new.assess(
      observation: observation, expectation: blake_expectation(digest),
      policy: "gp-latin-compatibility-v1"
    )
  end

  describe "#assess" do
    it "matches the official unkeyed empty-input BLAKE2b-512 vector" do
      digest = "786a02f742015903c6c6fd852552d272" \
               "912f4740e15847618a86e217f71f5419" \
               "d25e1031afee585313896444934eb04b" \
               "903a685b1448b755d56f701afe9be2ce"

      assessment = assess_blake("", digest)

      expect(assessment.comparison).to eq("match")
    end

    it "matches the official 255-byte unkeyed multi-block vector" do
      # BLAKE2 KAT blake2-kat.json, unkeyed blake2b entry with input 00..fe.
      digest = "5b21c5fd8868367612474fa2e70e9cfa" \
               "2201ffeee8fafab5797ad58fefa17c9" \
               "b5b107da4a3db6320baaf2c8617d5a5" \
               "1df914ae88da3867c2d41f0cc14fa67928"
      bytes = (0..254).to_a.pack("C*")

      assessment = assess_blake(bytes, digest)

      expect(assessment.comparison).to eq("match")
    end

    it "retains four-key digest evidence and the binary input length" do
      digest = "786a02f742015903c6c6fd852552d272" \
               "912f4740e15847618a86e217f71f5419" \
               "d25e1031afee585313896444934eb04b" \
               "903a685b1448b755d56f701afe9be2ce"

      assessment = assess_blake("", digest)

      expect(assessment.to_h).to eq(
        "comparison" => "match", "first_difference_byte" => nil,
        "actual_length" => 0, "expected_length" => nil,
        "hash_check" => { "algorithm" => "blake2b512",
                          "policy" => "gp-latin-compatibility-v1",
                          "expected_digest" => digest,
                          "observed_digest" => digest }
      )
    end

    it "detects a terminal newline as a byte mismatch" do
      digest = "786a02f742015903c6c6fd852552d272" \
               "912f4740e15847618a86e217f71f5419" \
               "d25e1031afee585313896444934eb04b" \
               "903a685b1448b755d56f701afe9be2ce"

      assessment = assess_blake("\n", digest)

      expect(assessment.comparison).to eq("mismatch")
    end

    it "does not mutate the caller's input while hashing" do
      bytes = "\x00\xff\n".b
      observation = Primus::Experiment::Observation.new(output_bytes: bytes)
      digest = "0" * 128

      Primus::Experiment::Evaluator.new.assess(
        observation: observation, expectation: blake_expectation(digest),
        policy: "gp-latin-compatibility-v1"
      )

      expect(bytes).to eq("\x00\xff\n".b)
    end

    it "rejects an unsupported algorithm instead of falling back to SHA-512" do
      observation = Primus::Experiment::Observation.new(output_bytes: "abc")
      expectation = blake_expectation("0" * 128)
      expectation["algorithm"] = "sha256"

      action = -> {
        Primus::Experiment::Evaluator.new.assess(
          observation: observation, expectation: expectation,
          policy: "gp-latin-compatibility-v1"
        )
      }

      expect(action).to raise_error(StandardError, /sha256/)
    end

    it "raises a backend error when OpenSSL cannot construct BLAKE2b-512" do
      observation = Primus::Experiment::Observation.new(output_bytes: "abc")
      expectation = blake_expectation("0" * 128)
      allow(OpenSSL::Digest).to receive(:new).with("BLAKE2b512").
        and_raise(OpenSSL::Digest::DigestError,
                  "digest unavailable")

      action = -> {
        Primus::Experiment::Evaluator.new.assess(
          observation: observation, expectation: expectation,
          policy: "gp-latin-compatibility-v1"
        )
      }

      expect(action).to raise_error(StandardError,
                                    /blake2b512.*digest unavailable/i)
    end
  end
end
