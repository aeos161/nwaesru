class Primus::Transcription::LineProjection
  attr_reader :groups

  def initialize(tokens)
    @groups = tokens.empty? ? [] : [[]]
    @breaks = []
    tokens.each { |token| add(token) }
  end

  def interleave(groups)
    groups.each_with_index.flat_map do |group, index|
      group + Array(@breaks[index])
    end
  end

  private

  def add(token)
    if token.kind == :line_break
      add_break(token)
    else
      @groups.last << token
    end
  end

  def add_break(token)
    @breaks << token
    @groups << []
  end
end
