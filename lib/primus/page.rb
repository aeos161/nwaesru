class Primus::Page
  attr_reader :name, :data

  DECODED_DIR_PATH = "data/decoded".freeze
  FILE_EXT = ".yml"

  def initialize(data: "")
    @data = data
  end

  def ==(page)
    data == page.data
  end

  def to_s
    data.to_s
  end

  def self.open(path:)
    path = [DECODED_DIR_PATH, "#{path}#{FILE_EXT}"].join("/")
    new(data: load_data(path))
  end

  def self.load_data(path)
    Psych.safe_load(File.read(path))["body"]
  end
end
