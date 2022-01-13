class Primus::Translation
  attr_reader :lines

  def initialize(lines:)
    @lines = lines
  end

  def to_s
    lines.map { |line| line.map(&:letter).join }.join("\n").rstrip
  end
end
