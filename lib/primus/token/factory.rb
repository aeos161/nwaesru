class Primus::Token::Factory
  def initialize(lexeme:, line: 0, position: 0)
    @lexeme = lexeme
    @line = line
    @position = position
  end

  def create_token
    if rune? || character?
      create_character_token
    else
      create_non_character_token
    end
  end

  private

  attr_reader :lexeme, :line, :position

  def rune?
    (5792..5872).cover? lexeme.ord
  end

  def character?
    /\w/.match? lexeme
  end

  def create_character_token
    Primus::Token::Character.new(lexeme: lexeme, location: location)
  end

  def create_non_character_token
    case lexeme
    when Primus::Token::WordDelimiter::IDENTIFIER
      Primus::Token::WordDelimiter.new(location: no_location)
    when Primus::Token::WordDelimiter::LITERAL
      Primus::Token::WordDelimiter.new(location: no_location)
    when Primus::Token::SentenceDelimiter::IDENTIFIER
      Primus::Token::SentenceDelimiter.new(location: no_location)
    when Primus::Token::LineBreak::IDENTIFIER
      Primus::Token::LineBreak.new(location: no_location)
    else
      fail "Unknown lexeme: #{lexeme}"
    end
  end

  def location
    Primus::Token::Location.new(line: line, position: position)
  end

  def no_location
    Primus::Token::Location.new(line: nil, position: nil)
  end
end
