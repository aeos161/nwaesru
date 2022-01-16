class Primus::LiberPrimus::Page
  attr_reader :number, :data

  ENCODED_DIR_PATH = "data/encoded/liber_primus".freeze
  DECODED_DIR_PATH = "data/decoded/liber_primus".freeze
  FILE_EXT = ".yml"

  def initialize(number: nil, data: "")
    @number = number
    @data = data
  end

  def to_s
    data.to_s
  end

  def self.open(page_number:, encoded: true)
    path = self.file_name(page_number: page_number, encoded: encoded)
    data = Psych.safe_load(File.read(path))["body"]
    if encoded
      data = data.split(" ").join
    end
    new(number: page_number, data: data)
  end

  def self.file_name(page_number:, encoded: true)
    dir_path = ENCODED_DIR_PATH
    unless encoded
      dir_path = DECODED_DIR_PATH
    end
    [dir_path, "page_#{page_number}#{FILE_EXT}"].join("/")
  end
end
