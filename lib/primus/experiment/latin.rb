class Primus::Experiment::Latin
  attr_reader :output_map

  def call(transcription)
    parser = Primus::Parser.new(transcription: transcription, strategy: :runic,
                                track_delimiters: false)
    parser.parse
    translated = parser.result.accept(Primus::Document::Translator.new)
    output = translated.to_s(:letter)
    @output_map = map_output(translated, output)
    Primus::Experiment::Observation.new(
      output_bytes: output,
      provenance: provenance(translated, transcription.pages)
    )
  end

  private

  def map_output(document, output)
    offset = 0
    flattened(document).each_with_object({}) do |token, mapping|
      source = token.source_location
      bytes = token.to_s(:letter).bytesize
      if source
        visible_end = [offset + bytes, output.bytesize].min
        mapping[[source.occurrence, source.byte_start, source.byte_end]] =
          visible_end > offset ? [offset, visible_end] : nil
      end
      offset += bytes
    end
  end

  def flattened(node)
    return node.text.flat_map { |item| flattened(item) } if node.respond_to?(:text)
    return node.tokens.flat_map { |item| flattened(item) } if node.respond_to?(:tokens)
    [node]
  end

  def provenance(document, pages)
    document.tokens.select { |token|
      token.respond_to?(:index) && !token.index.nil? &&
        token.source_location && token.source_location.rune_index
    }.each_with_index.map do |token, ordinal|
      source = token.source_location
      { "ordinal" => ordinal,
        "rune" => pages.fetch(source.occurrence).source_body.byteslice(source.byte_start...source.byte_end),
        "decoded_rune" => token.rune, "latin" => token.letter,
        **Primus::Transcription::SourceLocation::ATTRIBUTES.to_h { |name|
          [name.to_s, source.public_send(name)] } }
    end
  end

end
