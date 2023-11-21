class Primus::LiberPrimus
  def self.page(page_number:, strategy: :runic)
    builder = Primus::Document::Builder.for_pages(page_numbers: page_number,
                                                  strategy: strategy)
    builder.build
    builder.result
  end

  def self.chapter(page_numbers:, strategy: :runic)
    builder = Primus::Document::Builder.for_pages(page_numbers: page_numbers,
                                                  strategy: strategy)
    builder.build
    builder.result
  end
end
