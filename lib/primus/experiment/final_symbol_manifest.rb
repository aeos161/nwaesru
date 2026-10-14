class Primus::Experiment::FinalSymbolManifest
  def initialize(observation:, artifacts:)
    @observation, @artifacts = observation, artifacts
  end

  def to_h
    { "gp-runes-v1" => profile(Primus::Analysis::RUNES, rune_count),
      "gp-expanded-latin-v1" => profile(Primus::Analysis::LATIN, latin_count).
        merge("expansion_map" => Primus::Analysis::MAP) }
  end

  private

  def profile(alphabet, size)
    { "schema_version" => 1, "stage" => "final", "artifact" => "provenance.json",
      "symbol_field" => "decoded_rune", "alphabet" => alphabet,
      "sample_size" => size,
      "output_sha256" => @artifacts.fetch("output.txt").fetch("sha256"),
      "provenance_sha256" => @artifacts.fetch("provenance.json").fetch("sha256") }
  end

  def rune_count
    @observation.provenance.size
  end

  def latin_count
    @observation.provenance.sum { |row| Primus::Analysis::MAP.fetch(row.fetch("decoded_rune")).size }
  end
end
