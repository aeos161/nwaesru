class Primus::Experiment::Blake2b
  class Unavailable < StandardError; end

  def hexdigest(bytes)
    digest.hexdigest(bytes)
  end

  def runtime
    descriptor = versions
    digest
    descriptor.merge("available" => true)
  rescue Unavailable
    descriptor.merge("available" => false)
  end

  private

  def digest
    require "openssl"
    OpenSSL::Digest.new("BLAKE2b512")
  rescue LoadError, OpenSSL::Digest::DigestError, RuntimeError => error
    message = "blake2b512 unavailable: #{error.class}: #{error.message}"
    raise Unavailable, message
  end

  def versions
    require "openssl"
    { "openssl_binding_version" => OpenSSL::VERSION,
      "openssl_build_version" => OpenSSL::OPENSSL_VERSION,
      "openssl_library_version" => OpenSSL::OPENSSL_LIBRARY_VERSION }
  rescue LoadError
    { "openssl_binding_version" => nil, "openssl_build_version" => nil,
      "openssl_library_version" => nil }
  end
end
