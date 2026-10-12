# Biliteral — progress log

Plan: research brief §0.2 (12 steps). Accounts: Apple team `CJ438MY6FU`, GitHub `sahinrasit`,
bundle ID `com.sahinrasit.biliteral`. The owner approved on 2026-10-12: full autonomy up to App Review,
reuse of ASC API key `9ZUJU3XZ8V` (copied to `fastlane/`, git-ignored), public repo, Paid Apps Agreement active.

## Status

| # | Step | State |
|---|------|-------|
| 1 | Repo + skeleton | ✅ XcodeGen project, `Packages/BiliteralCore`, fastlane, docs site |
| 2 | Core (EPUB/PDF/URL/paste, sentences, translation, cache) | ✅ 27 core tests (`swift test --package-path Packages/BiliteralCore`) |
| 3 | Two-page + single-column reader | ✅ verified on iPhone 17 Pro Max and iPad Pro 13 simulators |
| 4 | RevenueCat + paywall | ⏳ paywall + StoreKit 2 done; RevenueCat keys from the owner pending |
| 5 | Onboarding → sample book → paywall | ✅ 3 pages, opens the sample book; free tier 1 book / 3 chapters / 20 reviews a day |
| 6 | Localization | ✅ 140 keys × de, fr, es, it, nl, tr, 0 missing (`scripts/build_xcstrings.py build/dd`) |
| 7 | Screenshots + metadata | ⏳ metadata for 8 locales written and within limits; screenshots next |
| 8 | TestFlight | — |
| 9 | ASC: IAPs, prices, privacy label, review info | — |
| 10 | Submit for review | — |
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

- RevenueCat: create project "Biliteral", add the App Store app (`com.sahinrasit.biliteral`) with the
  In-App Purchase key (the team key in `~/TwoSides/.secrets/SubscriptionKey_U3ALV752ML.p8` works),
  then save the public `appl_` key to `.secrets/revenuecat_public.txt` and a v2 secret key to
  `.secrets/revenuecat_v2.txt`. Until then the app uses StoreKit 2 directly.
- `gh auth refresh -s workflow` so `.github/workflows/ios.yml` can be pushed.

## Log

- 2026-10-12: prerequisites checked; core package, app, sample book, localization, metadata, site written.
