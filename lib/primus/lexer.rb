class Primus::Lexer
  attr_reader :data, :tokens, :line, :position

  def initialize(data: "", line: 0, position: 0)
    @data = standardize(data).split("")
    @pointer = 0
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

  attr_reader :current_token, :pointer

  def complete?
    pointer > data.size - 1
  end

  def new_line?
    current_token.is_a? Primus::Token::LineBreak
  end

  def delimiter?
    current_token.delimiter?
  end

  def bigraph?(lexeme)
    bigraphs.include? lexeme
  end

  def standardize(text)
    text = text.downcase
    replaceable_tokens.each do |alt, replacement|
      text = text.gsub(alt.to_s, replacement.to_s)
    end
    text
  end

  def extract_token
    factory = Primus::Token::Factory.new(lexeme: next_lexeme, line: line,
                                         position: position)
    @current_token = factory.create_token
    @tokens << @current_token
  end

  def next_lexeme
    lexeme = data[pointer..(pointer + 1)].join
    unless bigraph? lexeme
      lexeme = data[pointer]
    end
    increment_pointer(lexeme.size)
    lexeme
  end

  def increment_line
    return unless new_line?
    @line += 1
  end

  def increment_position
    return if delimiter?
    @position += 1
  end

  def increment_pointer(n)
    @pointer += n
  end

  def replaceable_tokens
    { ing: :ng, ia: :io, z: :s, k: :c, v: :u, qu: :cw }
  end

  def bigraphs
    ["th", "eo", "ng", "oe", "ae", "io", "ea"]
  end
end
