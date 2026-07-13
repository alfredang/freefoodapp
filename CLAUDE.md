# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

FreeFood (App Store listing "FreeFood: Share Leftovers") is a native SwiftUI iOS app for posting and discovering free leftover food nearby. Create a listing with photos, location, date, and a start/end time window; browse a searchable feed; and view listings on an Apple Map.

Data lives in the **CloudKit public database** (container `iCloud.com.tertiaryinfotech.freefood`) so every user sees the same shared listings. There is **no user account** — CloudKit uses the device's iCloud identity. Browsing works signed-out; posting requires the device to be signed into iCloud.

## Build & run

```sh
# Build for simulator
xcodebuild -project freefoodapp.xcodeproj -scheme freefoodapp -configuration Debug \
  -sdk iphonesimulator build

# Run in a simulator
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null
xcrun simctl install booted "$(xcodebuild -project freefoodapp.xcodeproj -scheme freefoodapp \
  -configuration Debug -sdk iphonesimulator -showBuildSettings | awk '/ BUILT_PRODUCTS_DIR/{d=$3}/ FULL_PRODUCT_NAME/{n=$3}END{print d"/"n}')"
xcrun simctl launch booted com.tertiaryinfotech.freefood
```

There is no test target, no linter, and no package manager — this is a plain `.xcodeproj` with no third-party dependencies (Apple frameworks only: SwiftUI, MapKit, CoreLocation, PhotosUI). Open in Xcode 16+ and target iOS 17+. The app is **iPhone-only** (`TARGETED_DEVICE_FAMILY = 1`).

## Architecture

The app is a single target. `FreeFoodApp` (`freefoodapp/freefoodappApp.swift`) injects two `@StateObject`s as environment objects consumed throughout the view tree:

- **`FoodListingStore`** (`Services/`) — `@MainActor ObservableObject`, the single source of truth for listings, backed by the **CloudKit public database** (`publicCloudDatabase`). Two things to know:
  - **Eventual consistency.** A record you just saved is often missing from the next query for a few seconds. Locally-saved records are held in `pending` and overlaid on query results (`rebuild()`) until a fetch confirms them, so a freshly-posted listing doesn't vanish.
  - **Expiry is a two-layer system.** Expired listings (past their end time, or >7 days old) are always *hidden* client-side by the `isActive` filter, so users never see stale posts. *Deleting* them from the cloud is separate: CloudKit's public-DB rule lets a device delete only records **its own user created**, so `purgeStaleFromCloud()` can't sweep strangers' posts. That's what the hourly **`.github/workflows/cleanup-past-events.yml`** job is for — it holds a CloudKit server-to-server key and deletes everyone's expired records (`scripts/cleanup_past_events.py`). If that job is disabled, the app still looks correct; expired records just accumulate invisibly in CloudKit.

  ⚠️ CloudKit Web Services quirk: deleting via the REST API must use `operationType: "forceDelete"`. Plain `"delete"` requires each record's `recordChangeTag`, which a query response doesn't carry, and fails with `BAD_REQUEST: missing required field 'recordChangeTag'`.
- **`LocationManager`** (`Services/`) — wraps CoreLocation for permission + current location, used to rank the feed by nearest listing.
- **`LocationSearchService`** (`Services/`) — MapKit `MKLocalSearch` place lookup; owned locally by `AddListingView` (not a global env object) to resolve a typed query into a coordinate.

`FoodListing` (`Models/`) is the core value type. Note the time model: `date`, `startTime`, and `endTime` are stored separately, and the computed `combinedStartDate` / `combinedEndDate` merge the day from `date` with the hour/minute from the time fields — use these computed properties for ordering and display, not the raw fields.

View layer (`Views/`): `ContentView` (tab/nav shell) → `ListingFeedView` (searchable list, nearest-first), `AddListingView` (the create form: photos capped at 3, Apple Maps location search, date + start/end time, with `canSave` requiring a resolved coordinate and `endTime > startTime`), `ListingDetailView`, and `FoodMapView` (MapKit markers).

## App Store submission

This repo is wired for App Store submission via the **`app-store-submission` skill**, installed at `.claude/skills/app-store-submission/` (scripts under `scripts/`). Per-project values live in the **gitignored `.env`** (loaded with `set -a; source .env; set +a`).

- **Bundle ID:** `com.tertiaryinfotech.freefood` · **ASC App ID:** `6782157783` · **Team:** `GU9WTSTX9M`
- ⚠️ Always confirm `ASC_APP_ID` / `ASC_BUNDLE_ID` in `.env` target *this* app before uploading — run `python3 .claude/skills/app-store-submission/scripts/asc_submit.py status` and verify the returned name is "FreeFood: Share Leftovers". (This project was previously mis-pointed at an unrelated "PotLuckHub" record — do not reintroduce that.)
- Signing is **manual**: "Apple Distribution" cert + the API-created "FreeFood App Store" provisioning profile, configured in `ExportOptions.plist`.
- `CURRENT_PROJECT_VERSION` (build) must be bumped on **every** upload; `MARKETING_VERSION` is the user-facing version.
- `ITSAppUsesNonExemptEncryption = false` and a `PrivacyInfo.xcprivacy` manifest are already set. Since there's no account, the account-deletion review requirement does not apply.
- Read `.claude/skills/app-store-submission/SKILL.md` for the full archive → upload → metadata → submit flow and the App-Review gotchas.
