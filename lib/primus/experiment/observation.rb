class Primus::Experiment::Observation
  attr_reader :output_bytes, :provenance

  def initialize(output_bytes:, provenance: [])
    @output_bytes = output_bytes.dup.b.freeze
    @provenance = deep_copy(provenance).freeze
  end

  private

  def deep_copy(value)
    case value
    when Hash then value.to_h { |key, item| [deep_copy(key), deep_copy(item)] }.freeze
    when Array then value.map { |item| deep_copy(item) }.freeze
    when String then value.dup.freeze
    else value
    end
  end
end
