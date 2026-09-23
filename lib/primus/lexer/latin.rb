class Primus::Lexer::Latin
  attr_accessor :current_lexeme

  attr_reader :data, :tokens, :line, :position, :raw_source

  def initialize(data: "", line: 0, position: 0, track_delimiters: false)
    @raw_source = data
    @data = data.chars.map(&:downcase)
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
    factory = Primus::Token::English.new(lexeme: current_lexeme, line: line,
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

  def valid_n_gram?(lexeme)
    return true if Primus::Token::English::TRI_GRAM.include? lexeme
    return true if Primus::Token::English::BI_GRAM.include? lexeme
    lexeme.size == 1
  end

  def next_lexeme(iteration = 2)
    lexeme = data[pointer..(pointer + iteration)].join
    if valid_n_gram? lexeme
      lexeme
    else
      next_lexeme(iteration - 1)
    end
  end

  def increment_pointer(amount)
    @pointer += amount
  end
end
