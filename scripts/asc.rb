# Minimal App Store Connect API client.
# Usage: ruby scripts/asc.rb GET /v1/apps?filter[bundleId]=com.sahinrasit.biliteral
#        ruby scripts/asc.rb POST /v1/bundleIds '{"data":{...}}'
# Reads fastlane/asc_api_key.json. Prints the JSON response.
require "json"
require "jwt"
require "net/http"
require "openssl"
require "uri"

module ASC
  ROOT = File.expand_path("..", __dir__)

  def self.config
    @config ||= JSON.parse(File.read(File.join(ROOT, "fastlane/asc_api_key.json")))
  end

  def self.token
    key = OpenSSL::PKey.read(File.read(File.expand_path(config["key_filepath"], File.join(ROOT, "fastlane"))))
    payload = { iss: config["issuer_id"], iat: Time.now.to_i, exp: Time.now.to_i + 1100, aud: "appstoreconnect-v1" }
    JWT.encode(payload, key, "ES256", { kid: config["key_id"], typ: "JWT" })
  end

  def self.request(method, path, body = nil)
    uri = URI(path.start_with?("http") ? path : "https://api.appstoreconnect.apple.com#{path}")
    klass = { "GET" => Net::HTTP::Get, "POST" => Net::HTTP::Post, "PATCH" => Net::HTTP::Patch,
              "DELETE" => Net::HTTP::Delete }.fetch(method)
    req = klass.new(uri)
    req["Authorization"] = "Bearer #{token}"
    req["Content-Type"] = "application/json"
    req.body = body.is_a?(String) ? body : JSON.generate(body) if body
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    parsed = res.body.to_s.empty? ? {} : JSON.parse(res.body)
    raise "#{method} #{path} -> #{res.code}: #{JSON.pretty_generate(parsed)}" unless res.code.to_i < 300
    parsed
  end

  def self.get(path)
    request("GET", path)
  end

  def self.post(path, body)
    request("POST", path, body)
  end

  def self.patch(path, body)
    request("PATCH", path, body)
  end
end

if $PROGRAM_NAME == __FILE__
  method, path, body = ARGV
  puts JSON.pretty_generate(ASC.request(method, path, body))
end
