class Primus::Lexer::Latin
  attr_accessor :current_lexeme

  attr_reader :data, :tokens, :line, :position

  def initialize(data: "", line: 0, position: 0)
    @data = data.split("").map(&:downcase)
    @pointer = 0
    @line = line || 0
    @position = position || 0
    @tokens = []
  end

  def complete?
    pointer > data.size - 1
  end

  def extract_lexeme
    lexeme = next_lexeme
    increment_pointer(lexeme.size)
    @current_lexeme = lexeme
  end

  def create_token
    factory = Primus::Token::English.new(lexeme: current_lexeme, line: line,
                                         position: position)
    token = factory.create_token
    @tokens << token
    token
  end

  def increment_line
    @line += 1
  end

  def increment_position
    @position += 1
  end

  protected

  attr_reader :current_token, :pointer

  def valid_n_gram?(lexeme)
    return true if Primus::Token::English::TRI_GRAM.include? lexeme
    return true if Primus::Token::English::BI_GRAM.include? lexeme
    lexeme.size == 1
  end

  def next_lexeme(iteration = 2)
    lexeme = data[pointer..pointer + iteration].join
    if valid_n_gram? lexeme
      lexeme
    else
      next_lexeme(iteration - 1)
    end
  end

  def increment_pointer(n)
    @pointer += n
  end
end
