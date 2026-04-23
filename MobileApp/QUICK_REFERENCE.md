# HTR Flutter Mobile App - Quick Reference & Assets Guide

Panduan cepat untuk struktur aset dan quick reference commands.

---

## 📁 Assets Structure

Buat folder berikut untuk menambah images, icons, dan fonts:

```
assets/
├── icons/              # App icons (16x16 hingga 512x512)
│   ├── app_icon.png
│   ├── home.png
│   ├── history.png
│   └── settings.png
├── images/             # General images
│   ├── splash.png
│   ├── logo.png
│   └── placeholder.png
├── animations/         # Lottie animations
│   ├── loading.json
│   ├── success.json
│   └── error.json
└── fonts/              # Custom fonts
    ├── Poppins-Regular.ttf
    ├── Poppins-Bold.ttf
    └── Poppins-SemiBold.ttf
```

### Update pubspec.yaml untuk Assets

```yaml
flutter:
  assets:
    - assets/icons/
    - assets/images/
    - assets/animations/
  
  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-Regular.ttf
        - asset: assets/fonts/Poppins-Bold.ttf
          weight: 700
```

---

## 🎨 Recommended Icon Sources

### Free Icon WebSites
- **Icons**: https://fonts.google.com/icons
- **Flaticons**: https://www.flaticon.com
- **Pexels**: https://www.pexels.com
- **Pixabay**: https://pixabay.com

### Custom Fonts
- **Google Fonts**: https://fonts.google.com
- **Font Awesome**: https://fontawesome.com
- **Material Icons**: Built-in Flutter

---

## ⚡ Quick Commands Cheatsheet

### Setup & Installation

| Command | Purpose |
|---------|---------|
| `flutter --version` | Check Flutter version |
| `flutter doctor` | Check environment setup |
| `flutter pub get` | Install dependencies |
| `flutter pub upgrade` | Update dependencies |
| `flutter clean` | Clean build |

### Running App

| Command | Purpose |
|---------|---------|
| `flutter run` | Run in debug mode |
| `flutter run --release` | Run in release mode |
| `flutter run --profile` | Run in profile mode |
| `flutter run -v` | Run with verbose output |
| `flutter devices` | List connected devices |

### Development

| Command | Purpose |
|---------|---------|
| `r` (in terminal) | Hot reload |
| `R` (in terminal) | Full restart |
| `q` (in terminal) | Quit app |
| `flutter logs` | Show logs |
| `flutter analyze` | Check code quality |
| `flutter format lib/` | Format code |

### Building

| Command | Purpose |
|---------|---------|
| `flutter build apk` | Build debug APK |
| `flutter build apk --release` | Build release APK |
| `flutter build ios` | Build iOS (macOS only) |
| `flutter build web` | Build web version |
| `flutter build appbundle` | Build App Bundle (Play Store) |

---

## 🔧 Configuration Quick Reference

### Change API URL

**File**: `lib/services/htr_service.dart`

```dart
// Line: ~10
static const String baseUrl = '';  // ← Change here

// Examples:
// Local: http://localhost:5000
// Ngrok: https://abc123.ngrok.io
// Production: https://api.yourdomain.com
```

### Change App Colors

**File**: `lib/theme/theme_provider.dart`

```dart
// Light theme primary color (Line: ~50)
seedColor: const Color(0xFF4A90E2),  // ← Blue

// Dark theme (Line: ~120)
seedColor: const Color(0xFF4A90E2),

// Material colors:
// Red: 0xFFEB5757
// Blue: 0xFF4A90E2
// Green: 0xFF27AE60
// Orange: 0xFFF39C12
```

### Change App Name

**File**: `pubspec.yaml`

```yaml
name: htr_flutter              # ← Change app name
description: Your description  # ← Change description

version: 1.0.0+1  # ← Update version
```

---

## 📱 Device Specific

### Android Device Commands

```bash
# List Android devices
flutter devices

# Connect via USB
# Settings → Developer Options → USB Debugging (ON)

# Connect via WiFi
adb connect 192.168.1.100:5555
flutter devices

# Run on specific device
flutter run -d device_id
```

### iOS Device Commands (macOS Only)

```bash
# List iOS devices
flutter devices

# Before running, open iOS project
open ios/Runner.xcworkspace

# Configure team signing in Xcode
# Then run
flutter run -d device_id
```

### Emulator Commands

```bash
# List emulators
flutter emulators

# Launch emulator
flutter emulators launch emulator_name

# Or from Android Studio
# Tools → Device Manager → Play
```

---

## 📊 Performance Monitoring

### Check App Size

```bash
# Check APK size
flutter build apk
ls -lh build/app/outputs/flutter-apk/app-release.apk

# Analyze what takes space
flutter analyze
```

### Monitor Runtime Performance

**In app code**:

```dart
// Add timing
final stopwatch = Stopwatch()..start();
// ... code ...
stopwatch.stop();
print('Took ${stopwatch.elapsedMilliseconds}ms');

// Memory info
print(Platform.localeName);
```

---

## 🐛 Debugging Tips

### Print Debugging

```dart
// Simple print
print('Value: $value');

// Conditional debugging
if (kDebugMode) {
  print('Debug mode only');
}

// Structure debugging
import 'dart:developer' as developer;
developer.Timeline.instantSync('Event name', arguments: {'key': 'value'});
```

### Widget Inspector

