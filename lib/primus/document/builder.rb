class Primus::Document::Builder
  attr_reader :pages, :result, :strategy, :transcription

  def initialize(pages: [], strategy: :runic, track_delimiters: false)
    @pages = Array(pages)
    @strategy = strategy
    @track_delimiters = track_delimiters
    @result = Primus::Document.new
  end

  def build
    sources = pages.each_with_index.map do |page, occurrence|
      lexer = Primus::Lexer.build(page: page, strategy: strategy,
                                  occurrence: occurrence)
      lexer.tokenize
      lexer.transcription
    end
    @transcription = Primus::Transcription.compose(sources)
    parser = Primus::Parser.new(transcription: transcription,
                                strategy: strategy,
                                track_delimiters: @track_delimiters)
    parser.parse
    @result = parser.result
  end

  def build_page(page)
    @pages = [page]
    build
  end

  def build_chapter(chapter_pages)
    @pages = Array(chapter_pages)
    build
  end

  def self.for_pages(page_numbers: [], strategy: :runic,
                     track_delimiters: false)
    pages = Array(page_numbers).map do |page_number|
      Primus::LiberPrimus::Page.open(page_number: page_number,
                                     character_set: strategy)
    end
    new(pages: pages, strategy: strategy, track_delimiters: track_delimiters)
  end
end
