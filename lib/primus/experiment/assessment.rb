class Primus::Experiment::Assessment
  attr_reader :comparison, :first_difference_byte, :actual_length,
              :expected_length

  def initialize(comparison:, first_difference_byte:, actual_length:,
                 expected_length:)
    @comparison = comparison
    @first_difference_byte = first_difference_byte
    @actual_length = actual_length
    @expected_length = expected_length
    @hash_check = nil
  end

  def self.for_hash(actual_length:, hash_check:)
    expected = hash_check["expected_digest"]
    observed = hash_check["observed_digest"]
    comparison = expected == observed ? "match" : "mismatch"
    assessment = new(comparison: comparison,
                     first_difference_byte: nil, actual_length: actual_length,
                     expected_length: nil)
    assessment.restore_hash_check(hash_check)
  end

  def restore_hash_check(hash_check)
    @hash_check = hash_check
    self
  end

  def to_h
    data = { "comparison" => comparison,
             "first_difference_byte" => first_difference_byte,
             "actual_length" => actual_length,
             "expected_length" => expected_length }
    data["hash_check"] = @hash_check if @hash_check
    data
  end
end
