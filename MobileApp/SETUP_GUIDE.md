# Flutter App Setup Guide - Step by Step

Panduan lengkap setup Flutter app dari nol sampai bisa jalan.

---

## ⚡ Quick Start (5 Minutes)

### Step 1: Check Flutter Installation

```bash
flutter --version
```

Expected output: `Flutter 3.0.0` atau lebih baru

### Step 2: Get Dependencies

```bash
cd "D:\Dokumen Kuliah\TA\Kode Kaggle\Integrasi_Mobile\MobileApp"
flutter pub get
```

### Step 3: Update API URL

Edit file: `lib/services/htr_service.dart`

```dart
// Untuk local development:
static const String baseUrl = 'http://localhost:5000';

// Atau untuk Ngrok:
// static const String baseUrl = 'https://your-ngrok-url.ngrok.io';
```

### Step 4: Run the App

```bash
flutter run
```

**Done!** App sekarang running. ✅

---

## 📋 Detailed Setup Steps

### Step 1: Install Flutter SDK

**If not installed yet:**

1. Download dari: https://flutter.dev/docs/get-started/install
2. Extract ke folder: `D:\Flutter\`
3. Add ke PATH environment variable:
   - Settings → System → Advanced → Environment Variables
   - Add: `D:\Flutter\bin`
4. Verify: `flutter --version`

### Step 2: Setup Android Development

```bash
# Accept Android licenses
flutter doctor --android-licenses

# Check setup
flutter doctor
```

Expected: Semua item menunjukkan ✅

### Step 3: Clone/Download Project

```bash
# Project sudah ada di:
# D:\Dokumen Kuliah\TA\Kode Kaggle\Integrasi_Mobile\MobileApp
```

### Step 4: Install Dependencies

```bash
cd MobileApp
flutter pub get
```

Ini akan download semua packages yang dibutuhkan.

### Step 5: Setup Android Emulator (Optional for Testing)

```bash
# Open Android Studio
# Tools → Device Manager → Create Device

# Or use device fisik via USB
```

### Step 6: Update API Configuration

#### Option A: Local Development (localhost)

File: `lib/services/htr_service.dart`

```dart
static const String baseUrl = 'http://localhost:5000';
```

Requirements:
- Flask API running: `python app.py` (dari FlaskAPI folder)
- Emulator/device terhubung ke network yang sama

#### Option B: Public Development (Ngrok)

File: `lib/services/htr_service.dart`

```dart
static const String baseUrl = 'https://abc123.ngrok.io';  // Ganti dengan URL Anda
```

Requirements:
- Ngrok running: `ngrok http 5000`
- Copy HTTPS URL dari Ngrok output

### Step 7: Run the App

```bash
# Terminal 1: Start Flask API
cd FlaskAPI
python app.py

# Terminal 2: Run Flutter
cd MobileApp
flutter run

# Terminal 3 (Optional): Start Ngrok if using public URL
ngrok http 5000
```

### Step 8: Test All Features

✅ **Home Tab**
- Upload image dari gallery
- Recognize text
- Try both single line & paragraph mode
- Save result to history

✅ **History Tab**
- View previous uploads
- Click to see details
- Copy text
- Delete items

✅ **Settings Tab**
- Toggle dark mode
- Check app information
- Verify API endpoints

---

## 🛠️ Troubleshooting

### Error 1: "pubspec.yaml not found"

**Solution**: Ensure you're in correct directory

```bash
cd "D:\Dokumen Kuliah\TA\Kode Kaggle\Integrasi_Mobile\MobileApp"
flutter pub get
```

### Error 2: "no devices connected"

**Solution**: Connect device atau start emulator

```bash
# List available devices
flutter devices

# If emulator not running:
# Open Android Studio → Tools → Device Manager → Play

# Or connect phone via USB
```

### Error 3: "SDK version mismatch"

**Solution**: Update Flutter

```bash
flutter upgrade
flutter pub get
flutter clean
flutter run
```

### Error 4: "Failed to connect to API"

**Solutions**:
1. Check Flask running: `curl http://localhost:5000/api/health`
2. Check baseUrl di htr_service.dart benar
3. Check network connectivity
4. Try with Ngrok URL instead of localhost

### Error 5: "Permission denied" (Camera/Gallery)

**Solution**: Check AndroidManifest.xml permissions

File: `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

If still issue, update permission_handler:

```bash
flutter pub get permission_handler
```

### Error 6: "Gradle error" during build

**Solution**:

```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

---

## 🔧 Configuration Files

### pubspec.yaml
- Contains app metadata & dependencies
- Change `version` untuk update version number
- Add new packages di `dependencies`

### lib/services/htr_service.dart
- **baseUrl**: Change API endpoint di sini
- Modify timeout values jika API slow

