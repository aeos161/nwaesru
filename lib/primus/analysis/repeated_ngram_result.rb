class Primus::Analysis::RepeatedNgramResult
  def initialize(data)
    @data = owned(data)
  end

  def to_h; @data; end
  def declaration_id; @data.fetch("declaration_id"); end
  def representation; @data.fetch("representation"); end
  def sample_size; @data.fetch("sample_size"); end
  def boundary_policy; @data.fetch("boundary_policy"); end
  def length_groups; @data.fetch("length_groups"); end
  def position_map; @data.fetch("position_map"); end

  private

  def owned(value)
    case value
    when Hash then value.each_with_object({}) { |(key, item), copy| copy[owned(key)] = owned(item) }.freeze
    when Array then value.map { |item| owned(item) }.freeze
    else value.dup.freeze
    end
  end
end
