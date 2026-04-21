# GymTracker

A native iOS workout tracking app built with SwiftUI and Core Data. Supports strength training, cardio, swimming, cycling, yoga, HIIT, and custom activities.

## Features

- **Workout logging** — Log sets with weight/reps, distance/time, laps/time, duration-only, or custom metrics depending on the activity type
- **Activity library** — 50+ preset activities across 7 categories, plus the ability to create custom activities
- **Edit workouts** — Go back and correct any previously logged workout
- **Personal records** — Flag sets as PR attempts; a celebration screen fires when a genuine new record is confirmed against your history
- **Pre-fill sets** — "Add Set" copies the previous set's values as a starting point
- **Body measurements** — Log weight and body fat over time with a historical chart in your profile
- **Profile photo** — Pick a photo from your library for your profile
- **Unit localisation** — Automatically uses kg/km/cm or lbs/miles/ft-in based on the device locale
- **iCloud sync** — Workouts sync across devices via CloudKit when the user is signed into iCloud
- **Print** — Print a single workout or a summary over a custom date range, formatted for paper

## Requirements

- Xcode 16+
- iOS 18.0+ deployment target
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- An Apple Developer account with iCloud/CloudKit capability enabled (for sync)

## Getting Started

```bash
git clone <repo>
cd GymTracker
xcodegen generate
open GymTracker.xcodeproj
```

Build and run on an iOS 18 simulator or device.

> **iCloud sync:** To enable sync, open the project in Xcode, go to **Signing & Capabilities**, add the **iCloud** capability, and select (or create) the `iCloud.com.chrisharrington.GymTracker` container. Without this step the app runs fully offline.

## Architecture

| Layer | Details |
|---|---|
| UI | SwiftUI, iOS 18 |
| Persistence | Core Data (`NSPersistentCloudKitContainer`) |
| Charts | Swift Charts |
| Project generation | xcodegen (`project.yml`) |
| Testing | XCTest unit tests in `GymTrackerTests/` |

### Key files

```
GymTracker/
├── Model/
│   ├── GymTracker.xcdatamodeld/   Core Data model (manual NSManagedObject codegen)
│   ├── ActivityCategory.swift     ActivityCategory + PrimaryMetric enums
│   ├── Units.swift                All unit conversion and display formatting
│   ├── PRDetector.swift           Pure personal-record detection logic
│   ├── WorkoutHTMLFormatter.swift HTML generation for printing
│   ├── PrintCoordinator.swift     UIKit bridge to UIPrintInteractionController
│   ├── CloudSyncMonitor.swift     Observes CKAccountStatus for iCloud sync UI
│   ├── Persistence.swift          Core Data + CloudKit stack
│   └── CDModels/                  One file per entity (CoreDataClass + Helpers)
└── Views/
    ├── Workout/
    │   ├── LogWorkoutView.swift    Log and edit workouts
    │   ├── WorkoutDetailView.swift Read-only detail + print button
    │   ├── WorkoutListView.swift   History list + print summary
    │   └── PrintSummaryView.swift  Date-range picker for summary printing
    └── Profile/
        └── ProfileView.swift       Stats, measurements, iCloud sync status
```

## Running Tests

Tests live in `GymTrackerTests/`. Run them from Xcode (`⌘U`) or via `xcodebuild`:

```bash
xcodebuild test \
  -project GymTracker.xcodeproj \
  -scheme GymTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Coverage includes unit conversion, PR detection, input filtering, HTML formatting, and all Core Data model helpers.

## Known Issues

- Xcode 26 beta emits a non-fatal `actool` simulator runtime warning during command-line builds — harmless, does not affect the running app.
- Run `xcodegen generate` after modifying `project.yml` (e.g. adding new source files or targets).
