class Primus::Document::CipherFactory
  attr_accessor :key, :skip_sequence, :name

  def initialize(name:)
    @name = name
  end

  def find
    cipher = initialize_cipher(name.to_sym)
    cipher.skip_sequence = skip_sequence
    cipher
  end

  protected

  def initialize_cipher(name)
    case name
    when :atbash
      Primus::Document::Atbash.new
    when :runes
      Primus::Document::Translator.new
    when :totient
      Primus::Document::TotientShift.new
    when :vigenere
      Primus::Document::Vigenere.new(key: key)
    else
      fail "No cipher decoder found for #{name}"
    end
  end
end
