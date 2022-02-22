RSpec.describe "investigation" do
  xit "analyzes the red words" do
    path = "data/encoded/liber_primus/red_words.yml"
    data = Psych.safe_load(File.read(path))["body"]
    phrases = data.map do |phrase|
      lexer = Primus::Lexer.new(data: phrase.to_s)
      lexer.tokenize
      parser = Primus::Parser.new(tokens: lexer.tokens)
      parser.parse
      parser.result
    end

    phrases = phrases.map do |phrase|
      phrase.accept(Primus::Document::Translator.new)
    end

    phrases.each.with_index do |phrase, index|
      word_sums = phrase.map(&:sum).reject(&:zero?)
      total_sum = word_sums.sum

      puts "#{index}: #{phrase.to_s(:rune)} #{phrase.to_s(:letter)} x: #{word_sums.join(',')} - #{word_sums.map(&:prime?)} - #{total_sum} - #{total_sum.prime?}"
    end
  end

  xit "investigate pages 54 and 55" do
    document = Primus::LiberPrimus.chapter(page_numbers: 54..55)
    document = document.accept(Primus::Document::Translator.new)
    wordA = document.words[0]
    wordB = document.words[1]

    word0 = create_word(%w(s h a d o w s))
    word1 = create_word(%w(u o i d))
    word2 = create_word(%w(f o r m))
    word3 = create_word(%w(u o i d))
    word4 = create_word(%w(c a b a l))

    word5 = create_word(%w(ae th e r ea l))
    word6 = create_word(%w(b u f f e r s))
    word7 = create_word(%w(u o i d))
    word8 = create_word(%w(c a r n a l))
  end

  xit "investigate pages 0 to 3" do
    document = Primus::LiberPrimus.chapter(page_numbers: 0..2)
    document = document.accept(Primus::Document::Translator.new)
    #analysis = Primus::Document::Analyzer.new(document: document)
    #analysis.analyze
    #puts document.index_of_coincidence
    #puts document.character_count
    #puts document.to_s
    puts analysis

    #processor = Primus::Processor::Affine.new
    #processor.process(document: document)
    #printer = Primus::Processor::Printer.new(processor: processor)
    #printer.print

    keys = [
      %w(r a s p u t i n),
      %w(p i l g r i m),
      %w(s t r a n n i c),
      %w(c w o r f r u r r u g f n g),
      %w(c w o r f r x r u g f n g),
      %w(c w o r f r u r r t f n g),
      %w(e t y i a y eo n),
      %w(m e s u s o t),
      %w(r u s s i a n o r th o d o x),
      %w(o r th o d o x),
      %w(o r th o g o n a l),
    ]
    processor = Primus::Processor::Vigenere.new(keys: keys, iterations: 8)
    processor.process(document: document)
    printer = Primus::Processor::Printer.new(processor: processor)
    printer.print

    #key = %w(e t y i a y eo n)
    #key = %w(m e s u s o t)
    #key = %w(r u s s i a n o r th o d o x)
    #key1 = %w(g oe d e l)
    #key2 = %w(e s c h e r)
    #key3 = %w(b a c h)
    #vigenere = Primus::Document::Vigenere.new(key: key1)
    #result = document.accept(vigenere)
    #puts result.to_s
    #vigenere = Primus::Document::Vigenere.new(key: key2, direction: :+)
    #result = document.accept(vigenere)
    #puts result.to_s
    #vigenere = Primus::Document::Vigenere.new(key: key3)
    #result = document.accept(vigenere)
    #puts result.to_s
  end

  xit "investigate pages 54 and 55" do
    gematria = Primus::GematriaPrimus.build
    alphabet = Primus::LatinAlphabet.build
    document = Primus::LiberPrimus.chapter(page_numbers: 54..55)

    document = document.accept(Primus::Document::Translator.new)
    puts document.index_of_coincidence
    puts document.to_s

    #csv =[]
    #document.text.each do |tx|
    #  if tx.is_a? Primus::Token
    #    csv << tx.to_s(:letter)
    #  else
    #    tx.tokens.each do |tk|
    #      csv << tk.to_s(:letter)
    #    end
    #  end
    #end

    processor = Primus::Processor::Affine.new(keys: -29..29, magnitudes: -29..29)
    processor.process(document: document)
    printer = Primus::Processor::Printer.new(processor: processor)
    printer.print

    characters = document.tokens
    ct = characters.map(&:letter)
    puts ct.join

    xor = Proc.new { |a, b| a ^ b }
    cxor = Proc.new { |a, b| (a.ord ^ b.ord) }
    cxor29 = Proc.new { |a, b| (a.ord ^ b.ord)  % 29 }

    n = 3
    r = []
    l = []

    r[n + 1] = ct[0..(ct.size/2)-1]
    l[n + 1] = ct[ct.size/2..ct.size]

    n.downto(0).each do |i|
      r[i] = l[i + 1]
      l[i] = r[i + 1].zip(l[i + 1]).map(&cxor)
    end

    pt = l[0] + r[0]

    puts pt.map { |c| gematria.find_by(index: c % 29) }.map(&:letter).join

    rb = []
    lb = []

    ctb = ct.join.unpack("b*").first.split("").map(&:to_i)
    rb[n + 1] = ctb[0..(ctb.size/2)-1]
    lb[n + 1] = ctb[ctb.size/2..ctb.size]

    n.downto(0).each do |i|
      rb[i] = lb[i + 1]
      lb[i] = rb[i + 1].zip(lb[i + 1]).map(&xor)
    end

    ptb = lb[0] + rb[0]
    ptg = ptb.to_enum.each_slice(8).map { |bits| bits.join.to_i(2) }

    puts ptg.map { |c| gematria.find_by(index: c % 29) }.map(&:letter).join
  end

  xit "investigate pages 3 to 7" do
    document = Primus::LiberPrimus.chapter(page_numbers: 3..7)

    translation = document.accept(Primus::Document::Translator.new)
    #result = translation.accept(totient)

    #expect(result.to_s).to eq(page56_decoded_text)
  end

  xit "can do a fibonacci shift on page 3" do
    page = Primus::LiberPrimus::Page.open(page_number: 3)
    strategy = Primus::FibonacciShift.build
    translator = Primus::Translator.build(page: page, strategy: strategy)

    translator.translate

    expect(translator.result.to_s).to eq("")
  end

  xit "can subtract gp words" do
    alphabet = Primus::GematriaPrimus.build
    l = alphabet.find_by(letter: "l")
    b = alphabet.find_by(letter: "b")
    r = alphabet.find_by(letter: "r")
    m = alphabet.find_by(letter: "m")
    s = alphabet.find_by(letter: "s")
    a = alphabet.find_by(letter: "a")
    c = alphabet.find_by(letter: "c")
    e = alphabet.find_by(letter: "e")
    t = alphabet.find_by(letter: "t")

    a_factor_l = a.factors(l)
    a_factor_m = a.factors(m)
    a_factor_b = a.factors(b)
    a_factor_s = a.factors(s)

    e_factor_b = e.factors(b)
    e_factor_s = e.factors(s)

    t_factor_s = t.factors(s)
  end
end
