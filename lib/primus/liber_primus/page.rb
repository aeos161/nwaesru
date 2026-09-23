class Primus::LiberPrimus::Page < Primus::Page
  attr_reader :number

  ENCODED_DIR_PATH = "data/encoded/liber_primus".freeze
  DECODED_DIR_PATH = "data/decoded/liber_primus".freeze

  def initialize(number: nil, data: "", **source)
    @number = number
    super(data: data, **source)
  end

  def self.open(page_number:, character_set: :runic)
    path = file_name(page_number: page_number, character_set: character_set)
    body, artifact = load_source(path)
    new(number: page_number, data: body.rstrip, source_body: body,
        artifact_bytes: artifact, source_path: path)
  end

  def self.file_name(page_number:, character_set: :runic)
    dir_path = character_set == :latin ? DECODED_DIR_PATH : ENCODED_DIR_PATH
    [dir_path, "page_#{page_number}#{FILE_EXT}"].join("/")
  end
end
