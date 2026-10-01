class Primus::Experiment::Assessment
  attr_reader :comparison, :first_difference_byte, :actual_length,
              :expected_length

  def initialize(comparison:, first_difference_byte:, actual_length:,
                 expected_length:)
    @comparison = comparison
    @first_difference_byte = first_difference_byte
    @actual_length = actual_length
    @expected_length = expected_length
  end

  def to_h
    { "comparison" => comparison,
      "first_difference_byte" => first_difference_byte,
      "actual_length" => actual_length, "expected_length" => expected_length }
  end
end
