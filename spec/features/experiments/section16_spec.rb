RSpec.describe "section 16 experiments (pg 33)" do
  xit "chapter level information" do
    document = Primus::LiberPrimus.chapter(page_numbers: 33)
    translation = document.accept(Primus::Document::Translator.new)
  end

  xit "looks at pages 9, 1, and 33" do
    document = Primus::LiberPrimus.chapter(page_numbers: [9, 1, 33])
    translation = document.accept(Primus::Document::Translator.new)
    converter = Primus::Document::NgramConverter.new(document: translation)
    converter.convert
    bigrams = converter.result
  end

  xit "looks at pages 15 to 22" do
    alphabet = Primus::GematriaPrimus.build

    document = Primus::LiberPrimus.chapter(page_numbers: 15..22)
    translation = document.accept(Primus::Document::Translator.new)
    puts translation.to_s

    counter = Primus::Document::TokenCounter.new
    translation.accept(counter)
    puts "total letters: #{counter.size}"
    puts "monographic IC: #{translation.index_of_coincidence}"

    counter = Primus::Document::TokenCounter.new(length: 2)
    translation.accept(counter)
    puts "number of digraphs: #{counter.size}"
    puts "digraphic IC: #{translation.index_of_coincidence(length: 2)}"

    #total_digraphs = counter.size
    #c = (alphabet.size ** 2).to_f
    #denominator = (total_digraphs * (total_digraphs - 1)) / c
    #numerator = counter.result.sum do |row|
    #  row.reject(&:zero?).map { |f| f * (f - 1) }.sum
    #end
    #dioc = numerator / denominator
    #puts "digraphic IC: #{dioc}"

    #converter = Primus::Document::NgramConverter.new(document: translation, length: 2)
    #converter.convert
    #bigrams = converter.result
    #counts = bigrams.to_s.split(" ").reduce({}) { |m, k| m[k] ||= 0; m[k] += 1; m }
    #repeats = counts.select { |k, v| v > 1 }
    #puts repeats.sort { |x, y| y[1] <=> x[1] }.map { |k| k.join(",") }
  end
end
