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
      increment_position
      increment_line
    end
  end

  def self.build(page:, strategy: nil, starting_line: 0, starting_position: 0,
                 track_delimiters: false)
    factory = Primus::Lexer::Factory.new(strategy: strategy || :runic)
    strategy = factory.build(data: page.data, line: starting_line,
                             position: starting_position,
                             track_delimiters: track_delimiters)
    new(strategy: strategy)
  end

  protected

  attr_reader :strategy, :current_token

  def tracking_delimiters?
    true if @track_delimiters
  end

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
    return if new_line?
    strategy.increment_position
  end
end
