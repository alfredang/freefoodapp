# Changelog

All notable features and bug fixes for **FreeFood** (App Store: *FreeFood: Share Leftovers*),
newest first. Versions follow `MARKETING_VERSION` (e.g. 1.1); each App Store build has its
own `CFBundleVersion` build number.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- **About tab** — a dedicated About screen with the app description, developer (Tertiary Infotech Academy Pte Ltd), data/privacy summary, and version.
- **Feedback tab** — send a feature request or bug report straight to the FreeFood team over WhatsApp.
- **Human verification before posting** — a lightweight anti-bot check (type the shown code) to deter automated/fake listings.
- **Recurring events** — bakeries, stalls, and offices can mark a listing as Daily or Weekly so regular free-food giveaways stay live (they roll forward to the next occurrence and aren't auto-deleted).
- **Reduce-food-waste notice** — an in-app reminder (Add screen + Settings) that FreeFood exists to cut food waste; please don't post fictitious events.
- **Like + social share** — tap to like a listing (one per device), and share it to WhatsApp / other apps via the iOS share sheet.
- **Country & distance filters (Settings)** — show only listings in your country and within a configurable distance (default 10 km).
- **Subscribe to recurring giveaways** — subscribed giveaways are always shown regardless of the country/distance filters.

### Changed
- CloudKit schema gains `recurrence`, `likes`, and `country` fields.
- CI `ci_submit` is resilient to the review-submission cancel/attach race (retries reusing an empty draft).
- CI builds with **Xcode 26 / iOS 26 SDK** (now required by App Store Connect).
- **Release notes are auto-recorded** — at submit time, the matching CHANGELOG section is written to the App Store "What's New in This Version" (no-op on a first release).

## [1.1] — CloudKit public sharing
Builds: 2, 3, and CI-built builds.

### Added
- **Public cloud sharing (CloudKit public database)** — listings are shared across all users; everyone's phone sees food posted by everyone. Browsing needs no account; posting uses the device's iCloud.
- Photos stored as CloudKit `CKAsset` (up to 3 per listing).
- **CI/CD pipeline** — push to `main` auto-builds, signs, uploads, and submits to App Store Connect (GitHub Actions, macOS).
- **Server-side cleanup cron** — hourly GitHub Action deletes *everyone's* past/expired listings from the public database via a CloudKit server-to-server key.

### Changed
- A listing is shown only while it's still upcoming/ongoing **and** posted within the last 7 days.

### Fixed
- Freshly-posted listings no longer disappear (CloudKit eventual-consistency: keep a local "pending" overlay until the cloud query catches up).
- Past/expired events are now **deleted** from the cloud, not just hidden (the user's own client-side, plus the server cron for all).
- `@preconcurrency import MapKit` so the location search compiles under Swift 6 strict concurrency.

## [1.0] — Initial release
Build: 1.

### Added
- Native SwiftUI app to post and discover free leftover food: title, details, up to 3 photos, location (Apple Maps search), date, and a start/end time window.
- Searchable feed (nearest first) and an Apple Map view of all listings.
- Auto-expiry of listings after 7 days.

### Notes
- First standalone **FreeFood** App Store record (`com.tertiaryinfotech.freefood`), created after an earlier build was mistakenly submitted into an unrelated "PotLuckHub" listing.
- Storage was local-only in 1.0; cloud sharing arrived in 1.1.
