class Primus::Lexer
  def initialize(strategy:)
    @strategy = strategy
    @current_token = nil
  end

  def data
    strategy.data
  end

  def position
    strategy.position
  end

  def tokens
    strategy.tokens
  end

  def tokenize
    until strategy.complete? do
      strategy.extract_lexeme
      @current_token = strategy.create_token
      unless @current_token.is_a? Primus::Token::LineBreak
        increment_position
      end
      increment_line
    end
  end

  def self.build(page:, strategy: nil, starting_line: 0, starting_position: 0)
    factory = Primus::Lexer::Factory.new(strategy: strategy || :runic)
    strategy = factory.build(data: page.data, line: starting_line,
                             position: starting_position)
    new(strategy: strategy)
  end

  protected

  attr_reader :strategy, :current_token

  def new_line?
    current_token.is_a? Primus::Token::LineBreak
  end

  def delimiter?
    current_token.delimiter?
  end

  def increment_line
    return unless new_line?
    strategy.increment_line
  end

  def increment_position
    return if delimiter?
    strategy.increment_position
  end
end