### lib/theme/theme_provider.dart
- **Primary Color**: Blue (#4A90E2) - change di sini
- **Light Theme**: Custom colors
- **Dark Theme**: Custom colors

### lib/models/upload_item.dart
- Data model untuk history
- Jangan ubah kecuali perlu tambahin fields

---

## 📱 Testing dengan Device

### Via USB

```bash
# Enable USB debugging di phone
# Settings → Developer Options → USB Debugging

# Connect via USB
flutter run

# Or specific device:
flutter run -d (device_id)
```

### Via Network

```bash
# Connect phone ke same WiFi as PC
# Phone: Enable TCP/IP debugging via ADB
flutter run -d wifi

# Or:
adb connect (phone_ip):5555
flutter run
```

---

## 🚀 Run Commands Reference

```bash
# Run di development mode
flutter run

# Run di release mode (faster)
flutter run --release

# Run specific device
flutter run -d emulator-5554

# Run dengan hot reload
flutter run --hot

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release

# Clean project
flutter clean

# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Analyze code
flutter analyze

# Format code
flutter format lib/

# Check project
flutter doctor
```

---

## 📊 Project Structure Quick Reference

```
MobileApp/
├── lib/
│   ├── main.dart                          # App entry
│   ├── screens/
│   │   ├── home_screen.dart              # Upload screen
│   │   ├── history_screen.dart           # History screen
│   │   └── settings_screen.dart          # Settings screen
│   ├── services/
│   │   ├── htr_service.dart             # API calls
│   │   └── storage_service.dart         # Local storage
│   ├── models/
│   │   └── upload_item.dart             # Data model
│   └── theme/
│       └── theme_provider.dart          # Theme logic
├── android/                               # Android native code
├── ios/                                   # iOS native code
├── pubspec.yaml                           # Dependencies & config
└── README.md                              # Documentation
```

---

## 🎯 Common Tasks

### Change App Name

1. Edit `pubspec.yaml`:
   ```yaml
   name: your_app_name
   ```

2. Android: `android/app/build.gradle`
   ```gradle
   defaultConfig {
       applicationId = "com.example.your_app"
   }
   ```

### Change App Icon

1. Put icon image: `assets/icon.png` (512x512)
2. Use online tool: https://appicon.co/
3. Place generated icons to `android/app/src/main/res/`

### Change Splash Screen

1. Edit: `android/app/src/main/AndroidManifest.xml`
2. Customize `android/app/src/main/res/drawable/launch_background.xml`

### Change App Colors

1. Edit: `lib/theme/theme_provider.dart`
2. Change seedColor & other colors
3. Rebuild app

---

## 🧪 Testing Scenario

### Scenario 1: Local Testing

**Terminal 1: Flask API**
```bash
cd FlaskAPI
python app.py
```

**Terminal 2: Flutter App**
```bash
cd MobileApp
flutter run
```

**baseUrl**: `http://localhost:5000`

### Scenario 2: Remote Testing (Ngrok)

**Terminal 1: Flask API**
```bash
cd FlaskAPI
python app.py
```

**Terminal 2: Ngrok Tunnel**
```bash
ngrok http 5000
# Get URL: https://abc123.ngrok.io
```

**Update in code**: Change baseUrl to Ngrok URL

**Terminal 3: Flutter App**
```bash
cd MobileApp
flutter run
```

---

## 📈 Performance Optimization

### Optimize Build Time

```bash
# Use profile mode (faster than debug, slower than release)
flutter run --profile

# Or release mode (fastest)
flutter run --release
```

### Optimize App Size

```bash
# Check dependencies
flutter analyze

# Remove unused packages from pubspec.yaml
flutter pub get
flutter build apk --release
```

---

## 🔐 Production Checklist

Before building APK untuk production:

- [ ] Update version di pubspec.yaml
- [ ] Change API URL to production endpoint
- [ ] Test all features thoroughly
- [ ] Verify permissions in AndroidManifest.xml
- [ ] Test on real device
- [ ] Check error handling
- [ ] Review privacy policy
- [ ] Generate app signing key
- [ ] Build signed APK

### Generate Signing Key

```bash
keytool -genkey -v -keystore htr_app.jks ^
  -keyalg RSA -keysize 2048 -validity 10000 ^
  -alias htr_key
```

### Build Signed APK

```bash
flutter build apk --release --extra-front-end-options=-Ddart.vm.profile=false
```

---

## 📚 Learning Resources

### Flutter Documentation
- https://flutter.dev/docs
- https://api.flutter.dev

### Provider State Management
- https://pub.dev/packages/provider
- https://codewithandrea.com/articles/state-management-riverpod/

### HTTP Networking
- https://pub.dev/packages/http
- https://www.youtube.com/watch?v=FPJiPjWNVAc

### Image Picker
- https://pub.dev/packages/image_picker
- https://www.youtube.com/watch?v=3FWPCANzB2M

---

## 💡 Tips & Tricks

### Hot Reload

During development, changes akan otomatis reload:
```bash
flutter run
# Make code change
# Press 'r' dalam terminal untuk hot reload
# Press 'R' untuk full restart
```

### Debug Mode

```bash
# Add print statements
print('Debug: $value');

# Or use debugPrint
import 'package:flutter/foundation.dart';
debugPrint('Debug: $value');

# Check logs
flutter logs
```

### Network Debugging

```dart
// Di htr_service.dart, add logging:
print('Request: $url');
print('Response: ${response.statusCode}');
print('Body: ${response.body}');
```

---

## ✅ Success Checklist

- [ ] Flutter installed dan working
- [ ] Project dependencies installed
- [ ] API URL configured
- [ ] Flask server running
- [ ] App runs tanpa error
- [ ] Home tab bisa upload image
- [ ] Recognition working
- [ ] History saves & loads
- [ ] Dark mode toggle working
- [ ] Settings screen accessible
- [ ] All error handling working

---

## 🎉 Ready to Go!

Sekarang aplikasi Anda siap digunakan. 

**Next steps:**
1. Test semua fitur
2. Build APK untuk testing di device
3. Deploy Flask API ke production
4. Update API URL untuk production
5. Distribute ke Play Store/App Store

---

**Support**: Jika ada masalah, check README.md atau troubleshooting section di atas.

**Version**: 1.0.0  
**Last Updated**: March 16, 2026  
**Status**: ✅ Ready
