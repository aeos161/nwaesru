module Primus
  module LiberPrimus

  end
end

require "prime"
require "psych"

require "primus/document"
require "primus/document/filter"
require "primus/lexer"
require "primus/parser"
require "primus/token"
require "primus/token/factory"
require "primus/token/character"
require "primus/token/line_break"
require "primus/token/location"
require "primus/token/sentence_delimiter"
require "primus/token/word_delimiter"
require "primus/word"

require "primus/alternating_shift"
require "primus/fibonacci_shift"
require "primus/gematria_shift"
require "primus/rune_to_letter"
require "primus/totient_shift"
require "primus/translation"
require "primus/translator"
require "primus/gematria_primus"
require "primus/gematria_primus/token"
require "primus/liber_primus/page"
