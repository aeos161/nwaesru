RSpec.describe "investigation" do
  it "can do a fibonacci shift on page 3" do
    pending
    fail

    page = Primus::LiberPrimus::Page.open(page_number: 3)
    strategy = Primus::FibonacciShift.build
    translator = Primus::Translator.build(page: page, strategy: strategy)

    translator.translate

    expect(translator.result.to_s).to eq("")
  end
end
