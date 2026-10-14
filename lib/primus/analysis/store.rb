require "fileutils"
require "securerandom"
require "time"

class Primus::Analysis::Store
  class Error < StandardError; end
  attr_reader :directory

  def initialize(directory:)
    @directory = directory
  end

  def reserve(entry, definition_bytes)
    id = "#{Time.now.utc.strftime('%Y%m%dT%H%M%S')}-#{SecureRandom.hex(6)}"
    path = File.join(directory, "analyses", id)
    FileUtils.mkdir_p(File.dirname(path))
    Dir.mkdir(path)
    entry = entry.with_id(id)
    File.binwrite(File.join(path, "definition.yml"), definition_bytes)
    write(path, entry)
    entry
  rescue SystemCallError => error
    raise Error, "could not persist analysis: #{error.message}"
  end

  def finish(entry)
    write(File.join(directory, "analyses", entry.analysis_run_id), entry)
    entry
  rescue SystemCallError => error
    raise Error, "could not persist analysis: #{error.message}"
  end

  def review(id = nil)
    base = File.join(directory, "analyses")
    paths = id ? [File.join(base, id)] : Dir.glob(File.join(base, "*"))
    paths.map { |path| read(path) }
  end

  private

  def write(path, entry)
    temporary = File.join(path, ".record-#{SecureRandom.hex(6)}")
    File.binwrite(temporary, JSON.pretty_generate(entry.to_h))
    File.rename(temporary, File.join(path, "record.json"))
  ensure
    File.delete(temporary) if temporary && File.exist?(temporary)
  end

  def read(path)
    raise Error, "invalid analysis run ID" unless Primus::Analysis::RUN_ID.match?(File.basename(path))
    raise Error, "analysis path escapes run" unless File.realpath(path) == path
    record_path = File.join(path, "record.json")
    raise Error, "analysis record path escapes run" unless File.realpath(record_path) == record_path
    record = Primus::Analysis::StrictData.json(File.binread(record_path))
    definition_path = File.join(path, "definition.yml")
    raise Error, "analysis definition path escapes run" unless File.realpath(definition_path) == definition_path
    definition = File.binread(definition_path)
    Primus::Analysis::RecordValidator.new(record).validate!
    raise Error, "analysis identity mismatch" unless record["analysis_run_id"] == File.basename(path)
    raise Error, "definition digest mismatch" unless record["definition_sha256"] == Digest::SHA256.hexdigest(definition)
    Primus::Analysis::LogEntry.new(data: record)
  rescue SystemCallError, Primus::Analysis::StrictData::Error,
         Primus::Analysis::RecordValidator::Error => error
    raise Error, "analysis record: #{error.message}"
  end
end
