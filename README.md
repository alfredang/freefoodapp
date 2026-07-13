<div align="center">

# FreeFood

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://www.swift.org/)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue.svg)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0A84FF.svg)](https://developer.apple.com/xcode/swiftui/)
[![MapKit](https://img.shields.io/badge/Maps-MapKit-34C759.svg)](https://developer.apple.com/documentation/mapkit)
[![License](https://img.shields.io/badge/License-Unspecified-lightgrey.svg)](#license)

**A native iOS app for sharing leftover food nearby and reducing food waste.**

[![Download on the App Store](https://img.shields.io/badge/Download_on_the-App_Store-0D96F6.svg?logo=apple&logoColor=white)](https://apps.apple.com/app/freefood-share-leftovers/id6782157783)

📱 **Now live on the App Store:** [FreeFood: Share Leftovers](https://apps.apple.com/app/freefood-share-leftovers/id6782157783)

[Report Bug](https://github.com/alfredang/freefoodapp/issues) . [Request Feature](https://github.com/alfredang/freefoodapp/issues)

</div>

## Screenshots

| Nearby feed | Listing details | Map view |
| --- | --- | --- |
| ![Feed](docs/screenshot-feed.png) | ![Detail](docs/screenshot-detail.png) | ![Map](docs/screenshot-map.png) |

## About

FreeFood is a SwiftUI iOS app for posting and discovering free leftover food from events, offices, meetups, and community spaces. It focuses on fast local sharing: create a listing with photos, location, schedule, and details; browse a searchable feed; and view available food on an Apple Map. Available on the App Store as **[FreeFood: Share Leftovers](https://apps.apple.com/app/freefood-share-leftovers/id6782157783)**.

### Key Features

| Feature | Description |
| --- | --- |
| Food listings | Add food title, details, date, start time, end time, and up to 3 photos. |
| Apple Maps search | Search MapKit locations when choosing where the food can be collected. |
| Nearby feed | Highlights the nearest available listing when location access is enabled. |
| Search | Filter listings by location, title, or event details. |
| Map view | Browse listings as map markers and open listing details from the map. |
| Public cloud sharing | Listings are stored in the CloudKit public database so everyone sees the same shared food. |
| Auto-expiry | Listings past their end time (or older than 7 days) are filtered out of the feed and map automatically. |
| Likes & sharing | Like a listing (count shared via CloudKit) or share it out through the system share sheet. |
| Filters | Narrow the feed by country and distance radius. |
| About & Feedback | In-app About tab and a Feedback tab for reaching the developer. |

## Tech Stack

| Layer | Technology |
| --- | --- |
| App UI | SwiftUI, NavigationStack, TabView, Form, List |
| Maps & Location | MapKit, CoreLocation |
| Photos | PhotosUI |
| State Management | ObservableObject, EnvironmentObject, @StateObject |
| Persistence | CloudKit public database (`CKRecord` / `CKAsset`); no backend, no user accounts |
| Platform | iOS 17+, iPhone only |
| Build Tooling | Xcode, xcodebuild |

## Architecture

```text
FreeFood
|
+-- SwiftUI App Entry
|   +-- FreeFoodApp
|       +-- FoodListingStore      (injected as @EnvironmentObject)
|       +-- LocationManager       (injected as @EnvironmentObject)
|
+-- Views
|   +-- RootView            Tab shell (Feed / Map / About / Feedback)
|   +-- ListingFeedView     Searchable list, nearest-first
|   +-- AddListingView      Create form (photos, place search, time window)
|   +-- ListingDetailView
|   +-- FoodMapView         MapKit markers
|   +-- SettingsView        Country + distance filters
|   +-- AboutView / FeedbackView
|
+-- Services
|   +-- FoodListingStore       CloudKit public DB sync, expiry filtering
|   +-- LocationManager        Location permission and current location
|   +-- LocationSearchService  MapKit place search
|   +-- AppSettings            Persisted user preferences
|
+-- Models
    +-- FoodListing
    +-- FoodListing+CloudKit   CKRecord <-> FoodListing mapping
```

**Storage.** There is no backend and no user account. `FoodListingStore` reads and writes the
**CloudKit public database** (`iCloud.com.tertiaryinfotech.freefood`) directly, so every user sees
the same listings, keyed off the device's iCloud identity.

Because CloudKit's public database is *eventually consistent*, a just-saved record is often missing
from the next query for a few seconds. Locally-saved records are held in a `pending` map and
overlaid on query results until a fetch confirms them, so a freshly-posted listing never flickers
out of the feed.

Expired listings are **hidden client-side** by an `isActive` filter — that is the guarantee users
see. Deleting them from the cloud is best-effort: CloudKit's public-DB rules let a device delete
only records its own user created, so other users' expired records linger in the database,
invisible to everyone. That is accepted, not a bug.

## Project Structure

```text
freefoodapp/
+-- freefoodapp.xcodeproj/
+-- freefoodapp/
|   +-- Assets.xcassets/
|   +-- Models/
|   |   +-- FoodListing.swift
|   |   +-- FoodListing+CloudKit.swift
|   +-- Services/
|   |   +-- AppSettings.swift
|   |   +-- FoodListingStore.swift
|   |   +-- LocationManager.swift
|   |   +-- LocationSearchService.swift
|   +-- Views/
|   |   +-- AboutView.swift
|   |   +-- AddListingView.swift
|   |   +-- FeedbackView.swift
|   |   +-- FoodMapView.swift
|   |   +-- ListingDetailView.swift
|   |   +-- ListingFeedView.swift
|   |   +-- RootView.swift
|   |   +-- SettingsView.swift
|   +-- Info.plist
|   +-- PrivacyInfo.xcprivacy
|   +-- freefoodapp.entitlements
|   +-- freefoodappApp.swift
+-- .github/workflows/
|   +-- ios-release.yml        Build + upload + submit to App Store on push to main
+-- scripts/
|   +-- ci_submit.py           App Store Connect API helper used by CI
+-- docs/
|   +-- screenshot-feed.png
|   +-- screenshot-detail.png
|   +-- screenshot-map.png
+-- CHANGELOG.md
+-- ExportOptions.plist
+-- screenshot.png
+-- README.md
```

## Getting Started

### Prerequisites

- macOS with Xcode 16 or newer
- iOS 17+ simulator or device
- Git

### Clone

```sh
git clone https://github.com/alfredang/freefoodapp.git
cd freefoodapp
```

### Run in Xcode

1. Open `freefoodapp.xcodeproj`.
2. Select the `freefoodapp` scheme.
3. Choose an iOS simulator or connected device.
4. Press Run.

### Build from Terminal

```sh
xcodebuild \
  -project freefoodapp.xcodeproj \
  -scheme freefoodapp \
  -configuration Debug \
  -sdk iphonesimulator \
  build
```

## Data & Privacy

- Listings are stored in the **CloudKit public database** (`iCloud.com.tertiaryinfotech.freefood`) so they are shared across all users. Anyone can browse without an account; posting requires the device to be signed into iCloud.
- The app requests location access to rank nearby listings and show user-location map controls.
- Food listing photos are selected through PhotosUI and stored as CloudKit `CKAsset`s (up to 3 per listing).
- No separate account or password is required; CloudKit uses the device's iCloud identity.

## Deployment

This is a native iOS app. For App Store or TestFlight distribution, archive the app in Xcode or use:

```sh
xcodebuild \
  -project freefoodapp.xcodeproj \
  -scheme freefoodapp \
  -configuration Release \
  -archivePath build/freefoodapp.xcarchive \
  archive
```

Export options can be configured through `ExportOptions.plist`.

Releases are automated: pushing app-code changes to `main` triggers
[`.github/workflows/ios-release.yml`](.github/workflows/ios-release.yml), which builds, signs,
uploads the build to App Store Connect, and submits it for review. Changes limited to docs, CI, or
`scripts/` are ignored by that workflow and will not trigger a submission.

## Roadmap

- Listing moderation and reporting.
- Push notifications for nearby food drops.
- Better distance formatting and location simulation defaults for screenshots/tests.
- UI tests for listing creation, search, and map navigation.

## Contributing

Contributions are welcome through issues and pull requests.

1. Fork the repository.
2. Create a feature branch.
3. Commit focused changes.
4. Open a pull request with a clear description and screenshots for UI changes.

## Developed By

Tertiary Infotech Academy Pte. Ltd.

## License

No license file is currently included. Add a license before distributing or accepting external contributions.
