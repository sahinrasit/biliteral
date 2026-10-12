# Biliteral — progress log

Plan: research brief §0.2 (12 steps). Accounts: Apple team `CJ438MY6FU`, GitHub `sahinrasit`,
bundle ID `com.sahinrasit.biliteral`. The owner approved on 2026-10-12: full autonomy up to App Review,
reuse of ASC API key `9ZUJU3XZ8V` (copied to `fastlane/`, git-ignored), public repo, Paid Apps Agreement active.

## Status

| # | Step | State |
|---|------|-------|
| 1 | Repo + skeleton | ✅ https://github.com/sahinrasit/biliteral (public), Pages: https://sahinrasit.github.io/biliteral/privacy (200) |
| 2 | Core (EPUB/PDF/URL/paste, sentences, translation, cache) | ✅ 27 core tests (`swift test --package-path Packages/BiliteralCore`) |
| 3 | Two-page + single-column reader | ✅ verified on iPhone 17 Pro Max and iPad Pro 13 simulators |
| 4 | RevenueCat + paywall | ⏳ paywall + StoreKit 2 done; RevenueCat keys from the owner pending |
| 5 | Onboarding → sample book → paywall | ✅ 3 pages, opens the sample book; free tier 1 book / 3 chapters / 20 reviews a day |
| 6 | Localization | ✅ 140 keys × de, fr, es, it, nl, tr, 0 missing (`scripts/build_xcstrings.py build/dd`) |
| 7 | Screenshots + metadata | ⏳ metadata for 8 locales within limits; `fastlane screenshots` running, then `swift scripts/frame_screenshots.swift fastlane/screenshots build/framed` |
| 8 | TestFlight | ⛔ needs the App Store Connect record (see open items) |
| 9 | ASC: IAPs, prices, privacy label, review info | — |
| 10 | Submit for review | ⏸ owner decision (2026-10-13): prepare everything, do NOT submit |
| 11 | Handle rejection | — |
| 12 | 7-day post-launch monitoring | — |

## Decisions and deviations from the brief

- Xcode 26.3 / iOS 26.2 SDK on this Mac (brief assumed 27.1); no iPhone Duo simulator. Deployment target iOS 18.
  The two-page layout switches on at ≥ 600 pt width (iPad, unfolded phone, large iPhone in landscape).
- Translation uses SwiftUI `.translationTask` (works on iOS 18), one request per sentence with
  `clientIdentifier` = sentence index, batches of ≤ 40 sentences / 4,000 characters, cached per chapter as JSON.
  The next chapter is translated ahead. The simulator has no translator: `-SeedDemo` ships ready translations
  of chapter VII (my own) into es/de/fr/it/nl/tr for screenshots and UI tests.
- Sample book: "Alice's Adventures in Wonderland" (Gutenberg #11, public domain), built into a clean EPUB by
  `scripts/make_sample_book.py`. Always free.
- Scope cut to 1.1: Share Extension, CloudKit sync, scanned-PDF OCR, review reminders (no notification prompt).
  Metadata says "iCloud backup", not sync.
- Word lookup: tap a sentence first, then a word inside it (keeps sentence selection and word lookup apart).
- "Explain this sentence" (Foundation Models, iOS 26 + Apple Intelligence) is Pro-only.
- Categories: Education (primary), Books (secondary).
- `.github/workflows/ios.yml` is git-ignored until the token has the `workflow` scope.

## Open items for the owner

- **App Store Connect record (blocker).** The API refuses `POST /v1/apps` (403), so it must be created on the website:
  My Apps → + → New App · iOS · Name `Biliteral: Bilingual Reader` · English (U.S.) · Bundle ID
  `com.sahinrasit.biliteral` (registered, id K33TN9L369) · SKU `biliteral-ios-2026` · Full Access.
  Also on the website: App Privacy → "Purchases" (not linked, no tracking, app functionality), publish.
  Claude cannot sign in (no password entry); sign in to App Store Connect and RevenueCat in Chrome and Claude does the rest.

- RevenueCat: create project "Biliteral", add the App Store app (`com.sahinrasit.biliteral`) with the
  In-App Purchase key (the team key in `~/TwoSides/.secrets/SubscriptionKey_U3ALV752ML.p8` works),
  then save the public `appl_` key to `.secrets/revenuecat_public.txt` and a v2 secret key to
  `.secrets/revenuecat_v2.txt`. Until then the app uses StoreKit 2 directly.
- `gh auth refresh -s workflow` so `.github/workflows/ios.yml` can be pushed.

## Next steps once the record exists (in order)

1. `ruby scripts/asc_setup.rb` (system Ruby) — app free, availability, Lifetime + Monthly IAPs with prices.
2. `ruby scripts/asc_listing.rb` — age rating 4+, review contact and notes.
3. `PATH=/opt/homebrew/opt/ruby/bin:$PATH bundle exec fastlane beta` — archive and upload to TestFlight.
4. `bundle exec fastlane metadata` (with framed screenshots copied to `fastlane/screenshots/<locale>`, en-GB = en-US copy).
5. RevenueCat project + offering; then `bundle exec fastlane release`.

Tooling notes: fastlane 2.241 lives in `vendor/bundle` (Homebrew Ruby 3.3); `scripts/asc*.rb` need system Ruby
(`/usr/bin/ruby`), because Homebrew Ruby's OpenSSL fails Apple's CRL check.

## Log

- 2026-10-12: prerequisites checked; core package, app, sample book, localization, metadata, site written.
- 2026-10-12: repo pushed, Pages live, bundle ID registered. App record creation blocked (website only).
- 2026-10-13: sentence and word taps verified by hand in the simulator; UI test failures were timeouts on an
  overloaded host (load ~800), timeouts raised to 60 s. Screenshot run started.
