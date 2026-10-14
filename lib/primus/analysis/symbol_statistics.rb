class Primus::Analysis::SymbolStatistics
  def initialize(symbols:, alphabet:, declaration_id:, representation:)
    @symbols, @alphabet = symbols, alphabet
    @declaration_id, @representation = declaration_id, representation
  end

  def to_result
    counts = @symbols.tally
    raise ArgumentError, "symbol outside alphabet" unless (counts.keys - @alphabet).empty?
    Primus::Analysis::Result.new(
      "declaration_id" => @declaration_id, "representation" => @representation,
      "alphabet_size" => @alphabet.size, "sample_size" => @symbols.size,
      "distinct_count" => counts.size,
      "frequencies" => frequencies(counts), "ic" => coincidence(counts),
    )
  end

  private

  def frequencies(counts)
    @alphabet.each_with_index.map do |symbol, index|
      count = counts.fetch(symbol, 0)
      { "index" => index, "symbol" => symbol, "count" => count,
        "relative_frequency" => @symbols.empty? ? nil : count.fdiv(@symbols.size) }
    end
  end

  def coincidence(counts)
    size = @symbols.size
    numerator = counts.values.sum { |count| count * (count - 1) }
    denominator = size * (size - 1)
    { "status" => size < 2 ? "insufficient_sample" : "computed",
      "normalization" => "none", "numerator" => numerator,
      "denominator" => denominator,
      "value" => size < 2 ? nil : numerator.fdiv(denominator) }
  end
end
