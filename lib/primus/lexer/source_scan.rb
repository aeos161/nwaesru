class Primus::Lexer::SourceScan
  PAIRS = ["᛫᛬", "᛬᛫"].freeze
  PUNCTUATION = ["᛫", "᛬", "᛭", ".", ",", "'", '"',
                 ";", ":", "-", "!", "?"].freeze

  attr_reader :tokens

  def initialize(page:, strategy:, occurrence: 0)
    @page = page
    @strategy = strategy
    @occurrence = occurrence
    @characters = page.source_body.chars
    @runes = Primus::GematriaPrimus.build.map(&:rune)
    @tokens = []
    @pointer = @byte = @line = @column = @rune_index = 0
  end

  def to_transcription
    add_token until @pointer >= @characters.length
    Primus::Transcription.new(pages: [@page], tokens: tokens)
  end

  private

  def add_token
    lexeme = next_lexeme
    kind = kind_for(lexeme)
    location = source_location(lexeme, kind)
    tokens << Primus::Transcription::Token.new(
      lexeme: lexeme, kind: kind, source_location: location,
    )
    advance(lexeme, kind)
  end

  def next_lexeme
    remainder = @characters[@pointer..].join
    return "\r\n" if remainder.start_with?("\r\n")
    return remainder[0, 2] if PAIRS.include?(remainder[0, 2])
    latin_lexeme(remainder) || @characters[@pointer]
  end

  def latin_lexeme(remainder)
    return unless @strategy == :latin
    candidates = Primus::Token::English::TRI_GRAM
    candidates += Primus::Token::English::BI_GRAM
    match = candidates.detect { |value| remainder.downcase.start_with?(value) }
    remainder[0, match.length] if match
  end

  def kind_for(lexeme)
    return :line_break if ["\r\n", "\r", "\n"].include?(lexeme)
    return :whitespace if lexeme.match?(/\A[\t ]\z/)
    return :punctuation if punctuation?(lexeme)
    return :rune if @runes.include?(lexeme)
    return :latin_symbol if lexeme.match?(/\A[A-Za-z0-9]+\z/)
    :unrecognized
  end

  def punctuation?(lexeme)
    PUNCTUATION.include?(lexeme) || PAIRS.include?(lexeme)
  end

  def source_location(lexeme, kind)
    Primus::Transcription::SourceLocation.new(
      page_number: @page.respond_to?(:number) ? @page.number : nil,
      occurrence: @occurrence, byte_start: @byte,
      byte_end: @byte + lexeme.bytesize, character_start: @pointer,
      character_end: @pointer + lexeme.length, line: @line,
      column: @column, rune_index: kind == :rune ? @rune_index : nil
    )
  end

  def advance(lexeme, kind)
    @pointer += lexeme.length
    @byte += lexeme.bytesize
    @rune_index += 1 if kind == :rune
    if kind == :line_break
      @line += 1
      @column = 0
    else
      @column += lexeme.length
    end
  end
end
