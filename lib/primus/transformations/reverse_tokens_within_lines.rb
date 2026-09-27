class Primus::Transformations::ReverseTokensWithinLines
  def call(transcription)
    Primus::Transformations::PageMapper.new.call(transcription) do |tokens|
      projection = Primus::Transcription::LineProjection.new(tokens)
      projection.interleave(projection.groups.map(&:reverse))
    end
  end
end
