module Aprimo
  class API
    def self.config=(config)
      @config = config
    end

    def self.config
      @config
    end

    def self.metadata
      self.new.get("/MetaData/", "Describe").body
    end

    def get(path, method)
      url = uri(path)
      http_with_retry do
        http.get(url.path, headers(method, url))
      end
    end

    def post(path, method, data)
      url = uri(path)
      http_with_retry do
        http.post(url.path, data, headers(method, url))
      end
    end

    def uri(path = "")
      URI.parse(File.join(self.class.config.base_url, path))
    end

    def http
      http = Net::HTTP.new(uri.host, 443)
      http.use_ssl = true
      http
    end

    def headers(method, url)
      {
        "ams-method" => method,
        "ams-nonce" => nonce.to_s,
        "ams-age" => age.to_s,
        "Authorization" => authorization(method, url)
      }
    end

    def authorization(method, url)
      str = "#{age}&#{nonce}&#{method.downcase}&#{url.to_s.downcase}"
      signature = OpenSSL::HMAC.digest(OpenSSL::Digest::SHA1.new, self.class.config.private_key, str)

      "AMS #{self.class.config.public_key}:#{Base64.encode64(signature)}"
    end

    def nonce
      @nonce ||= rand(2147483647)
    end

    def age
      @age ||= Time.now.to_i
    end

    def http_with_retry(&block)
      log_retry = Proc.new do |exception, tries|
        puts "#{exception.class}: '#{exception.message}' - #{tries}"
      end

      Retriable.retriable on: [Timeout::Error], tries: 5, interval: 5, on_retry: log_retry do
        block.call
      end
    end
  end
end
