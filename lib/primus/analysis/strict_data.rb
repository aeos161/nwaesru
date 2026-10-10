require "json"
require "psych"

module Primus::Analysis::StrictData
  class Error < StandardError; end

  class UniqueHash < Hash
    def []=(key, value)
      raise Error, "duplicate JSON key #{key}" if key?(key)
      super
    end
  end

  def self.json(bytes)
    JSON.parse(utf8(bytes), object_class: UniqueHash)
  rescue JSON::ParserError => error
    raise Error, "JSON parse: #{error.message}"
  end

  def self.yaml(bytes)
    source = utf8(bytes)
    reject_duplicate_yaml(Psych.parse(source))
    Psych.safe_load(source, aliases: false)
  rescue Psych::Exception => error
    raise Error, "YAML parse: #{error.message}"
  end

  def self.utf8(bytes)
    text = bytes.dup.force_encoding(Encoding::UTF_8)
    raise Error, "invalid UTF-8 text" unless text.valid_encoding?
    text
  end

  def self.reject_duplicate_yaml(node)
    if node.is_a?(Psych::Nodes::Mapping)
      keys = node.children.each_slice(2).map(&:first).map(&:value)
      duplicate = keys.detect { |key| keys.count(key) > 1 }
      raise Error, "duplicate YAML key #{duplicate}" if duplicate
    end
    Array(node.children).each { |child| reject_duplicate_yaml(child) } if node.respond_to?(:children)
  end
end
