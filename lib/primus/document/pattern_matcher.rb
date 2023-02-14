class Primus::Document::PatternMatcher
  attr_accessor :current_match
  attr_reader :pattern, :results

  def initialize(pattern:, matching: false, current_index: 0)
    @pattern = pattern
    @matching = matching
    @results = []
    @current_match = []
    @current_index = current_index
  end

  def matching?
    @matching
  end

  def visit_word(word)
    if matching?
      track_match(word)
    end

    if !matching?
      track_first_match(word)
    end
  end

  def visit_token(token)
    token
  end

  protected

  attr_accessor :current_index

  def track_first_match(word)
    return unless word.size == pattern[0]
    start_matching
    self.current_match << word
  end

  def track_match(word)
    if word.size == pattern[current_index]
      self.current_match << word
      self.current_index += 1
      store_valid_match
    else
      stop_matching
    end
  end

  def store_valid_match
    return unless current_index >= pattern.size
    self.results << current_match
    stop_matching
  end

  def start_matching
    self.current_index = 1
    self.current_match = []
    @matching = true
  end

  def stop_matching
    self.current_index = 0
    self.current_match = []
    @matching = false
  end
end
