class Primus::Ngram
  def initialize(ngram:, valid: true)
    @ngram = ngram
    @valid = valid
  end

  def to_s
    @ngram
  end

  def valid?
    @valid
  end
end
