class Primus::Parser::Compatibility
  attr_reader :position, :line

  def initialize(strategy: :runic, position: 0, line: 0,
                 track_delimiters: false)
    @strategy = strategy
    @position = position || 0
    @line = line || 0
    @track_delimiters = track_delimiters
  end

  def tokens_for(transcription)
    transcription.tokens.map { |source| token_for(source) }
  end

  def token_for(source)
    token = build_token(source)
    token.source_location = source.source_location
    token.location = location_for(token)
    advance(token)
    token
  end

  private

  def build_token(source)
    lexeme = source.lexeme
    case source.kind
    when :line_break then Primus::Token::LineBreak.new(lexeme: lexeme)
    when :whitespace then Primus::Token::WordDelimiter.new(lexeme: lexeme)
    when :punctuation then punctuation_token(lexeme)
    else Primus::Token::Character.new(lexeme: mapping_key(lexeme))
    end
  end

  def punctuation_token(lexeme)
    if word_mark?(lexeme)
      return Primus::Token::WordDelimiter.new(lexeme: lexeme)
    end
    if sentence_mark?(lexeme)
      return Primus::Token::SentenceDelimiter.new(lexeme: lexeme)
    end
    return Primus::Token::QuotationMark.new(lexeme: lexeme) if lexeme == '"'
    Primus::Token::Punctuation.new(lexeme: lexeme)
  end

  def word_mark?(lexeme)
    @strategy == :runic && lexeme == "-"
  end

  def sentence_mark?(lexeme)
    lexeme == "." || (@strategy == :runic && [",", "᛭"].include?(lexeme))
  end

  def mapping_key(lexeme)
    @strategy == :latin ? lexeme.downcase : lexeme
  end

  def location_for(token)
    return nil if token.line_break?
    if token.delimiter? && !@track_delimiters
      Primus::Token::NoLocation.new(line: line)
    else
      Primus::Token::Location.new(line: line, position: position)
    end
  end

  def advance(token)
    if token.line_break?
      @line += 1
    elsif !token.delimiter? || @track_delimiters
      @position += 1
    end
  end
end
