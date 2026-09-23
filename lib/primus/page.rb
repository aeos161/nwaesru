class Primus::Page
  attr_reader :name, :data, :source_body, :artifact_bytes, :source_path

  DECODED_DIR_PATH = "data/decoded".freeze
  FILE_EXT = ".yml".freeze

  def initialize(data: "", source_body: nil, artifact_bytes: nil,
                 source_path: nil)
    @data = data
    @source_body = source_body || data
    @artifact_bytes = artifact_bytes
    @source_path = source_path
  end

  def ==(page)
    data == page.data
  end

  def to_s
    data.to_s
  end

  def self.open(path:)
    path = [DECODED_DIR_PATH, "#{path}#{FILE_EXT}"].join("/")
    body, artifact = load_source(path)
    new(data: body, source_body: body, artifact_bytes: artifact,
        source_path: path)
  end

  def self.load_data(path)
    load_source(path).first
  end

  def self.load_source(path)
    artifact = File.binread(path).force_encoding(Encoding::UTF_8)
    unless artifact.valid_encoding?
      raise ArgumentError,
            "#{path}: invalid UTF-8"
    end
    body = Psych.safe_load(artifact)&.fetch("body", nil)
    unless body.is_a?(String)
      raise ArgumentError,
            "#{path}: body must be a String"
    end
    [body, artifact]
  end
end
