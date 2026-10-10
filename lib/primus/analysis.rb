module Primus::Analysis
  RUNES = %w[ᚠ ᚢ ᚦ ᚩ ᚱ ᚳ ᚷ ᚹ ᚻ ᚾ ᛁ ᛄ ᛇ ᛈ ᛉ ᛋ ᛏ ᛒ ᛖ ᛗ ᛚ ᛝ ᛟ ᛞ ᚪ ᚫ ᚣ ᛡ ᛠ].freeze
  EXPANSIONS = %w[f u th o r c g w h n i j eo p x s t b e m l ng oe d a ae y io ea].freeze
  MAP = RUNES.zip(EXPANSIONS).to_h.freeze
  LATIN = ("a".."z").to_a.freeze
  REPRESENTATIONS = %w[gp-runes-v1 gp-expanded-latin-v1].freeze
end
