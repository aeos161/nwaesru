module Primus
  def self.index_of_coincidence(text:, alphabet: nil)
    alphabet ||= Primus::GematriaPrimus::build
    chars = text.select { |char| alphabet.include? char }.
            group_by(&:letter).transform_values(&:size)
    numerator = chars.map { |letter, count| count * (count - 1) }.sum
    total_chars = chars.map { |letter, count| count }.sum
    c = alphabet.size.to_f
    denominator = (total_chars * (total_chars - 1)) / c
    numerator / denominator
  end

  def self.to_word(text:, alphabet: nil)
    Primus::Word.new(tokens: lex(text: text))
  end

  def self.parse(text:, alphabet: nil)
    alphabet ||= Primus::GematriaPrimus::build
    text.split(" ").map { |word| to_word(text: word) }
  end

  def self.lex(text:)
    alphabet ||= Primus::GematriaPrimus::build
    standardized_text = text.gsub("ing", "ng").gsub("ia", "io").gsub("z", "s").
                        gsub("k", "c")
    p = 0
    tokens = []
    until p > standardized_text.size - 1 do
      tk = standardized_text[p..(p + 1)]

      if tk.match?(/th|eo|ng|ing|oe|ae|io|ia|ea/)
        tokens << alphabet.find_by(letter: tk)
        p += 2
      else
        tokens << alphabet.find_by(letter: tk[0])
        p += 1
      end
    end

    tokens
  end
end

require "prime"
require "psych"

require "primus/document"
require "primus/document/decoder"

require "primus/document/affine"
require "primus/document/atbash"
require "primus/document/alternating_shift"
require "primus/document/builder"
require "primus/document/caesar_shift"
require "primus/document/complement_shift"
require "primus/document/fibonacci_shift"
require "primus/document/filter"
require "primus/document/mask"
require "primus/document/printer"
require "primus/document/totient_shift"
require "primus/document/stream_cipher"
require "primus/document/translator"
require "primus/document/vigenere"

require "primus/gematria_primus"
require "primus/gematria_primus/token"
require "primus/gematria_primus/calculator"

require "primus/latin_alphabet"
require "primus/latin_alphabet/token"

require "primus/lexer"
require "primus/liber_primus"
require "primus/liber_primus/page"
require "primus/parser"
require "primus/token"
require "primus/token/factory"
require "primus/token/character"
require "primus/token/line_break"
require "primus/token/location"
require "primus/token/sentence_delimiter"
require "primus/token/word_delimiter"
require "primus/word"
