# Flask HTR API

Backend API untuk Handwritten Text Recognition (HTR) menggunakan CRNN BiLSTM 2×256.

Dirancang untuk integrasi dengan aplikasi mobile Flutter.

---

## 📋 Fitur

✅ **Line-level Recognition** - Pengenalan text dari gambar satu baris  
✅ **Paragraph Recognition** - Pengenalan text dari gambar paragraph dengan line segmentation  
✅ **Beam Search Decoding** - Decoding dengan Beam Search + Language Model  
✅ **Image Preprocessing** - Resize, normalize, padding otomatis  
✅ **RESTful API** - Easy integration dengan client apps  
✅ **CORS Support** - Compatible dengan Flutter apps  
✅ **Health Check** - Monitoring endpoint  

---

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd "D:\Dokumen Kuliah\TA\Kode Kaggle\Integrasi_Mobile\FlaskAPI"
pip install -r requirements.txt
```

### 2. Run Server Locally

```bash
python app.py
```

Output:
```
 * Running on http://127.0.0.1:5000
 * WARNING: This is a development server. Do not use it in a production deployment.
```

API tersedia di: **http://localhost:5000**

### 3. Test API (Local)

#### Health Check
```bash
curl http://localhost:5000/api/health
```

Response:
```json
{
  "status": "ok",
  "timestamp": "2026-03-16T10:30:45.123456",
  "model": "ready",
  "version": "1.0.0"
}
```

#### Line Recognition
```bash
curl -X POST http://localhost:5000/api/recognize/line \
  -F "file=@path/to/image.jpg"
```

---

## 📱 Public Hosting dengan Ngrok

### 1. Install Ngrok

Download dari: https://ngrok.com/download

### 2. Run Flask App (di satu terminal)

```bash
python app.py
```

### 3. Expose dengan Ngrok (di terminal baru)

```bash
ngrok http 5000
```

Output:
```
ngrok by @inconshreveable
...
Session Status                online
Account                       Free
Version                       3.3.5
Region                        Singapore (sg)
Forwarding                    https://abc123.ngrok.io -> http://localhost:5000
Web Interface                 http://127.0.0.1:4040
```

**Public API URL**: `https://abc123.ngrok.io`

Gunakan URL ini di Flutter app!

---

## 📡 API Endpoints

### 1. Health Check
```
GET /api/health
```
**Purpose**: Check if server is running and model is loaded

**Response**:
```json
{
  "status": "ok",
  "timestamp": "2026-03-16T10:30:45.123456",
  "model": "ready",
  "version": "1.0.0"
}
```

---

### 2. Model Info
```
GET /api/model/info
```
**Purpose**: Get model configuration and info

**Response**:
```json
{
  "model_name": "CRNN BiLSTM 2x256",
  "num_classes": 80,
  "input_size": [64, 512],
  "decoder_type": "Beam Search",
  "beam_width": 10,
  "has_language_model": true,
  "device": "cuda"
}
```

---

### 3. Line Recognition
```
POST /api/recognize/line
```

**Purpose**: Recognize text from a single line image

**Request Format (Multipart)**:
```
- file: [image file]
- use_beam_search: boolean (optional, default: true)
```

**Or JSON with Base64**:
```json
{
  "image_base64": "iVBORw0KGgoAAAANSUhEUgAAA...",
  "use_beam_search": true
}
```

**Response**:
```json
{
  "success": true,
  "text": "The quick brown fox",
  "confidence": null,
  "processing_time_ms": 245,
  "method": "beam_search"
}
```

---

### 4. Paragraph Recognition
```
POST /api/recognize/paragraph
```

**Purpose**: Recognize text from paragraph/form image

**Request Format (Multipart)**:
```
- file: [image file]
- segmentation_method: "projection" or "contours" (optional, default: "projection")
- use_beam_search: boolean (optional, default: true)
- crop_mode: null | "auto" | "manual" | (float, float) (optional)
```

