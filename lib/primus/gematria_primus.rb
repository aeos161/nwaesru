class Primus::GematriaPrimus
  attr_reader :translations

  def initialize(translations:)
    @translations = translations
  end

  def self.build
    translations = dictionary.map.with_index do |data, index|
      Primus::Translation.new(data.merge(index: index))
    end
    new(translations: translations)
  end

  def self.dictionary
    [
      { rune: "ᚠ", letter: "f", value: 2 },
      { rune: "ᚢ", letter: "u", value: 3 },
      { rune: "ᚦ", letter: "th", value: 5 },
      { rune: "ᚩ", letter: "o", value: 7 },
      { rune: "ᚱ", letter: "r", value: 11 },
      { rune: "ᚳ", letter: "c", value: 13 },
      { rune: "ᚷ", letter: "g", value: 17 },
      { rune: "ᚹ", letter: "w", value: 19 },
      { rune: "ᚻ", letter: "h", value: 23 },
      { rune: "ᚾ", letter: "n", value: 29 },
      { rune: "ᛁ", letter: "i", value: 31 },
      { rune: "ᛂ", letter: "j", value: 37 },
      { rune: "ᛇ", letter: "eo", value: 41 },
      { rune: "ᛈ", letter: "p", value: 43 },
      { rune: "ᛉ", letter: "x", value: 47 },
      { rune: "ᛋ", letter: "s", value: 53 },
      { rune: "ᛏ", letter: "t", value: 59 },
      { rune: "ᛒ", letter: "b", value: 61 },
      { rune: "ᛖ", letter: "e", value: 67 },
      { rune: "ᛗ", letter: "m", value: 71 },
      { rune: "ᛚ", letter: "l", value: 73 },
      { rune: "ᛝ", letter: "ing", value: 79 },
      { rune: "ᛟ", letter: "oe", value: 83 },
      { rune: "ᛞ", letter: "d", value: 89 },
      { rune: "ᚪ", letter: "a", value: 97 },
      { rune: "ᚫ", letter: "ae", value: 101 },
      { rune: "ᚣ", letter: "y", value: 103 },
      { rune: "ᛡ", letter: "io", value: 107 },
      { rune: "ᛠ", letter: "ea", value: 109 },
    ]
  end
end
