class Primus::Transcription::SourceLocation
  ATTRIBUTES = [:page_number, :occurrence, :byte_start, :byte_end,
                :character_start, :character_end, :line, :column,
                :rune_index].freeze

  attr_reader(*ATTRIBUTES)

  def initialize(**attributes)
    ATTRIBUTES.each { |name|
      instance_variable_set("@#{name}", attributes[name])
    }
  end

  def ==(other)
    other.is_a?(self.class) &&
      ATTRIBUTES.all? { |name| public_send(name) == other.public_send(name) }
  end
end
