class Primus::Document::Builder
  attr_reader :pages, :result

  def initialize(pages: [])
    @pages = Array(pages)
    @result = Primus::Document.new
    @first_word = Primus::Word.new
    @position = 0
  end

  def build
    pages.each { |page| build_page(page) }
  end

  def build_page(page)
    lexer = Primus::Lexer.build(page: page, starting_position: position)
    lexer.tokenize
    parser = Primus::Parser.new(tokens: lexer.tokens, document: result,
                                first_word: first_word)
    parser.parse
    @position = lexer.position
    @first_word = parser.last_word
  end

  def self.for_pages(page_numbers: [])
    page_numbers = Array(page_numbers)
    pages = page_numbers.map do |page_number|
      Primus::LiberPrimus::Page.open(page_number: page_number)
    end
    new(pages: pages)
  end

  protected

  attr_reader :position, :first_word
end
