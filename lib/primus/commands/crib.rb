class Primus::Commands::Crib < Primus::Commands::SubCommandBase
  desc "generate", "Generate a key to satisfy cipher text"
  option :cipher_text, type: :string, required: true
  option :plain_text, type: :string, required: true, repeatable: true
  def generate
    plain_text_options = Primus.parse(options[:plain_text])
    cipher_text = Primus.parse(options[:cipher_text]).first
    plain_text_options.each do |plain_text|
      key = cipher_text - plain_text
      puts "#{cipher_text.to_s(:letter)} to #{plain_text.to_s(:letter)} => Key: #{key.to_s(:letter)}"
    end
  end
end