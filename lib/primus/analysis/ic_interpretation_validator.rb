class Primus::Analysis::ICInterpretationValidator
  Error = Primus::Analysis::RecordValidator::Error
  CODES = %w[above_controls within_controls closer_to_control closer_to_uniform equal_distance].freeze

  def initialize(measurement)
    @measurement = measurement
    @snapshot = measurement.fetch("interpretation")
  end

  def validate!
    fail_invalid unless @snapshot.is_a?(Hash)
    fail_invalid unless @snapshot.values_at("schema_version", "method_id", "method_version") ==
      [1, Primus::Analysis::ICInterpretation::METHOD_ID, 1]
    fail_invalid unless @snapshot.values_at("representation", "sample_size") ==
      @measurement.values_at("representation", "sample_size")
    validate_uniform!
    validate_status!
    validate_references!
    nil
  end

  private

  def validate_uniform!
    uniform = @snapshot["theoretical_uniform"]
    size = Primus::Analysis::ICInterpretation::UNIFORM[@measurement["representation"]]
    fail_invalid unless size && uniform == { "numerator" => 1, "denominator" => size }
  end

  def validate_status!
    ic = @measurement.fetch("ic")
    size = @measurement.fetch("sample_size")
    fail_invalid unless ic["denominator"] == size * (size - 1)
    fail_invalid unless ic["numerator"].is_a?(Integer)
    if size < 2
      fail_invalid unless ic["status"] == "insufficient_sample" &&
        @snapshot["judgment_code"] == "insufficient_sample"
    else
      fail_invalid unless ic["status"] == "computed" &&
        CODES.include?(@snapshot["judgment_code"])
    end
    fail_invalid unless @snapshot["text"].is_a?(String) &&
      @snapshot["text"].start_with?("English comparison:")
  end

  def validate_references!
    fail_invalid unless @snapshot["reference_set_id"] == "solved-gp-english-controls-v1"
    fail_invalid unless @snapshot["provenance_digest"].to_s.match?(/\A[0-9a-f]{64}\z/)
    fail_invalid unless @snapshot["source_description"].is_a?(String) &&
      !@snapshot["source_description"].empty?
    controls = @snapshot["references"]
    fail_invalid unless controls.is_a?(Array) && controls.size == 2 &&
      controls.map { |control| control["id"] } == %w[page-56 page-57]
    controls.each { |control| validate_control!(control) }
    validate_differences!(controls)
  end

  def validate_control!(control)
    size = control["sample_size"]
    fail_invalid unless size.is_a?(Integer) && size >= 2
    fail_invalid unless control["denominator"] == size * (size - 1)
    fail_invalid unless control["numerator"].is_a?(Integer) &&
      control["numerator"].between?(0, control["denominator"])
  end

  def validate_differences!(controls)
    differences = @snapshot["differences"]
    fail_invalid unless differences.is_a?(Hash)
    if @measurement["sample_size"] < 2
      fail_invalid unless differences.empty?
      return
    end
    fail_invalid unless differences.keys.sort == controls.map { |control| control["id"] }.sort
    measured = rational(@measurement.fetch("ic"))
    controls.each do |control|
      difference = differences.fetch(control.fetch("id"))
      fail_invalid unless valid_fraction?(difference)
      fail_invalid unless rational(difference) == measured - rational(control)
    end
  end

  def valid_fraction?(value)
    value.is_a?(Hash) && value["numerator"].is_a?(Integer) &&
      value["denominator"].is_a?(Integer) && value["denominator"].positive?
  end

  def rational(value)
    Rational(value.fetch("numerator"), value.fetch("denominator"))
  end

  def fail_invalid
    raise Error, "malformed IC interpretation"
  end
end
