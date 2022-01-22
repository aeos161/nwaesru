class Primus::Parser
  attr_reader :tokens, :result, :last_word, :last_token

  def initialize(tokens: [], document: nil, first_word: nil)
    @tokens = tokens
    @result = document || Primus::Document.new
    @first_word = first_word || Primus::Word.new
    @last_word = Primus::Word.new
    @last_token = nil
  end

  def parse
    parse_tokens
  end

  protected

  attr_reader :first_word

  def word_boundary?(token)
    token.delimiter? && !token.is_a?(Primus::Token::LineBreak)
  end

  def parse_tokens
    word = first_word
    tokens.each do |token|
      parse_token(token, word)

      if word_boundary? token
        word = Primus::Word.new
      end
    end

    handle_end_of_document(word)
  end

  def parse_token(token, word)
    if word_boundary? token
      add_word word
      add_token token
    else
      unless token.is_a?(Primus::Token::LineBreak)
        word << token
      end
    end
    @last_token = token
  end

  def handle_end_of_document(word)
    if word.blank? && !word_boundary?(last_token)
      add_token last_token
    else
      add_word word
      @last_word = word
    end
  end

  def add_word(word)
    return if word.blank?
    @result << word
  end

  def add_token(token)
    @result << token
  end
end
