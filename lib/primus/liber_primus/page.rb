class Primus::LiberPrimus::Page
  attr_reader :number, :lines

  DIR_PATH = "data/liber_primus".freeze
  FILE_EXT = ".yml"

  def initialize(number:, lines:)
    @number = number
    @lines = lines
  end

  def self.open(page_number:)
    path = self.file_name(page_number: page_number)
    data = Psych.safe_load(File.read(path))
    new(number: page_number, lines: data["body"].split(" "))
  end

  def self.file_name(page_number:)
    [DIR_PATH, "page#{page_number}#{FILE_EXT}"].join("/")
  end
end
