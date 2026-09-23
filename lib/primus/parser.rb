class Primus::Parser
  attr_reader :result, :tokens, :last_token

  def initialize(tokens: [], transcription: nil, document: nil,
                 policy: :compatibility, strategy: :runic,
                 track_delimiters: false)
    unless policy == :compatibility
      raise ArgumentError, "Unknown policy: #{policy}"
    end
    @source = transcription
    @input_tokens = tokens
    @strategy = strategy
    @track_delimiters = track_delimiters
    @result = document || Primus::Document.new
  end

  def parse
    @result = Primus::Document.new
    @sentence = Primus::Sentence.new
    @word = Primus::Word.new
    @tokens = projected_tokens
    tokens.each_with_index { |token, index| consume(token, index) }
    finish
    result
  end

  private

  def projected_tokens
    return @input_tokens if @source.nil?
    converter = Primus::Parser::Compatibility.new(
      strategy: @strategy, track_delimiters: @track_delimiters,
    )
    view_sources.map { |source|
      source ? converter.token_for(source) : synthetic_break
    }
  end

  def view_sources
    @source.pages.each_with_index.flat_map do |_page, occurrence|
      sources = sources_for(occurrence)
      if intermediate_page?(occurrence)
        sources.pop while trailing_space?(sources.last)
        sources + [nil]
      else
        sources
      end
    end
  end

  def sources_for(occurrence)
    @source.tokens.select do |token|
      token.source_location.occurrence == occurrence
    end
  end

  def trailing_space?(token)
    token && [:whitespace, :line_break].include?(token.kind)
  end

  def intermediate_page?(occurrence)
    occurrence < @source.pages.size - 1
  end

  def synthetic_break
    Primus::Token::LineBreak.new
  end

  def consume(token, index)
    @last_token = token
    if token.is_a?(Primus::Token::SentenceDelimiter)
      complete_sentence(token)
    elsif token.is_a?(Primus::Token::WordDelimiter)
      complete_word(token)
    elsif token.line_break?
      consume_line_break(token, index)
    elsif token.delimiter?
      complete_word
      @sentence << token
    else
      @word << token
    end
  end

  def consume_line_break(token, index)
    if @word.blank? && @sentence.blank?
      result << token
    elsif index == tokens.length - 1
      complete_word
      flush_sentence
      result << token
    else
      @word << token
    end
  end

  def complete_word(delimiter = nil)
    @sentence << @word if @word.tokens.any?
    @sentence << delimiter if delimiter
    @word = Primus::Word.new
  end

  def complete_sentence(delimiter)
    complete_word
    @sentence << delimiter
    flush_sentence
  end

  def flush_sentence
    result << @sentence if @sentence.text.any?
    @sentence = Primus::Sentence.new
  end

  def finish
    complete_word
    flush_sentence
  end
end
