# Build Instructions

## Platform Status

✅ **Web** - Ready to build and deploy
❌ **Android** - Requires Android Studio and Android SDK
❌ **iOS** - Requires macOS with Xcode

## Web Build (Works Now!)

```bash
C:\src\flutter\bin\flutter.bat build web --release
```

The built files will be in `build/web/` directory. Deploy these files to any web server or GitHub Pages.

## Android Build (Requires Setup)

### Prerequisites:
1. Install Android Studio from https://developer.android.com/studio
2. Open Android Studio and install Android SDK
3. Accept Android licenses: `C:\src\flutter\bin\flutter.bat doctor --android-licenses`

### Build APK:
```bash
C:\src\flutter\bin\flutter.bat build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### Install on Android Device:
```bash
C:\src\flutter\bin\flutter.bat install
```

## iOS Build (Requires macOS)

### Prerequisites:
- macOS computer
- Xcode installed from App Store
- Apple Developer account (for distribution)

### Build on macOS:
```bash
flutter build ios --release
```

### Alternative: Use PWA
Install the web version as a Progressive Web App:
1. Open https://saichowdary956-hash.github.io/datalogger/ on your iPhone
2. Tap Share button
3. Select "Add to Home Screen"

## Test Locally

### Web:
```bash
C:\src\flutter\bin\flutter.bat run -d chrome
```

### Android (with connected device or emulator):
```bash
C:\src\flutter\bin\flutter.bat run -d android
```

## Current Setup Summary

- ✅ Flutter SDK: C:\src\flutter
- ✅ Dependencies: installed (intl, shared_preferences)
- ✅ Web support: enabled
- ❌ Android SDK: not installed
- ❌ Visual Studio: not installed (for Windows desktop builds)
- ❌ Xcode: not available (Windows OS)