```bash
# Open Widget Inspector
# Flutter DevTools ini built-in dengan Flutter

# Terminal: Tekan 'i' saat app running
# Atau: Open Browser → DevTools URL
```

### Logcat Debugging (Android)

```bash
# Watch Android logs
adb logcat | grep flutter

# Or full verbose
flutter run -v
```

---

## 📁 Project File Quick Access

### Important Files

| Path | Purpose |
|------|---------|
| `lib/main.dart` | App entry point, navigation |
| `lib/screens/home_screen.dart` | Upload screen |
| `lib/screens/history_screen.dart` | History view |
| `lib/screens/settings_screen.dart` | Settings & info |
| `lib/services/htr_service.dart` | API communication |
| `lib/services/storage_service.dart` | Local storage |
| `lib/theme/theme_provider.dart` | Theme logic |
| `lib/models/upload_item.dart` | Data model |
| `pubspec.yaml` | Dependencies & config |

### Configuration Files

| Path | Purpose |
|------|---------|
| `android/app/build.gradle` | Android build config |
| `android/app/src/main/AndroidManifest.xml` | Permissions & config |
| `ios/Runner.xcodeproj` | iOS project |
| `web/index.html` | Web entry point |

---

## 🔄 Common Code Patterns

### Navigation Between Screens

```dart
// Already implemented in main.dart with BottomNavigationBar
// Tap on navigation item to switch screens
```

### HTTP Request Pattern

```dart
// See lib/services/htr_service.dart for full examples

try {
  final response = await http.post(
    Uri.parse('$baseUrl/endpoint'),
    // ... parameters
  ).timeout(Duration(seconds: 30));
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    // Handle success
  } else {
    // Handle error
  }
} catch (e) {
  // Handle exception
}
```

### State Management Pattern

```dart
// Using Provider (already setup)
Consumer<ThemeProvider>(
  builder: (context, provider, child) {
    // Access: provider.isDarkMode
    // Update: provider.toggleTheme()
  },
)
```

### Image Upload Pattern

```dart
final ImagePicker picker = ImagePicker();
final XFile? image = await picker.pickImage(
  source: ImageSource.gallery,
  imageQuality: 100,
);

if (image != null) {
  // Process image
}
```

---

## 🎯 Common Tasks Checklist

- [ ] **Change API URL**: Edit `htr_service.dart` line ~10
- [ ] **Change App Color**: Edit `theme_provider.dart` 
- [ ] **Add Custom Font**: Put in `assets/fonts/` & update `pubspec.yaml`
- [ ] **Add Icons**: Put in `assets/icons/` & update `pubspec.yaml`
- [ ] **Install New Package**: `flutter pub add package_name`
- [ ] **Remove Package**: Edit `pubspec.yaml` & `flutter pub get`
- [ ] **Build APK**: `flutter build apk --release`
- [ ] **Test on Device**: Connect via USB/WiFi & `flutter run`

---

## 📚 Useful Links

### Documentation
- [Flutter Official](https://flutter.dev)
- [Dart Documentation](https://dart.dev/guides)
- [Material Design](https://material.io/design)
- [Provider Documentation](https://pub.dev/packages/provider)

### Tools & Resources
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools)
- [Android Studio](https://developer.android.com/studio)
- [VS Code Flutter Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
- [Figma](https://figma.com) - UI Design

### Learning
- [Flutter YouTube Channel](https://www.youtube.com/c/flutterdev)
- [Codewithandrea](https://codewithandrea.com)
- [Fireship.io](https://fireship.io/courses/flutter/)

---

## 🚨 Emergency Fixes

### App Won't Start

```bash
flutter clean
rm -rf pubspec.lock
flutter pub get
flutter run
```

### Gradle Build Error

```bash
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

### Permission Error

```bash
# Run as administrator atau:
flutter doctor -v
flutter analyze
```

### Memory Error

```bash
# Reduce app size
flutter build apk --split-per-abi

# Or optimize images
# Convert PNG to WebP
```

---

## 💾 Backup & Recovery

### Backup Project

```bash
# Exclude build artifacts
7z a -x!build -x!.dart_tool app_backup.zip .

# Or
tar -czf app_backup.tar.gz --exclude=build --exclude=.dart_tool .
```

### Restore from Backup

```bash
# Extract & reinstall
flutter pub get
flutter clean
flutter run
```

---

## 📞 Getting Help

**If something breaks:**

1. **Read the error** carefully
2. **Check**: `flutter doctor`
3. **Search**: Google the error message
4. **Try**: `flutter clean` & rebuild
5. **Check**: File paths & permissions
6. **Review**: Documentation for that package

**Resources:**
- Stack Overflow: tag `flutter`
- GitHub Issues: relevant package
- Flutter Community Discord

---

## ✅ Daily Development Checklist

**Every Day:**
- [ ] Check Flutter version: `flutter --version`
- [ ] Update dependencies: `flutter pub upgrade`
- [ ] Run diagnostics: `flutter doctor`

**Before Commits:**
- [ ] Format code: `flutter format lib/`
- [ ] Analyze: `flutter analyze`
- [ ] Test manually

**Before Release:**
- [ ] Version bump in pubspec.yaml
- [ ] Update API URL for production
- [ ] Build signed APK
- [ ] Test on real device
- [ ] Sign app

---

**Version**: 1.0.0  
**Last Updated**: March 16, 2026  
**Status**: ✅ Complete Reference
