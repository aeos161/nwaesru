RSpec.describe Primus::Lexer do
  describe "#tokenize" do
    it "retains apostrophes in ordered source lexemes" do
      page = Primus::LiberPrimus::Page.new(number: 55, data: "ᚠ'ᚢ")
      lexer = Primus::Lexer.build(page: page)

      lexer.tokenize
      lexemes = lexer.transcription.tokens.map(&:lexeme)

      expect(lexemes).to eq(["ᚠ", "'", "ᚢ"])
    end

    it "recognizes a complete punctuation pair atomically" do
      page = Primus::Page.new(data: "ᚠ᛫᛬ᚢ")
      lexer = Primus::Lexer.build(page: page)

      lexer.tokenize
      lexemes = lexer.transcription.tokens.map(&:lexeme)

      expect(lexemes).to eq(["ᚠ", "᛫᛬", "ᚢ"])
    end

    it "preserves the reverse punctuation pair atomically" do
      page = Primus::Page.new(data: "ᚠ᛬᛫ᚢ")
      lexer = Primus::Lexer.build(page: page)

      lexer.tokenize
      lexemes = lexer.transcription.tokens.map(&:lexeme)

      expect(lexemes).to eq(["ᚠ", "᛬᛫", "ᚢ"])
    end

    it "does not consume a rune after a standalone punctuation mark" do
      page = Primus::Page.new(data: "ᚠ᛫ᚢ᛫")
      lexer = Primus::Lexer.build(page: page)

      lexer.tokenize
      tokens = lexer.transcription.tokens.map { |token|
        [token.lexeme, token.kind, token.source_location.rune_index]
      }

      expect(tokens).to eq(
        [["ᚠ", :rune, 0], ["᛫", :punctuation, nil],
         ["ᚢ", :rune, 1], ["᛫", :punctuation, nil]],
      )
    end

    it "captures unsupported characters without inventing GP membership" do
      page = Primus::Page.new(data: "ᚠ?ᚡ🙂")
      lexer = Primus::Lexer.build(page: page)

      lexer.tokenize
      tokens = lexer.transcription.tokens.map { |token|
        [token.lexeme, token.kind, token.source_location.rune_index]
      }

      expect(tokens).to eq(
        [["ᚠ", :rune, 0], ["?", :unrecognized, nil],
         ["ᚡ", :unrecognized, nil], ["🙂", :unrecognized, nil]],
      )
    end

    it "preserves Latin case and punctuation during reconstruction" do
      page = Primus::Page.new(data: "A,b;C")
      lexer = Primus::Lexer.build(page: page, strategy: :latin)

      lexer.tokenize
      body = lexer.transcription.tokens.map(&:lexeme).join

      expect(body).to eq("A,b;C")
    end

    it "recognizes mixed-case Latin multiletter symbols" do
      page = Primus::Page.new(data: "ThING")
      lexer = Primus::Lexer.build(page: page, strategy: :latin)

      lexer.tokenize
      tokens = lexer.transcription.tokens.map { |token|
        location = token.source_location
        [token.lexeme, location.character_start, location.character_end,
         location.byte_start, location.byte_end, location.rune_index]
      }

      expect(tokens).to eq([["Th", 0, 2, 0, 2, nil], ["ING", 2, 5, 2, 5, nil]])
    end

    it "retains mixed line endings and whitespace without normalization" do
      page = Primus::Page.new(data: "ᚠ\r\n\t \rᚢ\n\n")
      lexer = Primus::Lexer.build(page: page)

      lexer.tokenize
      lexemes = lexer.transcription.tokens.map(&:lexeme)

      expect(lexemes).to eq(["ᚠ", "\r\n", "\t", " ", "\r", "ᚢ", "\n", "\n"])
    end

    it "distinguishes byte spans from character spans across CRLF" do
      page = Primus::LiberPrimus::Page.new(number: 55, data: "ᚠ-ᚢ\r\nA")
      lexer = Primus::Lexer.build(page: page)

      lexer.tokenize
      coordinates = lexer.transcription.tokens.map { |token|
        location = token.source_location
        [location.byte_start, location.byte_end,
         location.character_start, location.character_end,
         location.line, location.column, location.rune_index]
      }

      expect(coordinates).to eq(
        [[0, 3, 0, 1, 0, 0, 0], [3, 4, 1, 2, 0, 1, nil],
         [4, 7, 2, 3, 0, 2, 1], [7, 9, 3, 5, 0, 3, nil],
         [9, 10, 5, 6, 1, 0, nil]],
      )
    end

    it "keeps source coordinates despite legacy delimiter tracking" do
      page = Primus::Page.new(data: "ᚠ-ᚢ")
      lexer = Primus::Lexer.build(page: page, track_delimiters: true)

      lexer.tokenize
      location = lexer.transcription.tokens.last.source_location

      expect(location).to have_attributes(
        byte_start: 4, byte_end: 7, character_start: 2, character_end: 3,
        rune_index: 1, line: 0, column: 2
      )
    end
  end
end
