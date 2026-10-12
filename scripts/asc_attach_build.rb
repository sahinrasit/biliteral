# Attaches the newest processed build to the editable App Store version. Does not submit anything.
# Usage: ruby scripts/asc_attach_build.rb
require_relative "asc"

APP_ID = ASC.get("/v1/apps?filter%5BbundleId%5D=com.sahinrasit.biliteral")["data"].first["id"]
version = ASC.get("/v1/apps/#{APP_ID}/appStoreVersions?filter%5BappStoreState%5D=PREPARE_FOR_SUBMISSION")["data"].first or abort("No version in Prepare for Submission")
build = ASC.get("/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5BprocessingState%5D=VALID&sort=-uploadedDate&limit=1")["data"].first or abort("No valid build")
ASC.patch("/v1/appStoreVersions/#{version['id']}/relationships/build", data: { type: "builds", id: build["id"] })
puts "version #{version.dig('attributes', 'versionString')} -> build #{build.dig('attributes', 'version')}"
