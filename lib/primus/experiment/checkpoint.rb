class Primus::Experiment::Checkpoint
  RUNE_POLICY = "gp-runes-lossless-v1".freeze
  LATIN_POLICY = "gp-latin-compatibility-v1".freeze

  attr_reader :step, :ordinal, :output_bytes, :parent_id, :symbols, :lexemes

  def initialize(step:, ordinal:, transcription:, output_bytes:, parent_id:, rendering: nil)
    @id = SecureRandom.uuid.freeze
    @step = deep_freeze(Marshal.load(Marshal.dump(step)))
    @ordinal = ordinal
    @transcription = transcription
    @output_bytes = output_bytes.dup.b.freeze
    @parent_id = parent_id&.dup&.freeze
    @rendering = rendering && deep_freeze(Marshal.load(Marshal.dump(rendering)))
    @symbols = deep_freeze(build_symbols)
    @lexemes = deep_freeze(build_lexemes)
    @transcription = @rendering = nil
    freeze
  end

  def id
    @id
  end

  def policy
    step["operation"] == "latin" ? LATIN_POLICY : RUNE_POLICY
  end

  def build_symbols
    @transcription.tokens.select { |token| token.kind == :rune }
      .each_with_index.map { |token, index| symbol(token, index) }
  end

  def build_lexemes
    cursor = 0
    @transcription.tokens.map do |token|
      span = token_span(token, cursor)
      cursor = span.last if span
      rendering = rendering_status(token, span)
      lexeme(token).merge("rendering" => rendering,
                          "output_byte_start" => span&.first,
                          "output_byte_end" => span&.last)
    end
  end

  def record
    { "id" => id, "step_id" => step.fetch("id"), "ordinal" => ordinal,
      "parent_id" => parent_id, "operation" => step.fetch("operation"),
      "parameters" => Marshal.load(Marshal.dump(step.fetch("parameters"))),
      "policy" => policy, "representation" => representation }
  end

  private

  def representation
    step["operation"] == "latin" ? "latin" : "gp-runes"
  end

  def symbol(token, ordinal)
    source = token.source_location
    gp = Primus::GematriaPrimus.build.find_by(rune: token.lexeme)
    { "ordinal" => ordinal, "rune" => token.lexeme, "latin" => gp.letter,
      **Primus::Transcription::SourceLocation::ATTRIBUTES.to_h { |name|
        [name.to_s, source.public_send(name)] } }
  end

  def lexeme(token)
    source = token.source_location
    coordinates = Primus::Transcription::SourceLocation::ATTRIBUTES.to_h { |name|
      ["source_#{name}", source.public_send(name)] }
    { "lexeme" => token.lexeme, "kind" => token.kind.to_s, **coordinates }
  end

  def token_span(token, cursor)
    if @rendering
      source = token.source_location
      @rendering[[source.occurrence, source.byte_start, source.byte_end]]
    else
      [cursor, cursor + token.lexeme.bytesize]
    end
  end

  def rendering_status(token, span)
    return "omitted" unless span
    visible = output_bytes.byteslice(span.first...span.last)
    visible == token.lexeme.b ? "retained" : "rendered"
  end

  def deep_freeze(value)
    case value
    when Hash then value.each { |key, item| deep_freeze(key); deep_freeze(item) }
    when Array then value.each { |item| deep_freeze(item) }
    end
    value.freeze
  end
end
