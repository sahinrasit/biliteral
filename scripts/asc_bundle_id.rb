# Registers the bundle ID (name "Biliteral": the portal rejects ":" in names). Safe to re-run.
# Usage: ruby scripts/asc_bundle_id.rb
require_relative "asc"

ID = "com.sahinrasit.biliteral"
existing = ASC.get("/v1/bundleIds?filter%5Bidentifier%5D=#{ID}")["data"].find { |b| b.dig("attributes", "identifier") == ID }
existing ||= ASC.post("/v1/bundleIds", data: { type: "bundleIds", attributes: { identifier: ID, name: "Biliteral", platform: "IOS" } })["data"]
puts "bundleId #{existing['id']}"
