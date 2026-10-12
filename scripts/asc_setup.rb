# Creates Biliteral's in-app purchases, app price and availability in App Store Connect. Safe to re-run: existing items are reused.
# Usage: ruby scripts/asc_setup.rb
require_relative "asc"

BUNDLE = "com.sahinrasit.biliteral"
APP_ID = ASC.get("/v1/apps?filter%5BbundleId%5D=#{BUNDLE}")["data"].first&.dig("id") or abort("Create the App Store Connect record first")
LIFETIME = "com.sahinrasit.biliteral.lifetime"
MONTHLY = "com.sahinrasit.biliteral.monthly"

# Pricing plan (§11): base price in USD, manual overrides elsewhere.
LIFETIME_PRICES = { "USA" => "14.99", "GBR" => "12.99", "TUR" => "399.99" }
MONTHLY_PRICES = { "USA" => "2.99", "GBR" => "2.99", "TUR" => "89.99" }
EURO = %w[DEU FRA ESP ITA NLD AUT BEL IRL PRT FIN]

LOCALIZED = {
  "en-US" => ["Biliteral Lifetime", "Unlimited books and translation. Pay once.",
              "Biliteral Monthly", "Unlimited books, translation and flashcards."],
  "en-GB" => ["Biliteral Lifetime", "Unlimited books and translation. Pay once.",
              "Biliteral Monthly", "Unlimited books, translation and flashcards."],
  "de-DE" => ["Biliteral Lebenslang", "Unbegrenzt Bücher und Übersetzung. Einmal zahlen.",
              "Biliteral Monatlich", "Unbegrenzt Bücher, Übersetzung und Karteikarten."],
  "fr-FR" => ["Biliteral à vie", "Livres et traduction illimités. Achat unique.",
              "Biliteral mensuel", "Livres, traduction et cartes illimités."],
  "es-ES" => ["Biliteral de por vida", "Libros y traducción ilimitados. Pago único.",
              "Biliteral mensual", "Libros, traducción y tarjetas ilimitados."],
  "it" => ["Biliteral a vita", "Libri e traduzione illimitati. Acquisto unico.",
           "Biliteral mensile", "Libri, traduzione e flashcard illimitati."],
  "nl-NL" => ["Biliteral levenslang", "Onbeperkt boeken en vertaling. Eén keer betalen.",
              "Biliteral maandelijks", "Onbeperkt boeken, vertaling en flashcards."],
  "tr" => ["Biliteral Ömür Boyu", "Sınırsız kitap ve çeviri. Tek ödeme.",
           "Biliteral Aylık", "Sınırsız kitap, çeviri ve kelime kartı."]
}

def log(msg)
  puts msg
  $stdout.flush
end

def all_pages(path)
  items = []
  url = path
  while url
    res = ASC.get(url)
    items.concat(res["data"])
    url = res.dig("links", "next")
  end
  items
end

def territories
  @territories ||= all_pages("/v1/territories?limit=200").map { |t| t["id"] }
end

# MARK: Lifetime (non-consumable)

def lifetime_iap
  existing = ASC.get("/v1/apps/#{APP_ID}/inAppPurchasesV2?filter%5BproductId%5D=#{LIFETIME}")["data"].first
  return existing if existing
  log "Creating #{LIFETIME}"
  ASC.post("/v2/inAppPurchases", data: {
    type: "inAppPurchases",
    attributes: { name: "Biliteral Lifetime", productId: LIFETIME, inAppPurchaseType: "NON_CONSUMABLE",
                  familySharable: true, reviewNote: "Unlocks unlimited books, chapters and reviews (entitlement \"pro\"). Open the paywall from Settings > Unlock Biliteral Pro." },
    relationships: { app: { data: { type: "apps", id: APP_ID } } }
  })["data"]
end

def localize_iap(iap_id)
  have = ASC.get("/v2/inAppPurchases/#{iap_id}/inAppPurchaseLocalizations")["data"].map { |l| l.dig("attributes", "locale") }
  LOCALIZED.each do |locale, (name, desc, _, _)|
    next if have.include?(locale)
    log "  IAP localization #{locale}"
    ASC.post("/v1/inAppPurchaseLocalizations", data: {
      type: "inAppPurchaseLocalizations", attributes: { locale: locale, name: name, description: desc },
      relationships: { inAppPurchaseV2: { data: { type: "inAppPurchases", id: iap_id } } }
    })
  end
