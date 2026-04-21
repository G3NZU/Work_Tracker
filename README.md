# Work Tracker

A personal work-hour tracking app for Android, built with Flutter. Track time spent on projects, log breaks, review your history, and export monthly PDF reports — all stored locally on your device.

---

## Features

- **Start / Pause / Stop** a work session with a single tap
- **Break tracking** — pause mid-session and resume without losing time
- **Daily summary** — see today's total hours and number of sessions at a glance
- **History screen** — browse all past sessions grouped by day
- **Monthly report** — view total hours, session count, average hours per day, and a week-by-week breakdown
- **PDF export** — generate and share a formatted monthly report as a PDF
- **Persistent storage** — sessions survive app restarts and OS process kills (Hive local database)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | [Flutter](https://flutter.dev) (Dart, Material 3) |
| State management | [Provider](https://pub.dev/packages/provider) |
| Local storage | [Hive](https://pub.dev/packages/hive) + [hive_flutter](https://pub.dev/packages/hive_flutter) |
| PDF generation | [pdf](https://pub.dev/packages/pdf) + [printing](https://pub.dev/packages/printing) |
| Date formatting | [intl](https://pub.dev/packages/intl) |
| Unique IDs | [uuid](https://pub.dev/packages/uuid) |
| File paths | [path_provider](https://pub.dev/packages/path_provider) |

---

## Installation

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **≥ 3.0.0**
- Android SDK (API level 21+) — the app targets Android only
- A physical Android device or emulator

### Steps

1. **Clone the repository**

   ```bash
   git clone https://github.com/G3NZU/Work_Tracker.git
   cd Work_Tracker
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**

   Plug in a device (or start an emulator), then:

   ```bash
   flutter run
   ```

4. **Build a release APK** *(optional)*

   ```bash
   flutter build apk --release
   ```

   The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## How It Works

1. **Home screen** — Tap **Start Session** to begin tracking. The live timer shows elapsed work time, updated every second. Tap **Take a Break** to pause (break time is excluded from worked hours). Tap **Resume Work** to continue, or **Stop Session** to save and close the session.
2. **History screen** — Tap the history icon (top-right) to see all completed sessions grouped by day, with a daily total for each day.
3. **Monthly Report screen** — Tap the chart icon (top-right) to view aggregated statistics for any month. Use the arrow buttons to navigate between months. Tap **Export Monthly Report** to generate and share/print a PDF summary.
