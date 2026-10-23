class Primus::Experiment::OrderedSourceEvidence
  def initialize(record_path:, data:, directory:)
    @record_path, @data, @directory = record_path, data, directory
  end

  def verify!(aggregate, lexemes)
    sources = @data.fetch("source_manifest")
    invalid!("invalid source manifest") unless sources.is_a?(Array) && sources.size >= 2
    offset = 0
    bodies = sources.each_with_index.map do |source, occurrence|
      invalid!("source occurrence mismatch") unless source.fetch("occurrence") == occurrence
      invalid!("source boundary mismatch") unless source.fetch("byte_start") == offset
      body = verify_source(source, occurrence)
      offset += body.bytesize
      invalid!("source boundary mismatch") unless source.fetch("byte_end") == offset
      body
    end
    invalid!("aggregate source mismatch") unless bodies.join.b == aggregate.b
    verify_coordinates!(sources, bodies, lexemes)
  end

  private

  def verify_coordinates!(sources, bodies, lexemes)
    cursors = Array.new(sources.size, 0)
    last_occurrence = 0
    lexemes.each do |token|
      occurrence = token.fetch("source_occurrence")
      invalid!("source token occurrence mismatch") unless occurrence.is_a?(Integer) &&
        occurrence >= 0 && occurrence < sources.size
      source = sources.fetch(occurrence)
      body = bodies.fetch(occurrence)
      invalid!("source token order mismatch") unless occurrence >= last_occurrence
      invalid!("source token identity mismatch") unless token.fetch("source_page_number") == source.fetch("page_number")
      first = token.fetch("source_byte_start")
      last = token.fetch("source_byte_end")
      invalid!("source token boundary mismatch") unless first == cursors[occurrence] &&
        last.is_a?(Integer) && last > first && last <= body.bytesize
      invalid!("source token bytes mismatch") unless body.byteslice(first...last).b == token.fetch("lexeme").b
      cursors[occurrence] = last
      last_occurrence = occurrence
    end
    invalid!("source token coverage mismatch") unless cursors == bodies.map(&:bytesize)
  end

  def verify_source(source, occurrence)
    number = source.fetch("page_number")
    expected_path = "data/encoded/liber_primus/page_#{number}.yml"
    invalid!("source page identity mismatch") unless number.is_a?(Integer) &&
      number >= 0 && source.fetch("source_path") == expected_path
    yaml = artifact("source-#{occurrence}.yml", source.fetch("yaml_sha256"))
    body = artifact("source-#{occurrence}-body.txt", source.fetch("body_sha256"))
    parsed = Psych.safe_load(yaml, aliases: false)
    invalid!("source YAML/body mismatch") unless parsed.is_a?(Hash) && parsed["body"].b == body.b
    body
  end

  def artifact(name, digest)
    metadata = @data.fetch("artifacts").fetch(name)
    path = File.join(File.dirname(@record_path), name)
    invalid!("source artifact path mismatch") unless metadata.fetch("path") == path &&
      File.realpath(path) == File.join(@directory, name)
    bytes = File.binread(path)
    invalid!("source artifact changed") unless metadata.fetch("bytes") == bytes.bytesize &&
      metadata.fetch("sha256") == digest && digest == Digest::SHA256.hexdigest(bytes)
    bytes
  end

  def invalid!(message)
    raise Primus::Experiment::CheckpointEvidence::Invalid, "#{@record_path}: #{message}"
  end
end
