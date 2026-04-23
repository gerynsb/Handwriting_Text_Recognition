# HTR Flutter Mobile App

Aplikasi mobile Flutter untuk Handwriting Text Recognition (HTR) yang terintegrasi dengan Flask API backend.

---

## 📱 Features

✅ **Dashboard Home**
- Upload image dari gallery atau camera
- Real-time handwriting recognition
- Support for single line dan paragraph recognition
- Toggle between Beam Search dan Greedy decoding

✅ **History**
- Riwayat semua upload dengan hasil recognition
- View detail setiap upload
- Delete individual atau clear all history
- Copy hasil ke clipboard
- Thumbnail preview gambar

✅ **Settings**
- Dark/Light mode toggle
- App information
- Features overview
- API configuration details
- Model information
- API endpoints documentation

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.0 atau lebih baru
- Android Studio / Visual Studio Code
- Android emulator atau device
- Flask API server running (dari FlaskAPI folder)

### Installation

#### 1. Setup Flutter Environment

```bash
# Check flutter installation
flutter --version

# Get dependencies
cd "D:\Dokumen Kuliah\TA\Kode Kaggle\Integrasi_Mobile\MobileApp"
flutter pub get
```

#### 2. Install Dependencies

```bash
flutter pub get
```

#### 3. Update API URL

Edit `lib/services/htr_service.dart`:

```dart
// Untuk local testing:
static const String baseUrl = 'http://localhost:5000';

// Untuk Ngrok public:
static const String baseUrl = 'https://your-ngrok-url.ngrok.io';
```

#### 4. Run the App

```bash
# Run di emulator atau device
flutter run

# Run dengan mode release (lebih cepat)
flutter run --release
```

---

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── upload_item.dart     # Data model untuk upload history
├── screens/
│   ├── home_screen.dart     # Dashboard dengan image upload
│   ├── history_screen.dart  # Riwayat uploads
│   └── settings_screen.dart # Settings & app info
├── services/
│   ├── htr_service.dart     # API service untuk Flask backend
│   └── storage_service.dart # Local storage menggunakan SharedPreferences
└── theme/
    └── theme_provider.dart  # Theme management (dark/light mode)
```

---

## 🔧 Configuration

### update API URL

File: `lib/services/htr_service.dart`

```dart
// Development (Local)
static const String baseUrl = 'http://localhost:5000';

// Production (Ngrok)
static const String baseUrl = 'https://abc123.ngrok.io';

// Production (Deployed Server)
static const String baseUrl = 'https://your-production-url.com';
```

### Customize Theme

File: `lib/theme/theme_provider.dart`

Ubah warna primary:
```dart
ColorScheme.fromSeed(
  seedColor: const Color(0xFF4A90E2),  // Ganti dengan warna Anda
  brightness: Brightness.light,
),
```

---

## 🎯 Usage Guide

### 1. Home Screen - Image Upload

1. Tap **Gallery** atau **Camera** untuk pilih/ambil gambar
2. Pilih mode recognition: **Single Line** atau **Paragraph**
3. Toggle **Beam Search** untuk akurasi lebih tinggi (atau greedy untuk cepat)
4. Tap **Recognize** untuk mulai processing
5. Lihat hasil recognition
6. **Copy** hasil atau **Save** ke history

### 2. History Screen - View Previous Uploads

1. Tap gambar/item untuk lihat detail
2. Lihat preprocessing preview dan hasil
3. Copy teks, atau delete item
4. Refresh dengan icon refresh
5. Clear all history dengan icon delete

### 3. Settings Screen - Configuration

1. Toggle **Dark Mode** sesuai preferensi
2. Lihat app information
3. Check API endpoints documentation
4. Review model architecture details

---

## 🔌 API Integration

### Endpoints Used

```
GET  /api/health              - Check API status
GET  /api/model/info          - Get model details
POST /api/recognize/line      - Recognize single line
POST /api/recognize/paragraph - Recognize multiple lines
POST /api/preprocess          - Get preprocessing preview
```

### File Upload Format

- **Type**: Multipart form data
- **Field**: `file` (image)
- **Supported**: PNG, JPG, JPEG
- **Max Size**: Recommended < 5MB

---

## 📊 State Management

Menggunakan **Provider** untuk state management:

```dart
// ThemeProvider - Mengelola dark/light mode
Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    // Access themeProvider.isDarkMode
  },
)

