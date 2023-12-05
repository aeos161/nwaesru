class Primus::Lexer::Runic
  attr_accessor :current_lexeme

  attr_reader :data, :tokens, :line, :position

  def initialize(data: "", line: 0, position: 0, track_delimiters: false)
    @data = data.split("")
    @pointer = 0
    @line = line || 0
    @position = position || 0
    @tokens = []
    @track_delimiters = track_delimiters
  end

  def tracking_delimiters?
    true if @track_delimiters
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
    factory = Primus::Token::Runic.new(lexeme: current_lexeme, line: line,
                                       position: position)
    @current_token = factory.create_token
    @tokens << @current_token
    @current_token
  end

  def increment_line
    @line += 1
  end

  def increment_position
    return if @current_token.delimiter? && !tracking_delimiters?
    @position += 1
  end

  protected

  attr_reader :current_token, :pointer

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