end

def iap_price_point(iap_id, territory, price)
  all_pages("/v2/inAppPurchases/#{iap_id}/pricePoints?filter%5Bterritory%5D=#{territory}&limit=200")
    .find { |p| p.dig("attributes", "customerPrice") == price } or raise "No #{price} price point in #{territory}"
end

def price_iap(iap_id)
  schedule = ASC.get("/v2/inAppPurchases/#{iap_id}/iapPriceSchedule?include=manualPrices") rescue nil
  if schedule && schedule["included"]&.any?
    log "  price schedule exists"
    return
  end
  prices = LIFETIME_PRICES.merge(EURO.map { |t| [t, "14.99"] }.to_h)
  included = prices.each_with_index.map do |(territory, price), i|
    point = iap_price_point(iap_id, territory, price)
    { type: "inAppPurchasePrices", id: "${price#{i}}", attributes: { startDate: nil },
      relationships: { inAppPurchasePricePoint: { data: { type: "inAppPurchasePricePoints", id: point["id"] } },
                       inAppPurchaseV2: { data: { type: "inAppPurchases", id: iap_id } } } }
  end
  log "  setting prices #{prices.keys.join(', ')}"
  ASC.post("/v1/inAppPurchasePriceSchedules", data: {
    type: "inAppPurchasePriceSchedules",
    relationships: { inAppPurchase: { data: { type: "inAppPurchases", id: iap_id } },
                     baseTerritory: { data: { type: "territories", id: "USA" } },
                     manualPrices: { data: included.map { |p| { type: p[:type], id: p[:id] } } } }
  }, included: included)
end

def availability_iap(iap_id)
  ASC.get("/v2/inAppPurchases/#{iap_id}/inAppPurchaseAvailability")
  log "  availability exists"
rescue RuntimeError
  log "  availability: all territories"
  ASC.post("/v1/inAppPurchaseAvailabilities", data: {
    type: "inAppPurchaseAvailabilities", attributes: { availableInNewTerritories: true },
    relationships: { inAppPurchase: { data: { type: "inAppPurchases", id: iap_id } },
                     availableTerritories: { data: territories.map { |t| { type: "territories", id: t } } } }
  })
end

# MARK: Monthly (auto-renewable)

def subscription_group
  existing = ASC.get("/v1/apps/#{APP_ID}/subscriptionGroups")["data"].first
  return existing if existing
  log "Creating subscription group"
  group = ASC.post("/v1/subscriptionGroups", data: {
    type: "subscriptionGroups", attributes: { referenceName: "Biliteral Pro" },
    relationships: { app: { data: { type: "apps", id: APP_ID } } }
  })["data"]
  LOCALIZED.each_key do |locale|
    ASC.post("/v1/subscriptionGroupLocalizations", data: {
      type: "subscriptionGroupLocalizations", attributes: { locale: locale, name: "Biliteral Pro" },
      relationships: { subscriptionGroup: { data: { type: "subscriptionGroups", id: group["id"] } } }
    })
  end
  group
end

def monthly_subscription(group_id)
  existing = ASC.get("/v1/subscriptionGroups/#{group_id}/subscriptions")["data"].find { |s| s.dig("attributes", "productId") == MONTHLY }
  return existing if existing
  log "Creating #{MONTHLY}"
  ASC.post("/v1/subscriptions", data: {
    type: "subscriptions",
    attributes: { name: "Biliteral Monthly", productId: MONTHLY, subscriptionPeriod: "ONE_MONTH",
                  familySharable: false, groupLevel: 1, reviewNote: "Unlocks unlimited books, chapters and reviews (entitlement \"pro\"). Open the paywall from Settings > Unlock Biliteral Pro." },
    relationships: { group: { data: { type: "subscriptionGroups", id: group_id } } }
  })["data"]
end

def localize_subscription(sub_id)
  have = ASC.get("/v1/subscriptions/#{sub_id}/subscriptionLocalizations")["data"].map { |l| l.dig("attributes", "locale") }
  LOCALIZED.each do |locale, (_, _, name, desc)|
    next if have.include?(locale)
    log "  subscription localization #{locale}"
    ASC.post("/v1/subscriptionLocalizations", data: {
      type: "subscriptionLocalizations", attributes: { locale: locale, name: name, description: desc },
      relationships: { subscription: { data: { type: "subscriptions", id: sub_id } } }
    })
  end
end

