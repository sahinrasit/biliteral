# Age rating and App Review details for the editable version. Safe to re-run.
# Usage: ruby scripts/asc_listing.rb
# Reads the reviewer contact from .secrets/review_contact.json
# ({contactFirstName, contactLastName, contactPhone, contactEmail}; git-ignored).
require_relative "asc"

ROOT = File.expand_path("..", __dir__)
BUNDLE = "com.sahinrasit.biliteral"
APP_ID = ASC.get("/v1/apps?filter%5BbundleId%5D=#{BUNDLE}")["data"].first&.dig("id") or abort("Create the App Store Connect record first")

def editable(path, states)
  ASC.get(path)["data"].find { |d| states.include?(d.dig("attributes", "appStoreState") || d.dig("attributes", "state")) }
end

EDITABLE = %w[PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED REJECTED METADATA_REJECTED]

info = editable("/v1/apps/#{APP_ID}/appInfos", EDITABLE + %w[WAITING_FOR_REVIEW]) || ASC.get("/v1/apps/#{APP_ID}/appInfos")["data"].first
decl = ASC.get("/v1/appInfos/#{info['id']}/ageRatingDeclaration")["data"]
none = "NONE"
ASC.patch("/v1/ageRatingDeclarations/#{decl['id']}", data: {
  type: "ageRatingDeclarations", id: decl["id"], attributes: {
    alcoholTobaccoOrDrugUseOrReferences: none, contests: none, gamblingSimulated: none, gunsOrOtherWeapons: none,
    horrorOrFearThemes: none, matureOrSuggestiveThemes: none, medicalOrTreatmentInformation: none,
    profanityOrCrudeHumor: none, sexualContentGraphicAndNudity: none, sexualContentOrNudity: none,
    violenceCartoonOrFantasy: none, violenceRealistic: none, violenceRealisticProlongedGraphicOrSadistic: none,
    gambling: false, unrestrictedWebAccess: false, lootBox: false, advertising: false, messagingAndChat: false,
    parentalControls: false, ageAssurance: false, userGeneratedContent: false, healthOrWellnessTopics: false,
    socialMedia: false
  }
})
puts "age rating set (4+)"

version = editable("/v1/apps/#{APP_ID}/appStoreVersions?filter%5Bplatform%5D=IOS", EDITABLE) or abort("No editable version")
contact = JSON.parse(File.read(File.join(ROOT, ".secrets/review_contact.json")))
notes = File.read(File.join(ROOT, "fastlane/metadata/review_information/notes.txt")).strip
attrs = contact.merge("demoAccountRequired" => false, "notes" => notes)
detail = (ASC.get("/v1/appStoreVersions/#{version['id']}/appStoreReviewDetail")["data"] rescue nil)
if detail
  ASC.patch("/v1/appStoreReviewDetails/#{detail['id']}", data: { type: "appStoreReviewDetails", id: detail["id"], attributes: attrs })
else
  ASC.post("/v1/appStoreReviewDetails", data: {
    type: "appStoreReviewDetails", attributes: attrs,
    relationships: { appStoreVersion: { data: { type: "appStoreVersions", id: version["id"] } } }
  })
end
puts "review details set for version #{version.dig('attributes', 'versionString')}"
