class Primus::Ngram
  def initialize(ngram:, valid: true, persisted: false)
    @ngram = ngram
    @valid = valid
    @persisted = persisted
  end

  def to_s
    @ngram
  end

  def persisted?
    @persisted
  end

  def valid?
    @valid
  end
end
