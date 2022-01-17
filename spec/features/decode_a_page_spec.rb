RSpec.describe "decode a page" do
  it "can use a totient shift on page 56" do
    page = Primus::LiberPrimus::Page.open(page_number: 56)
    strategy = Primus::TotientShift.build
    translator = Primus::Translator.build(page: page, strategy: strategy)

    translator.translate

    expect(translator.result.to_s).to eq(page56_decoded_text)
  end

  it "can use a gematria shift on a warning" do
    page = Primus::LiberPrimus::Page.open(page_number: "warning")
    strategy = Primus::GematriaShift.build
    translator = Primus::Translator.build(page: page, strategy: strategy)

    translator.translate

    expect(translator.result.to_s).to eq(warning_decoded_text)
  end

  it "can do a direct rune to letter translation on page 57" do
    page = Primus::LiberPrimus::Page.open(page_number: 57)
    strategy = Primus::RuneToLetter.build
    translator = Primus::Translator.build(page: page, strategy: strategy)

    translator.translate

    expect(translator.result.to_s).to eq(page57_decoded_text)
  end

  it "can do a fibonacci shift on page 3" do
    pending
    fail

    page = Primus::LiberPrimus::Page.open(page_number: 3)
    strategy = Primus::FibonacciShift.build
    translator = Primus::Translator.build(page: page, strategy: strategy)

    translator.translate

    expect(translator.result.to_s).to eq("")
  end

  it "can do an alternating shift on page 8" do
    document = Primus::Document.new
    first_word = Primus::Word.new
    position = 0

    8.upto(14) do |n|
      page = Primus::LiberPrimus::Page.open(page_number: n)

      lexer = Primus::Lexer.build(page: page, starting_position: position)
      lexer.tokenize

      parser = Primus::Parser.new(tokens: lexer.tokens, document: document,
                                  first_word: first_word)
      parser.parse

      position = lexer.position
      first_word = parser.last_word

      #strategy = Primus::AlternatingShift.build
      #translator = Primus::Translator.build(page: page, strategy: strategy)
      #doc = translator.document
      #binding.pry
      #puts "PAGE: #{n}"
      #puts "WORDS: #{doc.word_count}"
      #puts "CHARS: #{doc.token_count}"
      #puts doc.token_count / doc.word_count.to_f
      #puts "----"
    end

    token274 = document[274]
    token501 = document[501]
    token554 = document[554]
    puts "274: #{token274.inspect}"
    puts "501: #{token501.inspect}"
    puts "554: #{token554.inspect}"

    puts token501.location - token274.location
    puts token554.location - token501.location
    puts token554.location - token274.location

    visitor = Primus::Document::Filter.new(character_to_reject: "ᛉ")
    new_doc = document.accept(visitor)
    binding.pry

    #translator.translate

    #expect(translator.result.to_s).to eq("")
  end

  def page56_decoded_text
    Primus::LiberPrimus::Page.open(page_number: 56, encoded: false).to_s
  end

  def page57_decoded_text
    Primus::LiberPrimus::Page.open(page_number: 57, encoded: false).to_s
  end

  def warning_decoded_text
    Primus::LiberPrimus::Page.open(page_number: "warning", encoded: false).to_s
  end
end
