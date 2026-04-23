# Flask HTR API - Setup Guide

Panduan lengkap setup Flask API untuk integrasi dengan Flutter app.

---

## 📦 Step 1: Install Dependencies

### A. Buka Terminal di folder FlaskAPI

```bash
cd "D:\Dokumen Kuliah\TA\Kode Kaggle\Integrasi_Mobile\FlaskAPI"
```

### B. Install Python Packages

```bash
pip install -r requirements.txt
```

**Note**: Jika ada error saat install PyTorch, coba:
```bash
# Dengan CUDA support (GPU)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# CPU only
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
```

---

## ⚙️ Step 2: Verify Model Path

Edit `config.py` dan pastikan path benar:

```python
MODEL_PATH = Path(
    r"D:\Dokumen Kuliah\TA\Kode Kaggle\Experiment\2_23_2026_Eksperiment_RNN\exp_architecture_rnn_20260223_042857\best_model.pt"
)

LM_PATH = Path(
    r"D:\Dokumen Kuliah\TA\Kode Kaggle\Experiment\2_25_2026_Advanced_Deslanting++_Final\language_model\char_5gram.json"
)
```

Cek file exists:
- [ ] `best_model.pt` exists?
- [ ] `char_5gram.json` exists?

Jika path salah, app akan error saat startup!

---

## ▶️ Step 3: Run Flask Server (Locally)

Terminal 1: Start Flask app

```bash
python app.py
```

Expected output:
```
 * Serving Flask app 'app'
 * Debug mode: off
 * WARNING: This is a development server
 * Running on http://0.0.0.0:5000
```

Server sekarang listen di **http://localhost:5000**

---

## 🧪 Step 4: Test API (Local)

### Terminal 2: Test dengan curl

```bash
# Health check
curl http://localhost:5000/api/health

# Model info
curl http://localhost:5000/api/model/info
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2026-03-16T...",
  "model": "ready"
}
```

### Or run Python test script:

```bash
python test_api.py
```

---

## 🌐 Step 5: Public Hosting dengan Ngrok

### A. Download & Install Ngrok

1. Visit: https://ngrok.com/download
2. Download yang sesuai OS Anda
3. Extract zip file
4. Add ke PATH (optional, atau gunakan full path)

### B. Run Ngrok (di Terminal 3)

```bash
# Jika sudah di PATH:
ngrok http 5000

# Atau full path:
"C:\path\to\ngrok.exe" http 5000
```

Expected output:
```
ngrok by @inconshreveable
Session Status    online
Region           Singapore (sg)
Forwarding       https://abc123.ngrok.io -> http://localhost:5000
Web Interface    http://127.0.0.1:4040
```

**Gunakan URL ini di Flutter**: `https://abc123.ngrok.io`

### C. Verify Ngrok Connection

Test from browser atau curl:
```bash
curl https://abc123.ngrok.io/api/health
```

---

## 📱 Step 6: Integrate dengan Flutter

