class Primus::Lexer
  attr_reader :data, :tokens, :line, :position

  def initialize(data:, line: 0, position: 0)
    @data = data.split("").to_enum
    @line = line || 0
    @position = position || 0
    @tokens = []
    @current_lexeme = nil
    @current_token = nil
  end

  def tokenize
    until complete? do
      extract_token
      increment_position
      increment_line
    end
  end

  def self.build(page:, starting_line: 0, starting_position: 0)
    new(data: page.data, line: starting_line, position: starting_position)
  end

  protected

  attr_reader :current_token

  def complete?
    tokens.size >= data.count
  end

  def new_line?
    current_token.is_a? Primus::Token::LineBreak
  end

  def delimiter?
    current_token.delimiter?
  end

  def extract_token
    factory = Primus::Token::Factory.new(lexeme: data.next, line: line,
                                         position: position)
    @current_token = factory.create_token
    @tokens << @current_token
  end

  def increment_line
    return unless new_line?
    @line += 1
  end

  def increment_position
    return if delimiter?
    @position += 1
  end
end
