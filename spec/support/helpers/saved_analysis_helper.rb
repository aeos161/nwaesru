require "digest"
require "fileutils"
require "json"
require "securerandom"

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
    source_body = runes.join
    source = Psych.dump("body" => source_body)
    source_path = File.join(directory, "source.yml")
    File.binwrite(source_path, source)
    File.binwrite(File.join(directory, "source-body.txt"), source_body)
    source_identity = { "path" => source_path,
                        "sha256" => Digest::SHA256.hexdigest(source) }
    original_id = SecureRandom.uuid
    final_id = SecureRandom.uuid
    coordinates = %w[page_number occurrence byte_start byte_end character_start
                     character_end line column rune_index]
    symbol_rows = rows.map { |row| row.slice("ordinal", "rune", "latin", *coordinates) }
    original_lexemes = rows.map do |row|
      { "lexeme" => row.fetch("rune"), "kind" => "rune",
        "rendering" => "retained", "output_byte_start" => row.fetch("byte_start"),
        "output_byte_end" => row.fetch("byte_end") }.merge(
          coordinates.to_h { |name| ["source_#{name}", row.fetch(name)] }
        )
    end
    cursor = 0
    final_lexemes = rows.map do |row|
      first = cursor
      cursor += row.fetch("latin").bytesize
      { "lexeme" => row.fetch("rune"), "kind" => "rune",
        "rendering" => "rendered", "output_byte_start" => first,
        "output_byte_end" => cursor }.merge(
          coordinates.to_h { |name| ["source_#{name}", row.fetch(name)] }
        )
    end
    checkpoint = lambda do |step_id, id_value, ordinal, parent_id, operation,
                            policy, representation, bytes, lexemes|
      checkpoint_directory = File.join(directory, "checkpoints", step_id)
      FileUtils.mkdir_p(checkpoint_directory)
      artifacts = { "output" => ["output.txt", bytes],
                    "symbols" => ["symbols.json", JSON.pretty_generate(symbol_rows)],
                    "lexemes" => ["lexemes.json", JSON.pretty_generate(lexemes)] }
      metadata = artifacts.transform_values do |filename, content|
        path = File.join(checkpoint_directory, filename)
        File.binwrite(path, content)
        { "path" => path, "bytes" => content.bytesize,
          "sha256" => Digest::SHA256.hexdigest(content) }
      end
      { "id" => id_value, "step_id" => step_id, "ordinal" => ordinal,
        "parent_id" => parent_id, "operation" => operation, "parameters" => {},
        "policy" => policy, "representation" => representation,
        "source" => source_identity }.merge(metadata)
    end
    checkpoints = [
      checkpoint.call("original", original_id, 0, nil, "capture",
                      "gp-runes-lossless-v1", "gp-runes", source_body,
                      original_lexemes),
      checkpoint.call("letters", final_id, 1, original_id, "latin",
                      "gp-latin-compatibility-v1", "latin", output,
                      final_lexemes),
    ]
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
      "configuration" => { "steps" => [{ "id" => "letters", "operation" => "latin",
                                        "parameters" => {} }],
                           "output" => { "policy" => "gp-latin-compatibility-v1" } },
      "source_path" => source_path,
      "source_actual_sha256" => source_identity.fetch("sha256"),
      "checkpoints" => checkpoints,
      "final_checkpoint_id" => final_id,
      "observation" => { "output_bytes" => output.bytesize,
                         "representations" => profiles },
      "artifacts" => {
        "source-body.txt" => { "path" => File.join(directory, "source-body.txt"),
                               "bytes" => source_body.bytesize,
                               "sha256" => Digest::SHA256.hexdigest(source_body) },
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
