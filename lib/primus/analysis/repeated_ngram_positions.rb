class Primus::Analysis::RepeatedNgramPositions
  Error = Primus::Analysis::RecordValidator::Error
  SOURCE_KEYS = %w[rune_ordinal page_number occurrence rune_index byte_start byte_end
                   character_start character_end line column].freeze

  def initialize(entry)
    @entry = entry
    @positions = entry.fetch("result").fetch("position_map")
  end

  def validate!
    size = @entry.fetch("result").fetch("sample_size")
    raise Error, "invalid position map" unless @positions.is_a?(Array) && @positions.size == size &&
      @entry.fetch("profile").fetch("sample_size") == size
    @positions.each { |position| position!(position) }
    ordinal_order!
  end

  private

  def position!(position)
    raise Error, "missing source coordinates" unless position.is_a?(Hash) &&
      SOURCE_KEYS.all? { |key| coordinate?(key, position[key]) }
    return if @entry["representation"] == "gp-runes-v1" &&
      !position.key?("expansion_offset") && !position.key?("expansion_length")
    raise Error, "invalid expansion coordinates" unless @entry["representation"] == "gp-expanded-latin-v1" &&
      position["expansion_offset"].instance_of?(Integer) && position["expansion_length"].instance_of?(Integer) &&
      position["expansion_length"].positive? && position["expansion_offset"].between?(0, position["expansion_length"] - 1)
  end

  def coordinate?(key, value)
    value.instance_of?(Integer) || (key == "page_number" && value == "warning")
  end

  def ordinal_order!
    groups = @positions.chunk { |item| item.fetch("rune_ordinal") }.to_a
    raise Error, "rune ordinal order mismatch" unless groups.map(&:first) == (0...groups.size).to_a
    groups.each do |_ordinal, positions|
      offsets = positions.map { |item| item["expansion_offset"] }
      next if @entry["representation"] == "gp-runes-v1" && positions.size == 1
      length = positions.size
      raise Error, "expansion order mismatch" unless offsets == (0...length).to_a &&
        positions.all? { |item| item["expansion_length"] == length }
    end
  end
end
