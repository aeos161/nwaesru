require "numeric_inverse/ext"

require "oxford_dictionary"
require "prime"
require "psych"
require "thor"

module Primus
  module Commands; end
  module Processor; end

  def self.index_of_coincidence(document:, length: 1, alphabet: nil)
    alphabet ||= Primus::GematriaPrimus::build
    counter = Primus::Document::TokenCounter.new(length: length || 1)
    document.accept(counter)
    tokens = counter.result
    numerator = if length == 1
                  tokens.reject(&:zero?).sum { |count| count * (count - 1) }
                else
                  tokens.sum do |row|
                    row.reject(&:zero?).sum { |count| count * (count - 1) }
                  end
                end
    total_tokens = counter.size
    c = (alphabet.size**length).to_f
    denominator = (total_tokens * (total_tokens - 1)) / c
    numerator / denominator
  end

  def self.sum(text, strategy = :latin)
    parse(text, strategy).map(&:sum)
  end

  def self.parse(text, strategy = :latin)
    splitter = strategy == :rune ? "-" : " "
    text = text.split(splitter) if text.respond_to?(:split)
    text.map { |word| to_word(word, strategy) }
  end

  def self.to_word(text, strategy = :latin)
    factory = Primus::Lexer::Factory.new(strategy: strategy)
    strategy = factory.build(data: text)
    lexer = Primus::Lexer.new(strategy: strategy)
    lexer.tokenize
    translator = Primus::Document::Translator.new(strategy: strategy)
    translator.visit_word(Primus::Word.new(tokens: lexer.tokens))
  end
end

require "primus/core_extensions/integer_monkey_patch"
require "primus/core_extensions/string_monkey_patch"

require "primus/page"
require "primus/transcription"
require "primus/transcription/token"
require "primus/transcription/source_location"
require "primus/transcription/page_boundary"

require "primus/document"
require "primus/document/decoder"

require "primus/document/affine"
require "primus/document/atbash"
require "primus/document/builder"
require "primus/document/caesar_shift"
require "primus/document/cipher_factory"
require "primus/document/filter"
require "primus/document/key_finder"
require "primus/document/mask"
require "primus/document/ngram_converter"
require "primus/document/pattern_matcher"
require "primus/document/printer"
require "primus/document/word_reverser"
require "primus/document/token_counter"
require "primus/document/totient_shift"
require "primus/document/translator"
require "primus/document/vigenere"

require "primus/gematria_primus"
require "primus/gematria_primus/token"

require "primus/latin_alphabet"
require "primus/latin_alphabet/token"

require "primus/lexer"
require "primus/lexer/source_scan"
require "primus/lexer/latin"
require "primus/lexer/factory"
require "primus/lexer/runic"

require "primus/liber_primus"
require "primus/liber_primus/page"

require "primus/ngram"
require "primus/ngram/identity_map"

require "primus/parser"
require "primus/parser/compatibility"

require "primus/sentence"

require "primus/token"
require "primus/token/english"
require "primus/token/runic"
require "primus/token/character"
require "primus/token/line_break"
require "primus/token/location"
require "primus/token/no_location"
require "primus/token/punctuation"
require "primus/token/quotation_mark"
require "primus/token/sentence_delimiter"
require "primus/token/word_delimiter"

require "primus/word"
require "primus/word/expander"
require "primus/word/generator"

require "primus/commands/sub_command_base"
require "primus/commands/words"
require "primus/commands/brute"
require "primus/commands/files"

Primus::CoreExtensions::StringMonkeyPatch.apply_patch
Primus::CoreExtensions::IntegerMonkeyPatch.apply_patch
