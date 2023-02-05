class Primus::Word::Expander
  attr_reader :results, :method

  def initialize(method: :letter)
    @method = method
    @results = [Primus::Word.new]
  end

  def visit_word(word)
    word.tokens.map { |tk| visit_token(tk) }
    stringify = Proc.new do |word|
      word.tokens.map { |tk| tk.to_s(method) }.join
    end
    @results = results.map(&stringify)
  end

  def visit_token(token)
    expand_results_for(token)
    letters = extract_letters_from(token)
    results.each do |word|
      word << letters.next
    end
  end

  protected

  def expand_results_for(token)
    return unless method == :letter
    return unless token.respond_to? :alt?
    return unless token.alt?
    expanded = []
    results.each do |word|
      expanded << Primus::Word.new(tokens: word.tokens.dup)
    end
    @results = (results + expanded).sort
  end

  def extract_letters_from(token)
    if method == :letter && token.alt?
      alt_token = token.dup
      alt_token.letter = token.alt_letter
      [token, alt_token].sort.cycle(results.size / 2)
    else
      [token].cycle(results.size)
    end
  end
end
