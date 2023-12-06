class Primus::Token::NoLocation < Primus::Token::Location
  def initialize(line:, _position: nil, length: 1)
    super(line: line, position: nil, length: length)
  end
end
