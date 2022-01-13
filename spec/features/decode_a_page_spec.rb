RSpec.describe "decode a page" do
  it "page 56" do
    page = Primus::LiberPrimus::Page.open(page_number: 56)
    strategy = Primus::TotientShift.build
    translator = Primus::Translator.build(page: page, strategy: strategy)

    translator.translate

    expect(translator.result.to_s).to eq(page56_decoded_text)
  end

  def page56_decoded_text
    Primus::LiberPrimus::Page.open(page_number: 56, encoded: false).to_s
  end
end
