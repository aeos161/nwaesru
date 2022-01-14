class Primus::LiberPrimus::Page
  attr_reader :number, :lines

  ENCODED_DIR_PATH = "data/encoded/liber_primus".freeze
  DECODED_DIR_PATH = "data/decoded/liber_primus".freeze
  FILE_EXT = ".yml"

  LINE_DELIMITER = "/".freeze
  WORD_DELIMITER = "-".freeze
  SENTENCE_DELIMITER = ".".freeze

  def initialize(number: nil, lines: [])
    @number = number
    @lines = lines
  end

  def to_s
    lines.join("\n").rstrip
  end

  def self.open(page_number:, encoded: true)
    path = self.file_name(page_number: page_number, encoded: encoded)
    data = Psych.safe_load(File.read(path))
    new(number: page_number, lines: data["body"].split(LINE_DELIMITER))
  end

  def self.file_name(page_number:, encoded: true)
    dir_path = ENCODED_DIR_PATH
    unless encoded
      dir_path = DECODED_DIR_PATH
    end
    [dir_path, "page_#{page_number}#{FILE_EXT}"].join("/")
  end
end
