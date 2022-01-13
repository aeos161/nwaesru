RSpec.describe "decode a page" do
  it "page 56" do
    page = Primus::LiberPrimus::Page.open(page_number: 56)
    strategy = Primus::TotientShift.build
    translator = Primus::LiberPrimus::Translator.build(page: page,
                                                       strategy: strategy)

    translator.translate

    expect(translator.result.to_s).to eq(page56_decoded_text)
  end

  def page56_decoded_text
    text = <<~TEXT
an end within the deep web th
ere exists a page that ha
shes to
36367763ab73783c7af284446c
59466b4cd653239a311cb7116
d4618dee09a8425893dc7500b
464fdaf1672d7bef5e891c6e227
4568926a49fb4f45132c2a8b4
it is the duty of euery pilgr
im to seec out this page
    TEXT
    text.rstrip
  end
end