**Response**:
```json
{
  "success": true,
  "text": "First line\nSecond line\nThird line",
  "lines": ["First line", "Second line", "Third line"],
  "line_count": 3,
  "processing_time_ms": 890,
  "segmentation_method": "projection",
  "method": "beam_search"
}
```

---

### 5. Image Preprocessing Debug
```
POST /api/preprocess
```

**Purpose**: Debug image preprocessing pipeline

**Request**:
```
- file: [image file]
```

**Response**:
```json
{
  "success": true,
  "original_size": {"height": 640, "width": 480},
  "processed_size": {"height": 64, "width": 512},
  "image_preview": "iVBORw0KGgoAAAANSUhEUgAAA..."
}
```

---

## 🛠️ Configuration

Edit `config.py` untuk customize:

```python
# Model paths
MODEL_PATH = Path(r"D:\path\to\best_model.pt")
LM_PATH = Path(r"D:\path\to\char_5gram.json")

# Server
HOST = '0.0.0.0'
PORT = 5000

# Model
DEVICE = 'cuda' or 'cpu'
LINE_HEIGHT = 64
LINE_WIDTH = 512

# Decoding
BEAM_WIDTH = 10
LM_WEIGHT = 0.1
LENGTH_BONUS = 0.5
```

---

## 🐛 Troubleshooting

### Error: "Model not found"
→ Update `MODEL_PATH` di `config.py` dengan path yang benar

### Error: "CUDA out of memory"
→ Edit `config.py`, ubah `DEVICE = 'cpu'`

### Error: "LM not found"
→ API akan tetap berjalan dengan Greedy decoding (less accurate)

### Port sudah digunakan
```bash
# Find process using port 5000
netstat -ano | findstr :5000

# Kill process (Windows)
taskkill /PID [PID] /F

# Atau gunakan port lain
python app.py --port 5001
```

---

## 📊 Performance Tips

1. **Use GPU** - Pastikan PyTorch CUDA installed untuk kecepatan
2. **Reduce Image Size** - Preprocessing lebih cepat untuk gambar kecil
3. **Batch Processing** - Recognise banyak line sekaligus (future: batching endpoint)
4. **Cache Model** - Model di-load sekali, reuse untuk semua inference

---

## 🔄 Flutter Integration

### Example: Line Recognition Request

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class HTRService {
  final String apiUrl = 'https://your-ngrok-url.ngrok.io';
  
  Future<String> recognizeLine(XFile image) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiUrl/api/recognize/line'),
    );
    
    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
    );
    
    var response = await request.send();
    
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(
        await response.stream.bytesToString()
      );
      return jsonResponse['text'];
    } else {
      throw Exception('Failed to recognize text');
    }
  }
}
```

---

## 📝 Logging

Logs tersimpan di folder `logs/`

View logs:
```bash
# Linux/Mac
tail -f logs/app.log

# Windows
Get-Content logs/app.log -Tail 20 -Wait
```

---

## 🔒 Security Notes

⚠️ **DEVELOPMENT MODE** - Jangan gunakan untuk production tanpa security enhancement:
- Add authentication (API key, JWT)
- Enable HTTPS (SSL certificate)
- Rate limiting
- Input validation
- CORS restrictions

---

## 📦 Requirements

- Python 3.8+
- PyTorch 2.0+
- CUDA 11.8+ (optional, untuk GPU support)
- 4GB RAM minimum (8GB recommended)
- 1GB disk space untuk model

---

## 📄 License & Attribution

Model: CRNN BiLSTM 2×256  
Dataset: IAM Handwriting Database  
Language Model: 5-gram character LM  

---

## 📞 Support

Issues? Questions?
- Check `config.py` paths
- Review logs in `logs/` folder
- Test endpoint dengan curl first
- Ensure model checkpoint exists

---

**Last Updated**: March 16, 2026  
**Status**: ✅ Ready for Development
