require "digest/sha2"

class Primus::Experiment::Evaluator
  def assess(observation:, expectation:, policy: nil)
    if expectation.is_a?(Hash)
      return assess_hash(observation, expectation, policy)
    end
    actual = observation.output_bytes
    expected = expectation.b
    difference = (0...[actual.bytesize,
                       expected.bytesize].max).detect do |index|
      actual.getbyte(index) != expected.getbyte(index)
    end
    Primus::Experiment::Assessment.new(
      comparison: difference ? "mismatch" : "match",
      first_difference_byte: difference,
      actual_length: actual.bytesize, expected_length: expected.bytesize
    )
  end

  private

  def assess_hash(observation, expectation, policy)
    actual = observation.output_bytes
    observed = Digest::SHA512.hexdigest(actual)
    expected = expectation.fetch("digest")
    hash_check = { "algorithm" => expectation.fetch("algorithm"),
                   "policy" => policy, "expected_digest" => expected,
                   "observed_digest" => observed }
    Primus::Experiment::Assessment.for_hash(
      actual_length: actual.bytesize, hash_check: hash_check,
    )
  end
end
