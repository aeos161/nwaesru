require "json"
require "digest"

class Primus::Analysis::ICReferencePacket
  PATH = File.expand_path("../../../data/analysis/solved_gp_english_controls_v1.json", __dir__).freeze
  SHA256 = "8fb65e981bcface2be67259544a49bcd0cc6c3119bcb6c826dac7785de40201c".freeze

  def initialize(path: PATH)
    @path = path
  end

  def for_representation(name)
    bytes = File.binread(@path)
    raise ArgumentError, "English control packet digest mismatch" unless Digest::SHA256.hexdigest(bytes) == SHA256
    packet = JSON.parse(bytes)
    raise ArgumentError, "invalid English control packet" unless valid_packet?(packet)
    representation = packet.fetch("representations").fetch(name)
    representation.merge("id" => packet.fetch("id"),
      "provenance_digest" => packet.fetch("provenance_digest"),
      "source_description" => packet.fetch("source_description"))
  end

  private

  def valid_packet?(packet)
    return false unless packet["id"] == "solved-gp-english-controls-v1"
    return false unless packet["provenance_digest"].to_s.match?(/\A[0-9a-f]{64}\z/)
    return false unless packet["source_description"].is_a?(String)

    packet["representations"].is_a?(Hash) &&
      Primus::Analysis::REPRESENTATIONS.all? { |name| valid_representation?(packet["representations"][name], name) }
  end

  def valid_representation?(item, name)
    return false unless item.is_a?(Hash) && item["representation"] == name
    expected_size = name == "gp-runes-v1" ? 29 : 26
    return false unless item["uniform"] == { "numerator" => 1, "denominator" => expected_size }

    controls = item["controls"]
    controls.is_a?(Array) && controls.map { |control| control["id"] } == %w[page-56 page-57] &&
      controls.all? { |control| valid_control?(control) }
  end

  def valid_control?(control)
    size = control["sample_size"]
    size.is_a?(Integer) && size >= 2 &&
      control["denominator"] == size * (size - 1) &&
      control["numerator"].is_a?(Integer) &&
      control["numerator"].between?(0, control["denominator"])
  end
end
