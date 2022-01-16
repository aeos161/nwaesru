RSpec.describe "analyze a page" do
  it "counts the number of words" do
    page = Primus::LiberPrimus::Page.open(page_number: 57)
    lexer = Primus::Lexer.new(data: page.data)
    lexer.tokenize
    parser = Primus::Parser.new(tokens: lexer.tokens)
    parser.parse

    document = parser.result

    expect(document.word_count).to eq(20)
  end

  it "counts the number of characters" do
    page = Primus::LiberPrimus::Page.open(page_number: 57)
    lexer = Primus::Lexer.new(data: page.data)
    lexer.tokenize
    parser = Primus::Parser.new(tokens: lexer.tokens)
    parser.parse

    document = parser.result

    expect(document.character_count).to eq(95)
  end

  it "gets a token location" do
    page = Primus::LiberPrimus::Page.open(page_number: 57)
    lexer = Primus::Lexer.new(data: page.data)
    lexer.tokenize
    parser = Primus::Parser.new(tokens: lexer.tokens)
    parser.parse

    document = parser.result

    expect(document[25].lexeme).to eq("ᛝ")
    expect(document[25].location).to eq(
      Primus::Token::Location.new(line: 1, position: 25)
    )
  end
end
