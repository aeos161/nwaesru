class Primus::Token::Location
  attr_reader :line, :position, :length

  def initialize(line:, position:, length: 1)
    @line = line
    @position = position
    @length = length
  end

  def ==(other)
    other.is_a?(Primus::Token::Location) &&
      line == other.line && position == other.position && length == other.length
  end

  def -(other)
    position - other.position
  end
end
