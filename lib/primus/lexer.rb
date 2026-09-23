class Primus::Lexer
  attr_reader :transcription, :tokens, :position

  def initialize(strategy:, page: nil, occurrence: 0)
    @strategy = strategy
    @page = page || Primus::Page.new(data: source_data)
    @occurrence = occurrence
    @tokens = []
    @position = strategy.position
  end

  def data
    strategy.data
  end

  def tokenize
    scan = Primus::Lexer::SourceScan.new(page: @page, strategy: strategy_name,
                                         occurrence: @occurrence)
    @transcription = scan.to_transcription
    policy = Primus::Parser::Compatibility.new(
      strategy: strategy_name, position: strategy.position,
      line: strategy.line, track_delimiters: strategy.tracking_delimiters?
    )
    @tokens = policy.tokens_for(transcription)
    @position = policy.position
  end

  def self.build(page:, strategy: nil, starting_line: 0, starting_position: 0,
                 track_delimiters: false, occurrence: 0)
    factory = Primus::Lexer::Factory.new(strategy: strategy || :runic)
    lexer_strategy = factory.build(data: page.source_body, line: starting_line,
                                   position: starting_position,
                                   track_delimiters: track_delimiters)
    new(strategy: lexer_strategy, page: page, occurrence: occurrence)
  end

  private

  attr_reader :strategy

  def strategy_name
    strategy.is_a?(Primus::Lexer::Latin) ? :latin : :runic
  end

  def source_data
    strategy.respond_to?(:raw_source) ? strategy.raw_source : strategy.data.join
  end
end