def price_subscription(sub_id)
  if ASC.get("/v1/subscriptions/#{sub_id}/prices?limit=1")["data"].any?
    log "  subscription prices exist"
    return
  end
  usa = all_pages("/v1/subscriptions/#{sub_id}/pricePoints?filter%5Bterritory%5D=USA&limit=200")
        .find { |p| p.dig("attributes", "customerPrice") == MONTHLY_PRICES["USA"] } or raise "No USD price point"
  equalized = all_pages("/v1/subscriptionPricePoints/#{usa['id']}/equalizations?limit=200&include=territory")
  overrides = MONTHLY_PRICES.merge(EURO.map { |t| [t, "2.99"] }.to_h)
  points = { "USA" => usa["id"] }
  equalized.each do |p|
    territory = p.dig("relationships", "territory", "data", "id")
    points[territory] = p["id"] if territory
  end
  overrides.each do |territory, price|
    next if territory == "USA"
    match = all_pages("/v1/subscriptions/#{sub_id}/pricePoints?filter%5Bterritory%5D=#{territory}&limit=200")
            .find { |p| p.dig("attributes", "customerPrice") == price }
    match ? points[territory] = match["id"] : log("  no #{price} point in #{territory}, keeping equalized price")
  end
  log "  setting monthly prices in #{points.size} territories"
  points.each do |_, point_id|
    ASC.post("/v1/subscriptionPrices", data: {
      type: "subscriptionPrices", attributes: { startDate: nil, preserveCurrentPrice: false },
      relationships: { subscription: { data: { type: "subscriptions", id: sub_id } },
                       subscriptionPricePoint: { data: { type: "subscriptionPricePoints", id: point_id } } }
    })
  end
end

def availability_subscription(sub_id)
  ASC.get("/v1/subscriptions/#{sub_id}/subscriptionAvailability")
  log "  subscription availability exists"
rescue RuntimeError
  log "  subscription availability: all territories"
  ASC.post("/v1/subscriptionAvailabilities", data: {
    type: "subscriptionAvailabilities", attributes: { availableInNewTerritories: true },
    relationships: { subscription: { data: { type: "subscriptions", id: sub_id } },
                     availableTerritories: { data: territories.map { |t| { type: "territories", id: t } } } }
  })
end

# MARK: App price (free) and availability

def app_price
  existing = ASC.get("/v1/apps/#{APP_ID}/appPriceSchedule?include=manualPrices") rescue nil
  if existing && existing["included"]&.any?
    log "App price exists"
    return
  end
  free = all_pages("/v1/apps/#{APP_ID}/appPricePoints?filter%5Bterritory%5D=USA&limit=200")
         .find { |p| p.dig("attributes", "customerPrice").to_f.zero? } or raise "No free price point"
  log "App price: free"
  ASC.post("/v1/appPriceSchedules", data: {
    type: "appPriceSchedules",
    relationships: { app: { data: { type: "apps", id: APP_ID } },
                     baseTerritory: { data: { type: "territories", id: "USA" } },
                     manualPrices: { data: [{ type: "appPrices", id: "${free}" }] } }
  }, included: [{ type: "appPrices", id: "${free}", attributes: { startDate: nil },
                  relationships: { appPricePoint: { data: { type: "appPricePoints", id: free["id"] } } } }])
end

def app_availability
  ASC.get("/v1/apps/#{APP_ID}/appAvailabilityV2")
  log "App availability exists"
rescue RuntimeError
  log "App availability: all territories"
  included = territories.map do |t|
    { type: "territoryAvailabilities", id: "${#{t}}", attributes: { available: true },
      relationships: { territory: { data: { type: "territories", id: t } } } }
  end
  ASC.post("/v2/appAvailabilities", data: {
    type: "appAvailabilities", attributes: { availableInNewTerritories: true },
    relationships: { app: { data: { type: "apps", id: APP_ID } },
                     territoryAvailabilities: { data: included.map { |i| { type: i[:type], id: i[:id] } } } }
  }, included: included)
end

app_price
app_availability

iap = lifetime_iap
log "Lifetime: #{iap['id']}"
localize_iap(iap["id"])
price_iap(iap["id"])
availability_iap(iap["id"])

group = subscription_group
sub = monthly_subscription(group["id"])
log "Monthly: #{sub['id']} (group #{group['id']})"
localize_subscription(sub["id"])
availability_subscription(sub["id"])
price_subscription(sub["id"])
log "Done"
