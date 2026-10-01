class Primus::Experiment::Evaluator
  def assess(observation:, expectation:)
    actual = observation.output_bytes.b
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
end