### Create HTR Service di Flutter

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class HTRService {
  final String apiUrl = 'https://abc123.ngrok.io';  // Ganti dengan URL Anda
  
  Future<String> recognizeLine(XFile image) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiUrl/api/recognize/line'),
    );
    
    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
    );
    request.fields['use_beam_search'] = 'true';
    
    try {
      var response = await request.send();
      
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(
          await response.stream.bytesToString()
        );
        
        if (jsonResponse['success']) {
          return jsonResponse['text'];
        } else {
          throw Exception(jsonResponse['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }
  
  Future<List<String>> recognizeParagraph(XFile image) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiUrl/api/recognize/paragraph'),
    );
    
    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
    );
    request.fields['segmentation_method'] = 'projection';
    request.fields['use_beam_search'] = 'true';
    
    try {
      var response = await request.send();
      
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(
          await response.stream.bytesToString()
        );
        
        if (jsonResponse['success']) {
          return List<String>.from(jsonResponse['lines']);
        } else {
          throw Exception(jsonResponse['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }
}
```

### Use in Flutter UI

```dart
class HTRScreen extends StatefulWidget {
  @override
  State<HTRScreen> createState() => _HTRScreenState();
}

class _HTRScreenState extends State<HTRScreen> {
  final picker = ImagePicker();
  final htrService = HTRService();
  String recognizedText = '';
  bool isLoading = false;
  
  Future<void> pickAndRecognize() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    
    setState(() => isLoading = true);
    
    try {
      final text = await htrService.recognizeLine(image);
      setState(() => recognizedText = text);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recognized: $text')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('HTR')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: pickAndRecognize,
                child: Text('Pick & Recognize'),
              ),
            SizedBox(height: 20),
            if (recognizedText.isNotEmpty)
              Text(recognizedText),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔍 Troubleshooting

### Error 1: "Module not found: model_loader"
**Solution**: Pastikan file `model_loader.py` ada di folder FlaskAPI

### Error 2: "Model not found: best_model.pt"
**Solution**: Update `MODEL_PATH` di `config.py` dengan path yang benar

### Error 3: "Connection refused" di Flutter
**Mungkin penyebab**:
- Flask server tidak running
- Ngrok URL salah/expired
- Firewall blocking
- URL belum update di Flutter

**Solution**:
```
1. Restart Flask server
2. Restart Ngrok (akan generate URL baru)
3. Update URL di Flutter app
4. Check firewall settings
```

### Error 4: "CUDA out of memory"
**Solution**: Edit `config.py`:
```python
DEVICE = 'cpu'  # Gunakan CPU instead
```

### Error 5: Ngrok URL expires
Ngrok free version URL berubah setiap 2 jam. Solution:
```
1. Restart Ngrok (akan generate URL baru)
2. Update URL di Flutter app
3. Atau: upgrade ke Ngrok paid plan untuk static URL
```

---

## 📊 Performance Tips

1. **Input Image Size**
   - Lebih kecil → lebih cepat preprocessing
   - Recommended: 64 height, 512 width max
   - Format: Grayscale (L) atau RGB

2. **Decoding Method**
   - `use_beam_search=true` → Lebih akurat, lebih lambat (~200-300ms)
   - `use_beam_search=false` → Greedy, lebih cepat (~50-100ms)

3. **GPU vs CPU**
   - GPU: 100-200ms per image
   - CPU: 300-500ms per image

4. **Segmentation Method (untuk paragraph)**
   - `projection` → Cepat, cocok untuk clean documents
   - `contours` → Lebih robust, tapi lebih lambat

---

## 📋 Checklist

Setup checklist sebelum integrate dengan Flutter:

- [ ] Python 3.8+ installed
- [ ] Dependencies installed via `pip install -r requirements.txt`
- [ ] Model path correct di `config.py`
- [ ] `best_model.pt` file exists
- [ ] `char_5gram.json` exists
- [ ] Flask app runs without error
- [ ] Health endpoint responds OK
- [ ] Ngrok installed
- [ ] Ngrok tunnel working
- [ ] Flutter can reach Ngrok URL
- [ ] Test image recognition works
- [ ] Flutter service created
- [ ] Flutter UI integrated

---

## 📚 Next Steps

After Flask API is working:

1. Create Flutter app
2. Add Flutter dependencies:
   ```yaml
   dependencies:
     http: ^1.1.0
     image_picker: ^0.9.0
   ```
3. Create HTR service (see Step 6)
4. Create UI screens
5. Test with real images
6. Deploy to Play Store/App Store

---

## 🆘 Need Help?

1. Read `README.md` for API documentation
2. Check logs in Flask terminal
3. Run `python test_api.py` to debug
4. Verify paths in `config.py`
5. Check internet connection (especially for Ngrok)

---

**Status**: ✅ Ready to go!  
**Date**: March 16, 2026  
**Version**: 1.0.0
