class Primus::GematriaPrimus::NoToken
  attr_reader :rune, :letter, :value, :index

  def initialize(rune: nil, letter: " ")
    @rune = rune || letter
    @letter = determine_letter(rune)
    @value = nil
    @index = nil
  end

  def present?
    false
  end

  private

  def determine_letter(rune)
    if weird_tokens.include? rune
      " "
    else
      rune
    end
  end

  def weird_tokens
    ["•"]
  end
end
