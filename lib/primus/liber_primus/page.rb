class Primus::LiberPrimus::Page < Primus::Page
  attr_reader :number, :data

  ENCODED_DIR_PATH = "data/encoded/liber_primus".freeze
  DECODED_DIR_PATH = "data/decoded/liber_primus".freeze

  def initialize(number: nil, data: "")
    @number = number
    @data = data
  end

  def self.open(page_number:, character_set: :runic)
    path = file_name(page_number: page_number, character_set: character_set)
    data = load_data(path).rstrip
    new(number: page_number, data: data)
  end

  def self.file_name(page_number:, character_set: :runic)
    dir_path = ENCODED_DIR_PATH
    if character_set == :latin
      dir_path = DECODED_DIR_PATH
    end
    [dir_path, "page_#{page_number}#{FILE_EXT}"].join("/")
  end
end
