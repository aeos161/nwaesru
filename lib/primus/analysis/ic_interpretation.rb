class Primus::Analysis::ICInterpretation
  METHOD_ID = "raw-ic-control-comparison".freeze
  LIMITATION = "Limited comparison: two short solved controls, with different lengths; sample variation can be substantial. This is not a probability of English or evidence of decryption.".freeze
  REPETITION = "IC measures repetition, not word order, readability or correctness of a decryption.".freeze
  TEXT = {
    "above_controls" => "More concentrated than both solved English controls; higher IC does not mean closer to English.",
    "within_controls" => "Within the observed IC range of the solved English controls; compatible with their repetition level, but this does not establish English plaintext.",
    "closer_to_control" => "Closer in IC to a solved English control than to the uniform benchmark, but below the controls' observed range.",
    "closer_to_uniform" => "Closer in IC to the uniform benchmark than to either solved English control; weak support for English-like repetition from IC alone.",
    "equal_distance" => "Equally distant from the nearest English control and uniform benchmark; IC comparison is inconclusive.",
  }.freeze
  UNIFORM = { "gp-runes-v1" => 29, "gp-expanded-latin-v1" => 26 }.freeze

  def initialize(measurement:, references:)
    @measurement = measurement.respond_to?(:to_h) ? measurement.to_h : measurement
    @references = references
  end

  def to_h
    snapshot = base.merge(details)
    owned(snapshot)
  end

  private

  def base
    { "schema_version" => 1, "method_id" => METHOD_ID, "method_version" => 1,
      "representation" => @measurement.fetch("representation"),
      "sample_size" => @measurement.fetch("sample_size"),
      "theoretical_uniform" => uniform_fraction,
      "reference_set_id" => @references && @references["id"],
      "references" => @references ? @references.fetch("controls") : [],
      "provenance_digest" => @references && @references["provenance_digest"],
      "source_description" => @references && @references["source_description"] }
  end

  def details
    return insufficient_sample if @measurement.fetch("sample_size") < 2
    return missing_reference unless compatible_reference?

    code = judgment_code
    { "judgment_code" => code, "text" => "English comparison: #{TEXT.fetch(code)}",
      "limitations" => LIMITATION, "repetition_note" => REPETITION,
      "differences" => differences }
  end

  def insufficient_sample
    { "judgment_code" => "insufficient_sample",
      "text" => "English comparison: insufficient evidence — fewer than two symbols; IC is undefined.",
      "limitations" => nil, "repetition_note" => REPETITION, "differences" => {} }
  end

  def missing_reference
    { "judgment_code" => "no_compatible_reference",
      "text" => "English comparison: insufficient evidence — no compatible English reference is available.",
      "limitations" => nil, "repetition_note" => REPETITION, "differences" => {} }
  end

  def compatible_reference?
    @references && @references["representation"] == @measurement["representation"] &&
      @references["controls"].is_a?(Array) && @references["controls"].size == 2
  end

  def judgment_code
    values = @references.fetch("controls").map { |control| fraction(control) }
    Primus::Analysis::ICJudgment.new(
      measured: measured, controls: values, uniform: fraction(uniform_fraction),
    ).code
  end

  def differences
    @references.fetch("controls").each_with_object({}) do |control, result|
      result[control.fetch("id")] = fraction_hash(measured - fraction(control))
    end
  end

  def measured
    fraction(@measurement.fetch("ic"))
  end

  def fraction(value)
    Rational(value.fetch("numerator"), value.fetch("denominator"))
  end

  def fraction_hash(value)
    { "numerator" => value.numerator, "denominator" => value.denominator }
  end

  def uniform_fraction
    @references && @references["representation"] == @measurement["representation"] ?
      @references["uniform"] : known_uniform
  end

  def known_uniform
    size = UNIFORM[@measurement["representation"]]
    size && { "numerator" => 1, "denominator" => size }
  end

  def owned(value)
    case value
    when Hash then value.each_with_object({}) { |(key, item), copy| copy[owned(key)] = owned(item) }.freeze
    when Array then value.map { |item| owned(item) }.freeze
    else value.dup.freeze
    end
  end
end
