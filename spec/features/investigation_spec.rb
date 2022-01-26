RSpec.describe "investigation" do
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

    binding.pry

  end
end
