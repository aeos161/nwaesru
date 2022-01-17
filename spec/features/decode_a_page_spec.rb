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
    pending
    fail

    8.upto(14) do |n|
      page = Primus::LiberPrimus::Page.open(page_number: n)
      strategy = Primus::AlternatingShift.build
      translator = Primus::Translator.build(page: page, strategy: strategy)
      doc = translator.document
      binding.pry
      puts "PAGE: #{n}"
      puts "WORDS: #{doc.word_count}"
      puts "CHARS: #{doc.token_count}"
      puts doc.token_count / doc.word_count.to_f
      puts "----"
    end

    translator.translate

    expect(translator.result.to_s).to eq("")
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