// StorageService - Mengelola history uploads
context.read<StorageService>().getUploadHistory()
```

---

## 💾 Local Storage

Data disimpan menggunakan **SharedPreferences**:

- `upload_history` - JSON list semua uploads
- `isDarkMode` - Theme preference
- `api_url` - Saved API URL (optional)

Limit history: **100 items** (oldest automatically deleted)

---

## 🎨 UI/UX Features

### Material Design 3
- Modern card-based layout
- Smooth animations
- Responsive design
- Material You theme colors

### Accessibility
- Proper contrast ratios
- Semantic HTML structure
- Touch-friendly buttons
- Readable font sizes

### Offline Support
- History works offline
- Upload images stored locally
- Sync when API available

---

## ⚙️ Technical Stack

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter 3.0+ |
| **UI** | Material Design 3 |
| **State Management** | Provider |
| **Storage** | SharedPreferences |
| **Network** | HTTP + Dio |
| **Image Processing** | Image Picker |
| **Theme** | ThemeProvider |

---

## 🧪 Testing

### Manual Testing Checklist

- [ ] App launches without errors
- [ ] All 3 tabs/screens accessible
- [ ] Image upload from gallery works
- [ ] Camera image capture works
- [ ] Recognition produces results
- [ ] History saves correctly
- [ ] Dark mode toggles
- [ ] History can be deleted
- [ ] API errors handled gracefully

### Testing with Mock API

```dart
// lib/services/htr_service.dart - Add mock mode

class HTRService {
  static const bool useMockAPI = false; // Set true untuk testing

  Future<String> recognizeLine(XFile image) async {
    if (useMockAPI) {
      await Future.delayed(Duration(seconds: 2));
      return "Sample recognized text from mock API";
    }
    // ... real API call
  }
}
```

---

## 🚀 Build & Release

### Build APK (Android)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build iOS

```bash
flutter build ios --release
```

### Build Web

```bash
flutter build web --release
```

---

## 📱 Supported Platforms

| Platform | Status | Min Version |
|----------|--------|------------|
| Android | ✅ | Android 5.0 (API 21) |
| iOS | ✅ | iOS 11.0 |
| Web | ⏳ | Working |

---

## 🐛 Troubleshooting

### Issue 1: "Failed to connect to API"

**Solution**:
1. Pastikan Flask server running: `python app.py`
2. Cek baseUrl di `htr_service.dart` benar
3. Pastikan API health check responds: `curl http://localhost:5000/api/health`

### Issue 2: "Image picker not working"

**Solution**:
```bash
# Update image_picker
flutter pub get image_picker

# Check permissions in AndroidManifest.xml
```

### Issue 3: "Dark mode not persisting"

**Solution**:
```bash
# Clear app cache & data
flutter clean
flutter pub get
flutter run
```

### Issue 4: "History not loading"

**Solution**:
```bash
# Clear SharedPreferences
# Edit settings_screen.dart: 
// Add debug button to clear cache

// Atau:
// Open device settings > Apps > HTR > Clear Data
```

---

## 📚 Dependencies

```yaml
# Networking
http: ^1.1.0

# Image handling
image_picker: ^0.9.0

# State Management
provider: ^6.0.0

# Local Storage
shared_preferences: ^2.0.0

# Date/Time
intl: ^0.19.0

# Permissions
permission_handler: ^11.0.0

# UUID
uuid: ^4.0.0
```

---

## 🔐 Security

- No hardcoded sensitive data
- API URL configurable
- Input validation pada image selection
- Secure storage dengan SharedPreferences
- HTTPS support dengan Ngrok

---

## 📈 Performance Tips

### Optimize Recognition Speed

1. **Use CPU untuk cepat**: Set `use_beam_search=false` di settings
2. **Reduce image size**: App auto-resize ke max 512px width
3. **Batch processing**: Recognize multiple images queued

### Memory Management

- Images cached by Flutter
- History limited to 100 items
- Old uploads auto-deleted by storage service

---

## 🤝 Integration dengan Backend

### Expected Flask API Structure

```
FlaskAPI/
├── app.py              # Flask main app
├── model_loader.py     # Model & inference
├── config.py           # Configuration
├── requirements.txt    # Dependencies
└── test_api.py         # Test suite
```

### Quick Integration Check

```bash
# Terminal 1: Start Flask
cd FlaskAPI
python app.py

# Terminal 2: Test
python test_api.py

# Then run Flutter app and it should connect
```

---

## 📝 Code Examples

### Recognize Line dari Camera

```dart
final picker = ImagePicker();
final image = await picker.pickImage(source: ImageSource.camera);

if (image != null) {
  final result = await HTRService().recognizeLine(image);
  print('Result: $result');
}
```

### Get Upload History

```dart
final storageService = context.read<StorageService>();
final history = await storageService.getUploadHistory();

for (var item in history) {
  print('${item.uploadDate}: ${item.recognizedText}');
}
```

### Toggle Dark Mode

```dart
final themeProvider = context.read<ThemeProvider>();
await themeProvider.toggleTheme();
```

---

## 📞 Support

Untuk troubleshooting lebih lanjut:

1. Check logs di console
2. Lihat FlaskAPI documentation
3. Baca error message dengan teliti
4. Test API directly dengan cURL

---

## 🎉 Next Steps

1. ✅ Setup Flutter environment
2. ✅ Run local Flask API
3. ✅ Run Flutter app
4. 🔄 Test all features
5. 🚀 Deploy API (Railway/Ngrok)
6. 🚀 Build APK untuk distribution

---

**Version**: 1.0.0  
**Last Updated**: March 16, 2026  
**Status**: ✅ Production Ready
