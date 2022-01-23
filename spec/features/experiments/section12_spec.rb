RSpec.describe "section 12 experiments (pg 8 - 14)" do
  it "page level information" do
    (8..14).each do |n|
      document = Primus::LiberPrimus.page(page_number: n)
      puts "PAGE: #{n}"
      puts "WORDS: #{document.word_count}"
      puts "CHARACTERS: #{document.character_count}"

      filtered = document.accept(Primus::Document::Mask.new(mask: "1001"))
      puts "PAGE: #{n}"
      puts "WORDS: #{filtered.word_count}"
      puts "CHARACTERS: #{filtered.character_count}"
    end
  end

  it "chapter level information" do
    document = Primus::LiberPrimus.chapter(page_numbers: 8..14)
    puts "WORDS: #{document.word_count}"
    puts "CHARACTERS: #{document.character_count}"
    puts "1129: #{document[1129]}"

    alphabet = Primus::GematriaPrimus.build
    puts "ICex: #{alphabet.expected_index_of_coincidence}"
    ic_test = document.accept(Primus::Document::Translator.new)
    ic_test.index_of_coincidence
    puts "ICc: #{ic_test.index_of_coincidence}"

    filtered = document.accept(Primus::Document::Mask.new(mask: "1001"))
    puts "FWORDS: #{filtered.word_count}"
    puts "FTOKENS: #{filtered.character_count}"
    puts filtered.to_s #(:rune)

    filtered = filtered.accept(Primus::Document::Translator.new)
    puts "FCHARS: #{filtered.words.flat_map(&:tokens).map(&:letter).join.split("").size}"
    puts "ICf: #{filtered.index_of_coincidence}"

    slices = (1..100).map do |period|
      chars = filtered.words.flat_map(&:tokens)
      text = chars.map(&:letter).join.split("")
      if text.size % period != 0
        padding = (text.size / period.to_f).ceil
        1.upto((padding * period) - text.size) do
          text << "."
        end
      end
      text.each_slice(period).to_a.transpose.map(&:join)
    rescue => e
      puts e.inspect
      puts "didn't like #{period}"
    end

    slices.each.with_index do |slice, period|
      if !slice.nil?
        puts "PERIOD: #{period + 1}"
        ic = slice.map { |text| Primus.index_of_coincidence(text) }.sum / (period + 1).to_f
        puts "IC: #{ic}"
      end
    end

    #binding.pry

  end

  it "can xnor the text then brute force affine" do
    document = Primus::LiberPrimus.chapter(page_numbers: 8..14)
    #binding.pry

    filter = Primus::Document::Mask.new(mask: "1001")
    document = document.accept(filter)
    puts document.to_s(:rune)

    document = document.accept(Primus::Document::Translator.new)
    puts document.to_s
    #puts document.to_s.split(" ").join("-")
    #binding.pry

    if false
      (1..28).each do |letter|
        (1..28).each do |mg|
          begin
            pt = document.accept(Primus::Document::Affine.new(key: letter, magnitude: mg))
            puts "-----"
            puts "affine: [#{letter}, #{mg}]"
            puts "#{pt}"
            puts "-----"
          rescue => e
            puts e.message
          end
        end
      end
    end

    if false
      keys = [
        "diuinity", "mournful", "struggle", "discouer", "yourself", "rasputin",
        "circumference", "firfumferenfe", "forallissacred", "aethereal",
        %w(ae th e r ea l), %w(ae t h e r e a l), %w(ae th e r e a l),
        %w(ae t h e r ea l), %w(a e th e r e a l), %w(a e th e r ea l),
        "buffers", "uoid", "carnal", "mobius", "analog", "obscura", "cameraobscura",
        "form", "cabal", "command", "program", "unreasonable", "grigorirasputin",
        "consumption", %w(c o n s u m p t io n), "preseruation", %w(p r e s e r u a t io n),
        "adherence", "program", "programreality", "discouer", "enlightened",
        "youcantseetheforestwhenyoureloocingatthetrees",
        %w(y o u c a n t s e e th e f o r e s t w h e n y o u r e l o o c ng a t th e t r e e s)
      ]
      keys.each do |key|
        vigenere = Primus::Document::Vigenere.new(key: key)
        pt = document.accept(vigenere)

        puts "-----"
        puts "KEY: #{key}"
        puts pt
        puts "-----"
      end
    end
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

    #binding.pry
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

  def create_word(text)
    alphabet = Primus::GematriaPrimus.build
    tks = Array(text).map { |tk| alphabet.find_by(letter: tk) }
    Primus::Word.new(tokens: tks)
  end
end
