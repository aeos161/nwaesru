class Primus::LiberPrimus
  def self.page(page_number:)
    builder = Primus::Document::Builder.for_pages(page_numbers: page_number)
    builder.build
    builder.result
  end

  def self.chapter(page_numbers:)
    builder = Primus::Document::Builder.for_pages(page_numbers: page_numbers)
    builder.build
    builder.result
  end
end
