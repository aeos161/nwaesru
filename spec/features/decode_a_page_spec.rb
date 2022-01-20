RSpec.describe "decode a page" do
  it "can decode a running key cipher" do
    document = Primus::LiberPrimus.page(page_number: 56)
    totient = Primus::Document::TotientShift.new
    totient.skip_sequence = [57]

    translation = document.accept(Primus::Document::Translator.new)
    result = translation.accept(totient)

    expect(result.to_s).to eq(page56_decoded_text)
  end

  it "can decode an atbash cipher" do
    document = Primus::LiberPrimus.page(page_number: "warning")

    translation = document.accept(Primus::Document::Translator.new)
    result = translation.accept(Primus::Document::Atbash.new)

    expect(result.to_s).to eq(warning_decoded_text)
  end

  it "can decode a vigenere cipher" do
    document = Primus::LiberPrimus.page(page_number: "welcome")
    key = "diuinity"
    skip_sequence = [49, 75, 85, 133, 160, 161, 251]
    vigenere = Primus::Document::Vigenere.new(key: key)
    vigenere.skip_sequence = skip_sequence

    translation = document.accept(Primus::Document::Translator.new)
    result = translation.accept(vigenere)

    expect(result.to_s).to eq(welcome_decoded_text)
  end

  it "can do a direct rune to letter translation on page 57" do
    document = Primus::LiberPrimus.page(page_number: 57)

    result = document.accept(Primus::Document::Translator.new)

    expect(result.to_s).to eq(page57_decoded_text)
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

  def welcome_decoded_text
    Primus::LiberPrimus::Page.open(page_number: "welcome", encoded: false).to_s
  end
end
