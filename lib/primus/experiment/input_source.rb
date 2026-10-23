class Primus::Experiment::InputSource
  attr_reader :number, :occurrence, :path, :yaml_bytes, :body

  def initialize(selection:, occurrence:)
    @number = selection.fetch("id").delete_prefix("page-").to_i
    @occurrence = occurrence
    @path = "data/encoded/liber_primus/page_#{number}.yml".freeze
    @yaml_bytes = File.binread(path).force_encoding(Encoding::UTF_8)
    raise ArgumentError, "invalid UTF-8 source" unless @yaml_bytes.valid_encoding?
    parsed = Psych.safe_load(@yaml_bytes, aliases: false)
    @body = parsed["body"] if parsed.is_a?(Hash)
    raise ArgumentError, "body must be UTF-8 text" unless body.is_a?(String) && body.valid_encoding?
    raise ArgumentError, "SHA-256 digest does not match" unless selection["sha256"] == yaml_sha256
    @yaml_bytes.freeze
    @body = body.dup.freeze
    freeze
  end

  def yaml_sha256
    Digest::SHA256.hexdigest(yaml_bytes)
  end

  def body_sha256
    Digest::SHA256.hexdigest(body)
  end

  def page
    Primus::LiberPrimus::Page.new(number: number, data: body.rstrip,
      source_body: body, artifact_bytes: yaml_bytes, source_path: path)
  end

  def manifest(byte_start)
    { "page_number" => number, "occurrence" => occurrence,
      "source_path" => path, "yaml_sha256" => yaml_sha256,
      "body_sha256" => body_sha256, "byte_start" => byte_start,
      "byte_end" => byte_start + body.bytesize }
  end
end
