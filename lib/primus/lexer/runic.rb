class Primus::Lexer::Runic
  attr_reader :data, :tokens, :line, :position

  def initialize(data: "", line: 0, position: 0)
    @data = data.split("")
    @pointer = 0
    @line = line || 0
    @position = position || 0
    @tokens = []
    @current_lexeme = nil
    @current_token = nil
  end

  def tokenize
    extract_token

  end

  protected

  attr_reader :current_token, :pointer

  def extract_token
    lexeme = next_lexeme
    increment_pointer(lexeme.size)
    factory = Primus::Token::Runic.new(lexeme: lexeme, line: line,
                                       position: position)
    @current_token = factory.create_token
    @tokens << @current_token
  end

  def next_lexeme
    lexeme = data[pointer]
    if Primus::Token::Runic::BI_GRAM.include? lexeme
      lexeme = data[pointer..(pointer + 1)].join
    end
    lexeme
  end

  def increment_pointer(n)
    @pointer += n
  end
end
