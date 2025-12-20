# DataLogger

A comprehensive data logging application for vehicle testing and annotation.

## Features

- **5 Recording Categories**: Weather, Road Type, Lighting, Traffic, Speed
- **Simultaneous Recording**: Track one condition per category at a time
- **Session Management**: Driver, Annotator, Date, Vehicle, RSU No, Drive ID
- **Automatic Notifications**: Alerts at 20 minutes, then every 30 minutes (50, 80, 110...)
- **CSV Export**: Export all data with overall session time
- **Auto-save**: Data persists between sessions
- **Cross-platform**: Works on Android, iOS, and Web

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or higher
- For Android: Android Studio with Android SDK
- For iOS: Xcode on macOS
- For Web: Chrome, Safari, Edge, or Firefox

### Installation

1. Clone the repository:
```bash
git clone https://github.com/saichowdary956-hash/datalogger.git
cd datalogger
```

2. Install dependencies:
```bash
flutter pub get
```

### Running the App

**Web:**
```bash
flutter run -d chrome
```

**Android:**
```bash
flutter run -d android
```

**iOS (macOS only):**
```bash
flutter run -d ios
```

### Building Release Versions

**Web:**
```bash
flutter build web
```

**Android APK:**
```bash
flutter build apk --release
```

**iOS (macOS only):**
```bash
flutter build ios --release
```

## Live Demo

Visit: https://saichowdary956-hash.github.io/datalogger/

## Project Structure

```
datalogger/
├── lib/
│   └── main.dart          # Main Flutter application
├── web/
│   ├── index.html         # Web entry point
│   └── manifest.json      # PWA manifest
├── android/               # Android configuration
├── ios/                   # iOS configuration
├── app.html              # Standalone HTML/JS version (PWA)
└── pubspec.yaml          # Dependencies
```

## Usage

1. Fill in session details (Driver, Annotator, Date, etc.)
2. Select conditions from each category to start recording
3. Multiple categories can record simultaneously
4. Use category-specific reset buttons to clear individual categories
5. Click "Stop All" to stop all active recordings
6. Export data to CSV with overall session time

## License

See [LICENSE](LICENSE) file for details.
