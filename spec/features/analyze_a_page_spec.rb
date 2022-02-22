RSpec.describe "analyze a page" do
  it "counts the number of words" do
    document = Primus::LiberPrimus.page(page_number: 57)

    expect(document.word_count).to eq(20)
  end

  it "counts the number of characters" do
    document = Primus::LiberPrimus.page(page_number: 57)
    result = document.accept(Primus::Document::Translator.new)

    expect(result.character_count).to eq(95)
  end

  it "gets a token location" do
    document = Primus::LiberPrimus.page(page_number: 57)

    expect(document[25].lexeme).to eq("ᛝ")
    expect(document[25].location).to eq(
      Primus::Token::Location.new(line: 1, position: 25)
    )
  end
end
