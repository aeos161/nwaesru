class Primus::Experiment::Steps
  FIELDS = %w[id operation parameters].freeze
  TOTIENT_FIELDS = %w[modulus prime_start skip_sequence].freeze
  ATBASH = { "alphabet" => "gematria-primus", "modulus" => 29 }.freeze
  REVERSAL = { "scope" => "composed-input", "non_runes" => "fixed" }.freeze

  attr_reader :data

  def initialize(data, rune_count: nil)
    @data = data
    @rune_count = rune_count
  end

  def valid?
    return false unless data.is_a?(Array) && data.any?
    return false unless data.all? { |step| valid_step?(step) }
    ids = data.map { |step| step.fetch("id") }
    ids.uniq == ids && data.last["operation"] == "latin" &&
      data[0...-1].all? { |step| %w[totient atbash reverse-runes].include?(step["operation"]) }
  end

  def canonical
    data.map do |step|
      values = step.fetch("parameters").dup
      values["skip_sequence"] = values["skip_sequence"].sort if step["operation"] == "totient"
      step.merge("parameters" => values)
    end
  end

  private

  def valid_step?(step)
    return false unless step.is_a?(Hash) && step.keys.sort == FIELDS.sort
    return false unless step["id"].is_a?(String) && step["id"].match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
    return false if %w[original final].include?(step["id"])
    return false unless step["parameters"].is_a?(Hash)
    case step["operation"]
    when "latin" then step["parameters"].empty?
    when "atbash" then step["parameters"] == ATBASH && step["parameters"]["modulus"].instance_of?(Integer)
    when "reverse-runes" then step["parameters"] == REVERSAL
    when "totient" then valid_totient?(step)
    else false
    end
  end

  def valid_totient?(step)
    return false unless step["operation"] == "totient"
    values = step["parameters"]
    return false unless values.keys.sort == TOTIENT_FIELDS.sort
    return false unless values["modulus"] == 29 && values["modulus"].instance_of?(Integer)
    start = values["prime_start"]
    start.instance_of?(Integer) && start >= 2 && Prime.prime?(start) && valid_skips?(values["skip_sequence"])
  end

  def valid_skips?(skips)
    return false unless skips.is_a?(Array) && skips.uniq == skips
    skips.all? { |item| item.instance_of?(Integer) && item >= 0 &&
      (@rune_count.nil? || item < @rune_count) }
  end
end
