class Primus::Transcription::Token
  attr_reader :lexeme, :kind, :source_location

  def initialize(lexeme:, kind:, source_location:)
    @lexeme = lexeme
    @kind = kind
    @source_location = source_location
  end
end
