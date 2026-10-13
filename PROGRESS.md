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
| 4 | RevenueCat + paywall | ✅ project `projd99429d7`, app `appf9d467733a`, entitlement `pro`, current offering `default` ($rc_lifetime, $rc_monthly) |
| 5 | Onboarding → sample book → paywall | ✅ 3 pages, opens the sample book; free tier 1 book / 3 chapters / 20 reviews a day |
| 6 | Localization | ✅ 140 keys × de, fr, es, it, nl, tr, 0 missing (`scripts/build_xcstrings.py build/dd`) |
| 7 | Screenshots + metadata | ✅ 8 locales: texts + 8 iPhone 6.9" + 8 iPad 13" framed screenshots each, all COMPLETE in ASC |
| 8 | TestFlight | ✅ build 2 (with RevenueCat key) VALID, attached to version 1.0 |
| 9 | ASC: IAPs, prices, privacy label, review info | ✅ app 6822089873; Lifetime 6822090362 + Monthly 6822090445 READY_TO_SUBMIT; privacy label published; age 4+; review contact + notes |
| 10 | Submit for review | ⏸ READY: version 1.0 in Prepare for Submission, build 2 attached, "Add for Review" enabled, no warnings. Not submitted (owner decision 2026-10-13) |
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

- `gh auth refresh -s workflow` so `.github/workflows/ios.yml` can be pushed.

## How the store setup was done (re-runnable)

1. `ruby scripts/asc_setup.rb` (system Ruby) — app free, availability, Lifetime + Monthly IAPs with prices.
2. `ruby scripts/asc_listing.rb` — age rating 4+, review contact and notes.
3. `PATH=/opt/homebrew/opt/ruby/bin:$PATH bundle exec fastlane beta` — archive and upload to TestFlight.
4. `bundle exec fastlane metadata` (with framed screenshots copied to `fastlane/screenshots/<locale>`, en-GB = en-US copy).
5. `python3 scripts/revenuecat_setup.py` — RevenueCat products, entitlement, offering.
6. `ruby scripts/asc_review_screenshots.rb <paywall.png>`, `ruby scripts/asc_attach_build.rb`.
7. Screenshots: `bundle exec fastlane screenshots`, `swift scripts/frame_screenshots.swift fastlane/screenshots build/framed`,
   copy en-US to en-GB, `bundle exec fastlane upload_screenshots`.
8. Submission (NOT done, owner decides): `bundle exec fastlane release`.

Tooling notes: fastlane 2.241 lives in `vendor/bundle` (Homebrew Ruby 3.3); `scripts/asc*.rb` need system Ruby
(`/usr/bin/ruby`), because Homebrew Ruby's OpenSSL fails Apple's CRL check.

## Log

- 2026-10-12: prerequisites checked; core package, app, sample book, localization, metadata, site written.
- 2026-10-12: repo pushed, Pages live, bundle ID registered. App record creation blocked (website only).
- 2026-10-13: sentence and word taps verified by hand in the simulator; UI test failures were timeouts on an
  overloaded host (load ~800), timeouts raised to 60 s. Screenshot run started.
- 2026-10-13: owner signed in to Chrome; Claude created the ASC record, privacy label and RevenueCat project.
  IAPs, prices, metadata (8 locales), builds 1–2 uploaded; build 2 attached. Owner: do NOT submit for review.
- 2026-10-13: 112 screenshots captured, paywall reshot with local prices (₺/€/$), framed, uploaded (en-GB = en-US).
  IAP review screenshots uploaded; both IAPs READY_TO_SUBMIT. Content rights: uses third-party content (has rights).
  Repo has two changes after build 2 (scrollPosition in reader, language-based sample prices); neither affects
  real users, so build 2 stays attached.
