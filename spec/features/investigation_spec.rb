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

  it "can do an affine cipher on page 8" do
    document = Primus::LiberPrimus.page(page_number: 8)

    filter = Primus::Document::Filter.new(character_to_reject: "ᛉ")
    filtered = document.accept(filter)
    translated = document.accept(Primus::Document::Translator.new)
    affine = Primus::Document::Affine.new(key: 26, magnitude: 9)
    result = translated.accept(affine)

    binding.pry
  end

  it "can do an alternating shift on page 8" do
    document = Primus::LiberPrimus.chapter(page_numbers: 8..14)

    token274 = document[274]
    token501 = document[501]
    token554 = document[554]
    token786 = document[786]
    puts "274: #{token274.inspect}"
    puts "501: #{token501.inspect}"
    puts "554: #{token554.inspect}"
    puts "786: #{token786.inspect}"

    #puts token501.location - token274.location
    #puts token554.location - token501.location
    puts token554.location - token274.location
    puts token786.location - token274.location
    puts token786.location - token554.location

    visitor = Primus::Document::Filter.new(character_to_reject: "ᛉ")
    new_doc = document.accept(visitor)
    #new_doc = document
    #binding.pry
    tokens = new_doc.words.flat_map(&:tokens).map.with_index do |tk, index|
      tk.location = Primus::Token::Location.new(position: index, line: 0)
      tk
    end
    #binding.pry

    visitor = Primus::Document::Translator.new
    new_doc2 = new_doc.accept(visitor)

    one_letter_words = new_doc2.words.select { |w| w.size == 1 }
    puts one_letter_words.map { |w| [w.to_s, w.first.location.position].join("|") }

    binding.pry
    keys = %w(diuinity mournful struggle discouer yourself rasputin)

    keys.each do |key|
      vigenere = Primus::Document::Vigenere.new(key: key)
      new_doc3 = new_doc2.accept(vigenere)

      puts "-----"
      puts new_doc3
      puts "-----"
    end

    #visitor = Primus::Document::ComplementShift.new
    #visitor = Primus::Document::TotientShift.new
    #visitor = Primus::Document::GematriaShift.new
    #visitor = Primus::Document::StreamCipher.new
    #visitor = Primus::Document::AlternatingShift.new
    #visitor = Primus::GematriaPrimus::Calculator.new
    #new_doc2.accept(visitor)

    #word = new_doc2.first
    #puts word.accept(visitor)

    #binding.pry

    #expect(result.to_s).to eq("")
  end


end
