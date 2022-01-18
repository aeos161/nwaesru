RSpec.describe "decode a page" do
  it "can use a totient shift on page 56" do
    document = Primus::LiberPrimus.page(page_number: 56)

    translation = document.accept(Primus::Document::Translator.new)
    result = translation.accept(Primus::Document::TotientShift.new)

    expect(result.to_s).to eq(page56_decoded_text)
  end

  it "can use a gematria shift on a warning" do
    document = Primus::LiberPrimus.page(page_number: "warning")

    translation = document.accept(Primus::Document::Translator.new)
    result = translation.accept(Primus::Document::GematriaShift.new)

    expect(result.to_s).to eq(warning_decoded_text)
  end

  it "can do a direct rune to letter translation on page 57" do
    document = Primus::LiberPrimus.page(page_number: 57)

    result = document.accept(Primus::Document::Translator.new)

    expect(result.to_s).to eq(page57_decoded_text)
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
    document = Primus::LiberPrimus.chapter(page_numbers: 8..14)

    token274 = document[274]
    token501 = document[501]
    token554 = document[554]
    token786 = document[786]
    puts "274: #{token274.inspect}"
    puts "501: #{token501.inspect}"
    puts "554: #{token554.inspect}"
    puts "786: #{token786.inspect}"

    #puts token501.location - token274.location
    #puts token554.location - token501.location
    puts token554.location - token274.location
    puts token786.location - token274.location
    puts token786.location - token554.location

    #visitor = Primus::Document::Filter.new(character_to_reject: "ᛉ")
    #new_doc = document.accept(visitor)

    visitor = Primus::Document::Translator.new
    new_doc2 = document.accept(visitor)
    one_letter_words = new_doc2.words.select { |w| w.size == 1 }

    binding.pry

    #visitor = Primus::Document::ComplementShift.new
    #visitor = Primus::Document::TotientShift.new
    #visitor = Primus::Document::GematriaShift.new
    #visitor = Primus::Document::StreamCipher.new
    #visitor = Primus::Document::AlternatingShift.new
    visitor = Primus::GematriaPrimus::Calculator.new
    #new_doc2.accept(visitor)

    word = new_doc2.first
    puts word.accept(visitor)

    binding.pry

    #expect(result.to_s).to eq("")
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
