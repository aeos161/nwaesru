class Primus::Transformations::ReverseEntireSequence
  def call(transcription)
    Primus::Transformations::PageMapper.new.call(transcription, &:reverse)
  end
end
