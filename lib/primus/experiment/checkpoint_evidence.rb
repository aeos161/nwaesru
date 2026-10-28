class Primus::Experiment::CheckpointEvidence
  class Invalid < StandardError; end

  def initialize(record_path:, data:)
    @record_path = File.expand_path(record_path)
    @data = data
    @directory = File.realpath(File.dirname(@record_path))
  end

  def verify!
    @snapshots = nil
    @final_output_bytes = nil
    invalid!("source record path mismatch") unless File.realpath(saved_record_path) ==
      File.realpath(@record_path)
    items = @data.fetch("checkpoints")
    invalid!("invalid checkpoint list") unless items.is_a?(Array)
    ids = items.map { |item| item.fetch("id") }
    invalid!("duplicate checkpoint ID") unless ids.uniq == ids
    snapshots = items.each_with_index.map { |item, index| verify_item(item, index, items) }
    verify_original(items.first) if items.first
    verify_final(items)
    @snapshots = snapshots.to_h { |snapshot| [snapshot.fetch("step_id"), owned(snapshot)] }.freeze
    nil
  rescue KeyError, IndexError, NoMethodError, TypeError, JSON::ParserError,
         SystemCallError, Primus::Analysis::StrictData::Error => error
    invalid!("invalid checkpoint evidence: #{error.class}: #{error.message}")
  end

  def checkpoint(step_id)
    invalid!("checkpoint evidence has not been verified") unless @snapshots
    @snapshots.fetch(step_id) { invalid!("uncaptured checkpoint #{step_id}") }
  end

  def final_output_bytes
    invalid!("checkpoint evidence has not been verified") unless @snapshots
    @final_output_bytes
  end

  private

  def verify_item(item, index, items)
    expected = expected_step(index)
    invalid!("unsafe checkpoint step ID") unless expected["id"].is_a?(String) &&
      expected["id"].match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
    invalid!("invalid checkpoint ID") unless item["id"].is_a?(String) &&
      item["id"].match?(/\A[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\z/)
    invalid!("checkpoint step mismatch") unless item["step_id"] == expected["id"] &&
      item["operation"] == expected["operation"] && item["parameters"] == expected["parameters"]
    parent = index.zero? ? nil : items[index - 1].fetch("id")
    invalid!("checkpoint linkage mismatch") unless item["ordinal"] == index && item["parent_id"] == parent
    policy = expected["operation"] == "latin" ? "gp-latin-compatibility-v1" : "gp-runes-lossless-v1"
    invalid!("checkpoint policy mismatch") unless item["policy"] == policy
    representation = expected["operation"] == "latin" ? "latin" : "gp-runes"
    invalid!("checkpoint representation mismatch") unless item["representation"] == representation
    expected_source = if @data.key?("source_manifest")
                        @data.fetch("source_manifest")
                      else
                        { "path" => @data.fetch("source_path"),
                          "sha256" => @data.fetch("source_actual_sha256") }
                      end
    invalid!("checkpoint source identity mismatch") unless item["source"] == expected_source
    output = artifact(item, "output", "output.txt")
    Primus::Analysis::StrictData.utf8(output)
    symbols = Primus::Analysis::StrictData.json(artifact(item, "symbols", "symbols.json"))
    lexemes = Primus::Analysis::StrictData.json(artifact(item, "lexemes", "lexemes.json"))
    verify_mapping(item, output, symbols, lexemes)
    verify_lineage(expected["operation"], lexemes)
    verify_spans(item, output, lexemes)
    item.merge("output_bytes" => output, "symbols_rows" => symbols, "lexemes_rows" => lexemes)
  end

  def expected_step(index)
    return { "id" => "original", "operation" => "capture", "parameters" => {} } if index.zero?
    @data.fetch("configuration").fetch("steps").fetch(index - 1)
  end

  def artifact(item, key, filename)
    metadata = item.fetch(key)
    path = metadata.fetch("path")
    relative = File.join("checkpoints", item.fetch("step_id"), filename)
    expected = File.join(File.dirname(saved_record_path), relative)
    resolved = File.join(@directory, relative)
    invalid!("checkpoint path mismatch") unless path == expected && File.realpath(path) == resolved
    bytes = File.binread(path)
    invalid!("checkpoint artifact changed") unless metadata["bytes"] == bytes.bytesize &&
      metadata["sha256"] == Digest::SHA256.hexdigest(bytes)
    bytes
  end

  def verify_mapping(item, output, symbols, lexemes)
    invalid!("invalid checkpoint mapping") unless symbols.is_a?(Array) && lexemes.is_a?(Array)
    runes = lexemes.select { |token| token["kind"] == "rune" }
    invalid!("checkpoint symbols mismatch") unless runes.size == symbols.size
    symbols.each_with_index do |symbol, ordinal|
      token = runes.fetch(ordinal)
      coordinates = Primus::Transcription::SourceLocation::ATTRIBUTES
      invalid!("invalid checkpoint coordinates") unless coordinates.all? { |name|
        key = name.to_s
        valid_coordinate?(key, symbol[key]) && valid_coordinate?(key, token["source_#{key}"]) }
      coordinates_match = Primus::Transcription::SourceLocation::ATTRIBUTES.all? { |name|
        symbol[name.to_s] == token["source_#{name}"] }
      expected_latin = Primus::Analysis::MAP[token["lexeme"]]
      invalid!("unknown checkpoint rune") unless expected_latin
      invalid!("checkpoint source mismatch") unless symbol["ordinal"] == ordinal &&
        symbol["rune"] == token["lexeme"] && symbol["latin"] == expected_latin &&
        coordinates_match
    end
    identities = symbols.map { |symbol| symbol.values_at("page_number", "occurrence", "rune_index") }
    invalid!("duplicate checkpoint source identity") unless identities.uniq.size == identities.size
    if item["operation"] != "latin"
      invalid!("checkpoint output mismatch") unless lexemes.map { |token| token["lexeme"] }.join.b == output
    end
  end

  def verify_lineage(operation, lexemes)
    if operation == "capture"
      @original_lexemes = @previous_lexemes = lexemes
      return
    end
    previous = @previous_lexemes
    invalid!("checkpoint lexical count changed") unless lexemes.size == previous.size
    expected = operation == "reverse-runes" ? reversed_runes(previous) : previous
    lexemes.zip(expected).each do |current, parent|
      invalid!("checkpoint lexical mapping changed") unless same_identity?(current, parent)
      invalid!("checkpoint non-rune changed") unless current["kind"] == "rune" || current["lexeme"] == parent["lexeme"]
      invalid!("checkpoint Atbash mismatch") if operation == "atbash" &&
        current["kind"] == "rune" && current["lexeme"] != mirrored(parent["lexeme"])
      invalid!("checkpoint rune changed") if %w[reverse-runes latin].include?(operation) &&
        current["kind"] == "rune" && current["lexeme"] != parent["lexeme"]
    end
    @previous_lexemes = lexemes
  end

  def reversed_runes(tokens)
    runes = tokens.select { |token| token["kind"] == "rune" }.reverse.each
    tokens.map { |token| token["kind"] == "rune" ? runes.next : token }
  end

  def same_identity?(current, parent)
    keys = parent.keys.select { |key| key.start_with?("source_") }
    current["kind"] == parent["kind"] && keys.all? { |key| current[key] == parent[key] }
  end

  def mirrored(rune)
    alphabet = Primus::GematriaPrimus.build
    index = alphabet.find_by(rune: rune).index
    alphabet.find_by(index: 28 - index).rune
  end

  def valid_coordinate?(name, value)
    return value == "warning" || value.is_a?(Integer) if name == "page_number"
    value.is_a?(Integer)
  end

  def verify_spans(item, output, lexemes)
    lexemes.each do |token|
      first = token["output_byte_start"]
      last = token["output_byte_end"]
      if token["rendering"] == "omitted"
        invalid!("omitted token has output span") unless first.nil? && last.nil?
      else
        invalid!("invalid checkpoint output span") unless first.is_a?(Integer) &&
          last.is_a?(Integer) && first >= 0 && last <= output.bytesize && last >= first
        value = output.byteslice(first...last)
        expected = if item["operation"] == "latin" && token["kind"] == "rune"
                     Primus::GematriaPrimus.build.find_by(rune: token["lexeme"]).letter
                   elsif token["rendering"] == "retained"
                     token["lexeme"]
                   end
        invalid!("checkpoint rendered token mismatch") if expected && value != expected.b
      end
    end
  end

  def verify_final(items)
    terminal = items.last
    unless terminal && terminal["operation"] == "latin"
      invalid!("unexpected final checkpoint") if @data["final_checkpoint_id"]
      return
    end
    expected_size = @data.fetch("configuration").fetch("steps").size + 1
    invalid!("incomplete final chain") unless items.size == expected_size
    invalid!("final checkpoint mismatch") unless @data["final_checkpoint_id"] == terminal["id"]
    root = @data.fetch("artifacts").fetch("output.txt")
    invalid!("final output mismatch") unless root["sha256"] == terminal.fetch("output").fetch("sha256")
    path = root.fetch("path")
    expected = File.join(File.dirname(saved_record_path), "output.txt")
    invalid!("final output path mismatch") unless path == expected &&
      File.realpath(path) == File.join(@directory, "output.txt")
    bytes = File.binread(path)
    invalid!("final output artifact changed") unless root["bytes"] == bytes.bytesize &&
      root["sha256"] == Digest::SHA256.hexdigest(bytes)
    @final_output_bytes = bytes.dup.freeze
  end

  def verify_original(original)
    metadata = @data.fetch("artifacts").fetch("source-body.txt")
    path = metadata.fetch("path")
    invalid!("source-body path mismatch") unless
      path == File.join(File.dirname(saved_record_path), "source-body.txt") &&
      File.realpath(path) == File.join(@directory, "source-body.txt")
    bytes = File.binread(path)
    invalid!("source-body artifact changed") unless metadata["bytes"] == bytes.bytesize &&
      metadata["sha256"] == Digest::SHA256.hexdigest(bytes)
    Primus::Experiment::OrderedSourceEvidence.new(
      record_path: saved_record_path, data: @data, directory: @directory
    ).verify!(bytes, @original_lexemes) if @data.key?("source_manifest")
    invalid!("original checkpoint differs from source body") unless
      original.fetch("output").fetch("sha256") == metadata["sha256"]
  end

  def invalid!(message)
    raise Invalid, "#{@record_path}: #{message}"
  end

  def saved_record_path
    path = @data.fetch("artifacts").fetch("source-body.txt").fetch("path")
    File.join(File.dirname(path), "record.json")
  end

  def owned(value)
    case value
    when Hash then value.each_with_object({}) { |(key, item), copy| copy[owned(key)] = owned(item) }.freeze
    when Array then value.map { |item| owned(item) }.freeze
    else value.dup.freeze
    end
  end
end
