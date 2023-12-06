class Primus::Token::Runic
  BI_GRAM = ["᛫", "᛬"].freeze
  PUNCTUATION = ["᛭", "᛫᛬", "᛬᛫", ".", ",", "'"].freeze
  QUOTATION_MARK = ["\""].freeze
  WORD_DELIMITER = ["-", " "].freeze
  LINE_DELIMITER = ["\n"].freeze

  def initialize(lexeme:, line: 0, position: 0, track_delimiters: false)
    @lexeme = lexeme
    @line = line
    @position = position
    @track_delimiters = track_delimiters
  end

  def create_token
    case
    when punctuation?
      create_punctuation_token
    when quotation_mark?
      create_quotation_mark_token
    when white_space?
      create_word_delimeter_token
    when line_break?
      create_line_break_token
    when alpha? || numeric?
      create_character_token
    when rune?
      create_character_token
    else
      fail "Unknown Token: #{lexeme}"
    end
  end

  private

  attr_reader :lexeme, :line, :position

  def delimiter?
    punctuation? || quotation_mark? || white_space?
  end

  def position_is_trackable?
    true unless delimiter? && !@track_delimiters
  end

  def rune?
    (5792..5872).cover? lexeme.ord
  end

  def alpha?
    /[a-z]/.match? lexeme
  end

  def numeric?
    (48..57).cover? lexeme.ord
  end

  def punctuation?
    PUNCTUATION.include? lexeme
  end

  def quotation_mark?
    QUOTATION_MARK.include? lexeme
  end

  def white_space?
    WORD_DELIMITER.include? lexeme
  end

  def line_break?
    LINE_DELIMITER.include? lexeme
  end

  def create_character_token
    Primus::Token::Character.new(lexeme: lexeme, location: location)
  end

  def create_punctuation_token
    case lexeme
    when "᛭"
      Primus::Token::SentenceDelimiter.new(lexeme: lexeme, location: location)
    when "."
      Primus::Token::SentenceDelimiter.new(lexeme: lexeme, location: location)
    when ","
      Primus::Token::SentenceDelimiter.new(lexeme: lexeme, location: location)
    else
      Primus::Token::Punctuation.new(lexeme: lexeme, location: location)
    end
  end

  def create_quotation_mark_token
    Primus::Token::QuotationMark.new(lexeme: lexeme, location: location)
  end

  def create_word_delimeter_token
    Primus::Token::WordDelimiter.new(lexeme: lexeme, location: location)
  end

  def create_line_break_token
    Primus::Token::LineBreak.new(lexeme: lexeme)
  end

  def location
    if position_is_trackable?
      Primus::Token::Location.new(line: line, position: position)
    else
      Primus::Token::NoLocation.new(line: line)
    end
  end
end
