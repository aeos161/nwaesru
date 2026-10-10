class Primus::Analysis::Result
  attr_reader :frequencies

  def initialize(data)
    @data = deep_freeze(data)
    @frequencies = @data.fetch("frequencies")
  end

  def to_h
    @data
  end

  private

  def deep_freeze(value)
    value.each { |key, item| deep_freeze(key); deep_freeze(item) } if value.is_a?(Hash)
    value.each { |item| deep_freeze(item) } if value.is_a?(Array)
    value.freeze
  end
end
