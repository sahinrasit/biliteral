# Uploads the paywall screenshot as the App Review screenshot of both in-app purchases.
# Usage: ruby scripts/asc_review_screenshots.rb path/to/paywall.png
require "digest"
require_relative "asc"

LIFETIME_ID = "6822090362"
MONTHLY_ID = "6822090445"

def upload(path, create_path, relationship, type, owner_type, owner_id)
  data = File.binread(path)
  reservation = ASC.post(create_path, data: {
    type: type, attributes: { fileName: File.basename(path), fileSize: data.bytesize },
    relationships: { relationship => { data: { type: owner_type, id: owner_id } } }
  })["data"]
  reservation.dig("attributes", "uploadOperations").each do |op|
    uri = URI(op["url"])
    req = Net::HTTP.const_get(op["method"].capitalize).new(uri)
    op["requestHeaders"].each { |h| req[h["name"]] = h["value"] }
    req.body = data.byteslice(op["offset"], op["length"])
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    raise "upload failed: #{res.code}" unless res.code.to_i < 300
  end
  ASC.patch("#{create_path}/#{reservation['id']}", data: {
    type: type, id: reservation["id"],
    attributes: { uploaded: true, sourceFileChecksum: Digest::MD5.hexdigest(data) }
  })
  puts "#{owner_type} #{owner_id}: review screenshot uploaded"
end

path = ARGV[0] or abort "usage: asc_review_screenshots.rb <png>"
existing = ASC.get("/v2/inAppPurchases/#{LIFETIME_ID}/appStoreReviewScreenshot")["data"] rescue nil
if existing
  puts "lifetime already has a review screenshot"
else
  upload(path, "/v1/inAppPurchaseAppStoreReviewScreenshots", :inAppPurchaseV2,
         "inAppPurchaseAppStoreReviewScreenshots", "inAppPurchases", LIFETIME_ID)
end
existing = ASC.get("/v1/subscriptions/#{MONTHLY_ID}/appStoreReviewScreenshot")["data"] rescue nil
if existing
  puts "monthly already has a review screenshot"
else
  upload(path, "/v1/subscriptionAppStoreReviewScreenshots", :subscription,
         "subscriptionAppStoreReviewScreenshots", "subscriptions", MONTHLY_ID)
end
