RSpec.describe "decode a page" do
  it "can use a totient shift on page 56" do
    page = Primus::LiberPrimus::Page.open(page_number: 56)
    strategy = Primus::TotientShift.build
    translator = Primus::Translator.build(page: page, strategy: strategy)

    translator.translate

    expect(translator.result.to_s).to eq(page56_decoded_text)
  end

  it "can do a direct rune to letter translation on page 57" do
    page = Primus::LiberPrimus::Page.open(page_number: 57)
    strategy = Primus::RuneToLetter.build
    translator = Primus::Translator.build(page: page, strategy: strategy)

    translator.translate

    expect(translator.result.to_s).to eq(page57_decoded_text)
  end

  def page56_decoded_text
    Primus::LiberPrimus::Page.open(page_number: 56, encoded: false).to_s
  end

  def page57_decoded_text
    Primus::LiberPrimus::Page.open(page_number: 57, encoded: false).to_s
  end
end
