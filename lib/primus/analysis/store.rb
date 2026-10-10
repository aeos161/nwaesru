require "fileutils"
require "securerandom"
require "time"

class Primus::Analysis::Store
  class Error < StandardError; end
  attr_reader :directory

  def initialize(directory:)
    @directory = directory
  end

  def reserve(data, definition_bytes)
    id = "#{Time.now.utc.strftime('%Y%m%dT%H%M%S')}-#{SecureRandom.hex(6)}"
    path = File.join(directory, "analyses", id)
    FileUtils.mkdir_p(File.dirname(path))
    Dir.mkdir(path)
    data["analysis_run_id"] = id
    File.binwrite(File.join(path, "definition.yml"), definition_bytes)
    write(path, data)
    id
  rescue SystemCallError => error
    raise Error, "could not persist analysis: #{error.message}"
  end

  def finish(id, data)
    write(File.join(directory, "analyses", id), data)
  rescue SystemCallError => error
    raise Error, "could not persist analysis: #{error.message}"
  end

  def review(id = nil)
    base = File.join(directory, "analyses")
    paths = id ? [File.join(base, id)] : Dir.glob(File.join(base, "*"))
    paths.map { |path| read(path) }
  end

  private

  def write(path, data)
    temporary = File.join(path, ".record-#{SecureRandom.hex(6)}")
    File.binwrite(temporary, JSON.pretty_generate(data))
    File.rename(temporary, File.join(path, "record.json"))
  ensure
    File.delete(temporary) if temporary && File.exist?(temporary)
  end

  def read(path)
    raise Error, "invalid analysis run ID" unless Primus::Analysis::SavedObservation::RUN_ID.match?(File.basename(path))
    raise Error, "analysis path escapes run" unless File.realpath(path) == path
    record_path = File.join(path, "record.json")
    raise Error, "analysis record path escapes run" unless File.realpath(record_path) == record_path
    record = Primus::Analysis::StrictData.json(File.binread(record_path))
    definition_path = File.join(path, "definition.yml")
    raise Error, "analysis definition path escapes run" unless File.realpath(definition_path) == definition_path
    definition = File.binread(definition_path)
    Primus::Analysis::RetainedRecord.new(record).validate!
    raise Error, "analysis identity mismatch" unless record["analysis_run_id"] == File.basename(path)
    raise Error, "definition digest mismatch" unless record["definition_sha256"] == Digest::SHA256.hexdigest(definition)
    record
  rescue SystemCallError, Primus::Analysis::StrictData::Error,
         Primus::Analysis::RetainedRecord::Error => error
    raise Error, "analysis record: #{error.message}"
  end
end
