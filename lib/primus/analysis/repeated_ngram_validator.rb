class Primus::Analysis::RepeatedNgramValidator
  Error = Primus::Analysis::RecordValidator::Error
  SOURCE_KEYS = %w[rune_ordinal page_number occurrence rune_index byte_start byte_end
                   character_start character_end line column].freeze

  def initialize(entry)
    @entry = entry
    @result = entry.fetch("result")
    @profile = entry.fetch("profile")
    @parameters = entry.fetch("parameters")
  end

  def validate!
    identity!
    positions!
    groups!
    nil
  rescue KeyError, NoMethodError, TypeError => error
    raise Error, "malformed repeated n-gram measurement: #{error.message}"
  end

  private

  def identity!
    raise Error, "measurement representation mismatch" unless @result["representation"] == @entry["representation"]
    raise Error, "measurement declaration mismatch" unless @result["declaration_id"] == @entry["declaration_id"]
    raise Error, "boundary policy mismatch" unless @result["boundary_policy"] == "continuous-gp-v1" &&
      @parameters["boundary_policy"] == @result["boundary_policy"]
    lengths = @parameters["lengths"]
    raise Error, "invalid lengths" unless lengths.is_a?(Array) && !lengths.empty? &&
      lengths.all? { |n| n.instance_of?(Integer) && [2, 3].include?(n) } && lengths == lengths.uniq.sort
    raise Error, "invalid sample size" unless @result["sample_size"].instance_of?(Integer) && @result["sample_size"] >= 0
    alphabet = @entry["representation"] == "gp-runes-v1" ? Primus::Analysis::RUNES : Primus::Analysis::LATIN
    raise Error, "invalid alphabet" unless @profile["alphabet"] == alphabet
    if @entry["representation"] == "gp-expanded-latin-v1"
      raise Error, "invalid expansion map" unless @profile["expansion_map"] == Primus::Analysis::MAP
    end
  end

  def positions!
    positions = @result["position_map"]
    raise Error, "invalid position map" unless positions.is_a?(Array) && positions.size == @result["sample_size"] &&
      @profile["sample_size"] == positions.size
    positions.each { |position| position! (position) }
  end

  def position!(position)
    raise Error, "missing source coordinates" unless position.is_a?(Hash) &&
      SOURCE_KEYS.all? { |key| position[key].instance_of?(Integer) || (key == "page_number" && position[key] == "warning") }
    return if @entry["representation"] == "gp-runes-v1" &&
      !position.key?("expansion_offset") && !position.key?("expansion_length")
    raise Error, "invalid expansion coordinates" unless @entry["representation"] == "gp-expanded-latin-v1" &&
      position["expansion_offset"].instance_of?(Integer) && position["expansion_length"].instance_of?(Integer) &&
      position["expansion_length"].positive? && position["expansion_offset"].between?(0, position["expansion_length"] - 1)
  end

  def groups!
    groups = @result["length_groups"]
    raise Error, "invalid length groups" unless groups.is_a?(Array) &&
      groups.map { |group| group["length"] } == @parameters["lengths"]
    groups.each { |group| group!(group) }
  end

  def group!(group)
    length = group.fetch("length")
    candidates = [@result["sample_size"] - length + 1, 0].max
    patterns = group.fetch("patterns")
    raise Error, "candidate count mismatch" unless group["candidate_count"] == candidates
    raise Error, "group status mismatch" unless group["status"] == (candidates.zero? ? "insufficient_sample" : "computed")
    raise Error, "invalid patterns" unless patterns.is_a?(Array)
    patterns.each { |pattern| pattern!(pattern, length) }
    keys = patterns.map { |item| item.fetch("symbols").map { |symbol| alphabet.index(symbol) } }
    raise Error, "pattern order mismatch" unless keys == keys.uniq.sort
    raise Error, "repeated aggregate mismatch" unless group["repeated_pattern_count"] == patterns.size &&
      group["repeated_occurrence_count"] == patterns.sum { |item| item.fetch("count") }
    distinct = group["distinct_pattern_count"]
    raise Error, "distinct aggregate mismatch" unless distinct.instance_of?(Integer) &&
      distinct.between?(patterns.size, candidates - patterns.sum { |item| item.fetch("count") } + patterns.size)
  end

  def pattern!(pattern, length)
    symbols = pattern.fetch("symbols")
    starts = pattern.fetch("occurrences")
    raise Error, "invalid pattern" unless symbols.is_a?(Array) && symbols.size == length &&
      symbols.all? { |symbol| alphabet.include?(symbol) } && starts.is_a?(Array) && starts.size >= 2
    indices = starts.map { |item| item.fetch("start_index") }
    raise Error, "invalid occurrence span" unless starts.each_with_index.all? { |item, index|
      indices[index].instance_of?(Integer) && indices[index].between?(0, @result["sample_size"] - length) &&
        item["end_index"] == indices[index] + length }
    raise Error, "occurrence order mismatch" unless indices == indices.uniq.sort
    raise Error, "pattern count mismatch" unless pattern["count"] == starts.size
    raise Error, "gap mismatch" unless pattern["gaps"] == indices.each_cons(2).map { |a, b| b - a }
  end

  def alphabet
    @entry["representation"] == "gp-runes-v1" ? Primus::Analysis::RUNES : Primus::Analysis::LATIN
  end
end
