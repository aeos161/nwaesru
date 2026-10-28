class Primus::Analysis::RepeatedNgrams
  def initialize(symbols:, alphabet:, position_map:, lengths:, boundary_policy:,
                 declaration_id:, representation:)
    @symbols, @alphabet, @position_map = symbols, alphabet, position_map
    @lengths, @boundary_policy = lengths, boundary_policy
    @declaration_id, @representation = declaration_id, representation
  end

  def to_result
    raise ArgumentError, "symbol outside alphabet" unless (@symbols - @alphabet).empty?
    Primus::Analysis::RepeatedNgramResult.new(
      "declaration_id" => @declaration_id, "representation" => @representation,
      "sample_size" => @symbols.size, "boundary_policy" => @boundary_policy,
      "position_map" => @position_map,
      "length_groups" => @lengths.map { |length| group(length) },
    )
  end

  private

  def group(length)
    candidates = [@symbols.size - length + 1, 0].max
    starts = (0...candidates).each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |index, hash|
      hash[@symbols.slice(index, length)] << index
    end
    patterns = starts.filter_map { |symbols, indices| pattern(symbols, indices) if indices.size > 1 }
    patterns.sort_by! { |item| item.fetch("symbols").map { |symbol| @alphabet.index(symbol) } }
    { "length" => length, "status" => candidates.zero? ? "insufficient_sample" : "computed",
      "candidate_count" => candidates, "distinct_pattern_count" => starts.size,
      "repeated_pattern_count" => patterns.size,
      "repeated_occurrence_count" => patterns.sum { |item| item.fetch("count") },
      "patterns" => patterns }
  end

  def pattern(symbols, indices)
    { "symbols" => symbols, "count" => indices.size,
      "occurrences" => indices.map { |index| { "start_index" => index,
                                                "end_index" => index + symbols.size } },
      "gaps" => indices.each_cons(2).map { |left, right| right - left } }
  end
end
