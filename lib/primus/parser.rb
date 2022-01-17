class Primus::Parser
  attr_reader :tokens, :result, :last_word

  def initialize(tokens: [], document: nil, first_word: nil)
    @tokens = tokens
    @result = document || Primus::Document.new
    @first_word = first_word || Primus::Word.new
    @last_word = Primus::Word.new
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
    last_token = nil
    tokens.each do |token|
      if word_boundary? token
        add_word word
        add_token token
        word = Primus::Word.new
      else
        unless token.is_a?(Primus::Token::LineBreak)
          word << token
        end
      end
      last_token = token
    end

    if word.blank?
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
