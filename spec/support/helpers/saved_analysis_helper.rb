require "digest"
require "fileutils"
require "json"

module SavedAnalysisHelper
  GP_ALPHABET = %w[ᚠ ᚢ ᚦ ᚩ ᚱ ᚳ ᚷ ᚹ ᚻ ᚾ ᛁ ᛄ ᛇ ᛈ ᛉ ᛋ ᛏ ᛒ ᛖ ᛗ ᛚ ᛝ ᛟ ᛞ ᚪ ᚫ ᚣ ᛡ ᛠ].freeze
  GP_EXPANSIONS = %w[f u th o r c g w h n i j eo p x s t b e m l ng oe d a ae y io ea].freeze

  def independent_three_rune_observation(root, runes: %w[ᚦ ᚪ ᚦ],
                                         letters: %w[th a th], output: "thath")
    id = "tiny-final"
    run_id = "20261009T000000-000000000001"
    directory = File.join(root, id, run_id)
    FileUtils.mkdir_p(directory)
    rows = runes.each_with_index.map do |rune, index|
      { "ordinal" => index, "rune" => rune, "decoded_rune" => rune,
        "latin" => letters.fetch(index), "page_number" => 57,
        "occurrence" => 0, "byte_start" => index * 3,
        "byte_end" => (index + 1) * 3, "character_start" => index,
        "character_end" => index + 1, "line" => 0,
        "column" => index, "rune_index" => index }
    end
    provenance = JSON.pretty_generate(rows)
    output_digest = Digest::SHA256.hexdigest(output)
    provenance_digest = Digest::SHA256.hexdigest(provenance)
    File.binwrite(File.join(directory, "output.txt"), output)
    File.binwrite(File.join(directory, "provenance.json"), provenance)
    common = { "schema_version" => 1, "stage" => "final",
               "artifact" => "provenance.json", "symbol_field" => "decoded_rune",
               "output_sha256" => output_digest,
               "provenance_sha256" => provenance_digest }
    profiles = {
      "gp-runes-v1" => common.merge("alphabet" => GP_ALPHABET,
                                    "sample_size" => runes.size),
      "gp-expanded-latin-v1" => common.merge(
        "alphabet" => ("a".."z").to_a, "sample_size" => letters.join.length,
        "expansion_map" => GP_ALPHABET.zip(GP_EXPANSIONS).to_h,
      ),
    }
    record = {
      "schema_version" => 2, "experiment_id" => id, "run_id" => run_id,
      "status" => "completed", "completed_at" => "2026-10-09T00:00:00Z",
      "configuration" => { "output" => { "policy" => "gp-latin-compatibility-v1" } },
      "observation" => { "output_bytes" => output.bytesize,
                         "representations" => profiles },
      "artifacts" => {
        "output.txt" => { "path" => File.join(directory, "output.txt"),
                          "bytes" => output.bytesize, "sha256" => output_digest },
        "provenance.json" => { "path" => File.join(directory, "provenance.json"),
                               "bytes" => provenance.bytesize,
                               "sha256" => provenance_digest },
      },
    }
    File.write(File.join(directory, "record.json"), JSON.pretty_generate(record))
    [id, run_id]
  end
end
