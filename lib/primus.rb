module Primus
  def self.relative_word_frequencies_in_english
    frequencies =
      [0.084966, 0.020720, 0.045388, 0.033844, 0.111607, 0.018121, 0.024705,
      0.030034, 0.075448, 0.001965, 0.011016, 0.054893, 0.030129, 0.066544,
      0.071635, 0.031671, 0.001962, 0.075809, 0.057351, 0.069509, 0.036308,
      0.010074, 0.012899, 0.002902, 0.017779, 0.002722]
    ("a".."z").zip(frequencies)
  end

  def self.index_of_coincidence(text:, alphabet: nil)
    alphabet ||= Primus::GematriaPrimus::build
    chars = text.split("").
            select { |char| alphabet.unique_tokens.include? char }.
            group_by { |char| char }.transform_values(&:size)
    numerator = chars.map { |letter, count| count * (count - 1) }.sum
    total_chars = chars.map { |letter, count| count }.sum
    c = alphabet.unique_tokens.size.to_f
    denominator = (total_chars * (total_chars - 1)) / c
    numerator / denominator
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
