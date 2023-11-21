class Primus::Parser
  attr_reader :tokens, :result, :last_token

  def initialize(tokens: [], document: nil, first_word: nil)
    @tokens = tokens.to_enum
    @result = document || Primus::Document.new
    @sentence = Primus::Sentence.new
    @word = Primus::Word.new
    @last_token = nil
  end

  def parse
    while true
      parse_tokens
    end
  rescue StopIteration
    handle_end_of_document
  end

  protected

  def end_of_word?(token)
    token.is_a?(Primus::Token::WordDelimiter)
  end

  def end_of_sentence?(token)
    token.is_a?(Primus::Token::SentenceDelimiter)
  end

  def parse_tokens
    token = tokens.next
    if token.delimiter?
      parse_delimiter token
    else
      parse_character token
    end
    @last_token = token
  end

  def parse_character(token)
    if token.line_break?
      parse_line_break token
    else
      add_to_word token
    end
  end

  def parse_delimiter(token)
    case token
    when ->(token) { end_of_word?(token) }
      complete_current_word token
    when ->(token) { end_of_sentence?(token) }
      complete_current_sentence token
    end
  end

  def parse_line_break(token)
    if @word.blank? && @sentence.blank?
      add_to_document token
    else
      tokens.peek
      add_to_word token
    end
  rescue StopIteration
  end

  def complete_current_sentence(token)
    complete_current_word token
    add_to_document @sentence
    @sentence = Primus::Sentence.new
  end

  def complete_current_word(token = nil)
    unless @word.blank?
      add_to_sentence @word
    end

    unless token.nil?
      add_to_sentence token
    end

    @word = Primus::Word.new
  end

  def handle_end_of_document
    if !end_of_word?(last_token) && !end_of_sentence?(last_token)
      complete_current_word
    end

    add_to_document @sentence

    if last_token.is_a? Primus::Token::LineBreak
      @result << last_token
    end
  end

  def add_to_word(token)
    @word << token
  end

  def add_to_sentence(word)
    @sentence << word
  end

  def add_to_document(token)
    @result << token
  end
end
