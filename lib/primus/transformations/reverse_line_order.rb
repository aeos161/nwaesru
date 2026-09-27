class Primus::Transformations::ReverseLineOrder
  def call(transcription)
    Primus::Transformations::PageMapper.new.call(transcription) do |tokens|
      projection = Primus::Transcription::LineProjection.new(tokens)
      projection.interleave(projection.groups.reverse)
    end
  end
end
