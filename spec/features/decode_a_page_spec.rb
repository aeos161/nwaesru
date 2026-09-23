RSpec.describe "decode a page" do
  it "can decode a running key cipher" do
    document = Primus::LiberPrimus.page(page_number: 56)
    totient = Primus::Document::TotientShift.new
    totient.skip_sequence = [56]

    translation = document.accept(Primus::Document::Translator.new)
    result = translation.accept(totient)

    expect(result.to_s).to eq(decoded_fixture(56))
  end

  it "can decode an atbash cipher" do
    document = Primus::LiberPrimus.page(page_number: "warning")

    translation = document.accept(Primus::Document::Translator.new)
    result = translation.accept(Primus::Document::Atbash.new)

    expect(result.to_s).to eq(decoded_fixture("warning"))
  end

  it "can translate runes" do
    document = Primus::LiberPrimus.page(page_number: "know_this")

    result = document.accept(Primus::Document::Translator.new)

    expect(result.to_s).to eq(decoded_fixture("know_this"))
  end

  it "decodes the welcome pages with vigenere" do
    document = Primus::LiberPrimus.page(page_number: ["welcome", "welcome_2"])
    key = "diuinity"
    skip_sequence = [48, 74, 84, 132, 159, 160, 250, 421, 443, 465, 514]
    vigenere = Primus::Document::Vigenere.new(key: key)
    vigenere.skip_sequence = skip_sequence

    translation = document.accept(Primus::Document::Translator.new)
    result = translation.accept(vigenere)

    expect(result.to_s).to eq(
      "#{decoded_fixture("welcome")}\n#{decoded_fixture("welcome_2")}",
    )
  end

  it "decodes pages 107 and 167 with vigenere" do
    document = Primus::LiberPrimus.page(page_number: [107, 167])
    key = "firfumferenfe"
    skip_sequence = [49, 58]
    vigenere = Primus::Document::Vigenere.new(key: key)
    vigenere.skip_sequence = skip_sequence

    translation = document.accept(Primus::Document::Translator.new)
    result = translation.accept(vigenere)

    expect(result.to_s).to eq(
      "#{decoded_fixture(107)}\n#{decoded_fixture(167)}",
    )
  end

  it "translates page 229 directly" do
    document = Primus::LiberPrimus.page(page_number: 229)

    result = document.accept(Primus::Document::Translator.new)

    expect(result.to_s).to eq(decoded_fixture(229))
  end

  it "translates page 57 directly" do
    document = Primus::LiberPrimus.page(page_number: 57)

    result = document.accept(Primus::Document::Translator.new)

    expect(result.to_s).to eq(decoded_fixture(57))
  end

  def decoded_fixture(page_number)
    path = "data/decoded/liber_primus/page_#{page_number}.yml"
    Psych.safe_load(File.read(path))["body"].rstrip
  end
end
