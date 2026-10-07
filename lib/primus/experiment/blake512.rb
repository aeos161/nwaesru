class Primus::Experiment::Blake512
  class Unavailable < StandardError; end

  def hexdigest(bytes)
    backend.hexdigest(bytes)
  end

  def runtime
    available_info
  rescue Unavailable => error
    unavailable(error)
  end

  private

  def backend
    require "aeos/blake512"
    Aeos::Blake512
  rescue ::LoadError => error
    raise Unavailable, "blake512 unavailable: #{error.class}: #{error.message}"
  end

  def available_info
    info = backend.build_info
    unless info.is_a?(Hash) && info["schema_version"] == 1
      raise Unavailable, "unsupported BLAKE-512 build descriptor"
    end
    info.merge("backend" => "blake512-ruby", "available" => true)
  end

  def unavailable(error)
    { "backend" => "blake512-ruby", "available" => false,
      "gem_version" => Gem.loaded_specs["blake512-ruby"]&.version&.to_s,
      "error_class" => (error.cause || error).class.name,
      "error_message" => error.message }
  end
end
