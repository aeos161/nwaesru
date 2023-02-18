class Primus::Commands::Files < Primus::Commands::SubCommandBase
  desc "flip", "Flip all the bits of a binary file"
  def flip(file_name)
    File.open(file_name, "rb") do |file|
      result = file.read.bytes.map do |byte|
        byte.to_s(2).split("").map(&:to_i).map { |bit| bit ^ 1 }
      end
      print result.map(&:join).map { |byte| byte.to_i(2) }.pack("C*")
    end
  end

  desc "reverse", "Reverse every byte of a file"
  option :encoding, type: :string, default: :binary
  def reverse(file_name)
    File.open(file_name, "rb") do |file|
      data = file.read
      case options[:encoding].to_sym
      when :hex
        print data.scan(/../).reverse.join("")
      else
        print data.gsub(/\n/, "").to_i.to_s(2).reverse
      end
    end
  end

  desc "xor", "XOR two files"
  def xor(file_a, file_b)
    File.open(file_a, "rb") do |file_a|
      File.open(file_b, "rb") do |file_b|
        bytes_a = file_a.read.bytes
        bytes_b = file_b.read.bytes
        result = bytes_a.enum_for(:each_with_index).map do |byte, index|
          byte ^ bytes_b[index]
        end
        print result.pack("C*")
      end
    end
  end
end
