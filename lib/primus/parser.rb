class Primus::Parser
  attr_reader :tokens, :result

  def initialize(tokens: [])
    @tokens = tokens
    @result = Primus::Document.new
  end

  def parse
    parse_tokens
  end

  protected

  def word_boundary?(token)
    token.delimiter? && !token.is_a?(Primus::Token::LineBreak)
  end

  def parse_tokens
    word = Primus::Word.new
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
