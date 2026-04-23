# Flask HTR API - Troubleshooting Guide

Solusi untuk error dan masalah yang mungkin dihadapi saat setup dan menjalankan Flask API.

---

## ⚠️ Common Errors & Solutions

### Error 1: Module Not Found

**Error Message**:
```
ModuleNotFoundError: No module named 'torch'
ModuleNotFoundError: No module named 'flask'
```

**Penyebab**: Dependency belum diinstall

**Solusi**:
```bash
# Reinstall semua dependency
pip install -r requirements.txt -U

# Atau install satu-satu
pip install torch==2.0.1
pip install flask==2.3.0
pip install flask-cors==4.0.0

# Verify installation
python -c "import torch; print(torch.__version__)"
python -c "import flask; print(flask.__version__)"
```

---

### Error 2: Model File Not Found

**Error Message**:
```
FileNotFoundError: No such file or directory: '...\best_model.pt'
```

**Penyebab**: Path model di `config.py` salah

**Solusi**:

1. Cek file benar-benar ada:
```bash
# Windows PowerShell
Test-Path "D:\Dokumen Kuliah\TA\Kode Kaggle\Experiment\2_23_2026_Eksperiment_RNN\exp_architecture_rnn_20260223_042857\best_model.pt"
```

2. Copy-paste path yang benar ke `config.py`:
```python
# Jangan gunakan relative path, gunakan absolute path
MODEL_PATH = Path(r"D:\path\to\best_model.pt")
```

3. Jika file tidak ditemukan, buka File Explorer dan cari:
```
Experiment\2_23_2026_Eksperiment_RNN\...
```

---

### Error 3: CUDA Out of Memory

**Error Message**:
```
RuntimeError: CUDA out of memory. Tried to allocate X.XX GiB
```

**Penyebab**: GPU memory tidak cukup (biasanya terjadi dengan batch processing)

**Solusi**:

Option A: Gunakan CPU instead
```python
# Edit config.py
DEVICE = 'cpu'
```

Option B: Reduce batch size (jika ada)
```python
BATCH_SIZE = 1
```

Option C: Clear GPU cache
```python
import torch
torch.cuda.empty_cache()
```

Option D: Update PyTorch
```bash
pip install torch --upgrade
```

---

### Error 4: Port Already In Use

**Error Message**:
```
OSError: [WinError 10048] Only one usage of each socket address
Address already in use: ('0.0.0.0', 5000)
```

**Penyebab**: Port 5000 sudah digunakan proses lain

**Solusi Option A**: Stop proses yang menggunakan port

```bash
# Windows PowerShell - find process using port 5000
Get-NetTCPConnection -LocalPort 5000 | Select-Object -Property OwningProcess

# Kill process (ganti PID dengan nomor dari hasil di atas)
Stop-Process -Id <PID> -Force
```

**Solusi Option B**: Gunakan port lain

```bash
# Edit config.py
SERVER_PORT = 5001  # Ganti dengan port yang bebas

# Or run dengan argument
python app.py --port 5001
```

---

### Error 5: CORS Error dari Flutter

**Error Message** (di Flutter):
```
XMLHttpRequest error.
403: Forbidden
Access-Control-Allow-Origin not present
```

**Penyebab**: CORS tidak dikonfigurasi dengan benar

**Solusi**:

1. Check CORS di `app.py`:
```python
from flask_cors import CORS

# Harus ada baris ini sebelum route definition
CORS(app, resources={
    r"/api/*": {
        "origins": "*",  # Izinkan semua (untuk development)
        "methods": ["GET", "POST"],
        "allow_headers": ["Content-Type"]
    }
})
```

2. Jika masih error, test dengan curl:
```bash
curl -X POST \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  http://localhost:5000/api/health
```

3. Jika gunakan Ngrok, tambahkan header:
```bash
# Ngrok auth error
ngrok authtoken YOUR_TOKEN
```

---

### Error 6: Ngrok Not Found

**Error Message**:
```
'ngrok' is not recognized as an internal or external command
```

**Penyebab**: Ngrok belum diinstall atau tidak di PATH

**Solusi**:

1. Download dari https://ngrok.com/download
2. Extract zip file
3. Add ke PATH:

```bash
# Create folder untuk ngrok
mkdir C:\ngrok

# Extract folder zip ke C:\ngrok

# Add ke PATH: 
# Settings → System → Advanced system settings → Environment Variables
# Add: C:\ngrok
```

4. Atau gunakan full path:
```bash
C:\ngrok\ngrok.exe http 5000
```

---

### Error 7: Image Format Error

**Error Message**:
```
UnidentifiedImageError: cannot identify image file
PIL.UnidentifiedImageError: cannot open image file
```

**Penyebab**: Format gambar tidak didukung atau file corrupt

**Solusi**:

1. Cek format gambar (harus PNG, JPG, JPEG):
```bash
# Windows
wmic datafile where name="path\to\image.png" get Description
```

2. Coba buka di image viewer untuk confirm file tidak corrupt

3. Convert ke format didukung:
```python
from PIL import Image

img = Image.open('image.webp')  # Contoh format lain
img.save('image.png')  # Convert ke PNG
```

---

### Error 8: Timeout Error

**Error Message**:
```
requests.exceptions.ConnectTimeout: Connection timeout
socket.timeout: timed out
```

**Penyebab**: Koneksi ke API lambat atau server tidak respond

**Solusi**:

Option A: Increase timeout
```python
# Python client
response = requests.post(url, files=files, timeout=60)

# Dart/Flutter
final response = await request.send()
    .timeout(Duration(seconds: 60));
```

Option B: Check server status
```bash
curl http://localhost:5000/api/health
```

Option C: Check network
```bash
# Ping test
ping localhost

# DNS test
nslookup localhost
```

---

### Error 9: Memory Leak

**Error Message**:
```
MemoryError: Unable to allocate X GiB for an array
```

**Penyebab**: Memory tidak di-release setelah setiap inference

**Solusi**:

1. Tambahkan cleanup di `model_loader.py`:
```python
def recognize_line(self, image):
    try:
        # ... inference code ...
        return result
    finally:
        # Clear GPU cache
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
```

2. Monitor memory usage:
```python
import psutil

# In app.py health check
def health_check():
    memory = psutil.virtual_memory()
    return {
        'status': 'ok',
        'memory_percent': memory.percent,
        'memory_available_gb': memory.available / (1024**3)
    }
```

---

### Error 10: JSON Decode Error

**Error Message** (di Flutter):
```
FormatException: Unexpected character (at character 1)
```

**Penyebab**: Response dari server bukan JSON valid

**Solusi**:

1. Check response di curl:
```bash
curl http://localhost:5000/api/model/info
```

2. Ensure app.py return JSON:
```python
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({  # HARUS pakai jsonify()
        'status': 'ok',
        'timestamp': datetime.now().isoformat()
    })
```

3. Debug di Flask app:
```python
from flask import jsonify

@app.route('/api/test')
def test():
    import json
    data = {'test': 'data'}
    return jsonify(data)  # Correct
    # return json.dumps(data)  # Also correct, but jsonify() preferred
```

---

## 🔍 Debugging Steps

### Step 1: Enable Debug Mode

Edit `config.py`:
```python
FLASK_ENV = 'development'  # Or 'production'
DEBUG = True  # Enable debug mode
LOG_LEVEL = 'DEBUG'  # Verbose logging
```

### Step 2: Check Logs

```bash
# Flask terminal output
# Lihat error message di terminal saat app berjalan

# Atau save ke file
# python app.py > app.log 2>&1
```

### Step 3: Test dengan cURL

```bash
# Health check
curl http://localhost:5000/api/health -v

# Model info
curl http://localhost:5000/api/model/info -v

# Line recognition
curl -X POST \
  -F "file=@image.png" \
  -v \
  http://localhost:5000/api/recognize/line
```

### Step 4: Run Test Suite

```bash
python test_api.py

# Output akan show pass/fail untuk setiap endpoint
```

### Step 5: Monitor System Resources

```bash
# Windows PowerShell
Get-Process python | Select-Object Name, CPU, WorkingSet

# Linux/Mac
ps aux | grep python
```

---

## 🎯 Performance Debugging

### Slow Inference

**Problem**: Recognition memakan waktu > 500ms

**Solutions**:

1. Check if using GPU:
```python
import torch
print(f"Using device: {torch.cuda.is_available()}")
print(f"Device name: {torch.cuda.get_device_name(0)}")
```

2. Profile inference time:
```python
import time

start = time.time()
result = model(image)
end = time.time()

print(f"Inference time: {(end-start)*1000:.2f}ms")
```

3. Reduce model complexity:
   - Disable beam search: `use_beam_search=false`
   - Use greedy decoding (faster)

### High Memory Usage

**Problem**: Memory usage > 2GB

**Debug**:
```python
import tracemalloc
tracemalloc.start()

# ... inference code ...

current, peak = tracemalloc.get_traced_memory()
print(f"Current: {current/1024/1024:.2f}MB")
print(f"Peak: {peak/1024/1024:.2f}MB")
```

---

## 🚨 Logging & Monitoring

### Enable Detailed Logging

Edit `config.py`:
```python
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('htr_api.log'),
        logging.StreamHandler()
    ]
)
```

### Save Logs to File

```bash
# Run and save all output
python app.py > logs/api.log 2>&1 &

# Monitor live
tail -f logs/api.log
```

### Check for Errors

```bash
# Find all errors in log
grep -i "error\|exception\|failed" logs/api.log
```

---

## 📱 Flutter-Specific Issues

### Issue 1: URL Not Reachable

```dart
// Test connectivity
try {
  final response = await http.get(
    Uri.parse('$baseUrl/api/health'),
  ).timeout(Duration(seconds: 10));
  
  print('Connection OK: ${response.statusCode}');
} catch (e) {
  print('Connection error: $e');
  // Check if Ngrok URL is correct
  // Check if Flutter app has internet permission
}
```

### Issue 2: File Upload Fails

**Solution**: Ensure camera permission

```dart
// pubspec.yaml
dependencies:
  permission_handler: ^11.4.4
  image_picker: ^0.9.0

// In code
Future<void> requestCameraPermission() async {
  final status = await Permission.camera.request();
  
  if (status.isDenied) {
    print('Camera permission denied');
  } else if (status.isPermanentlyDenied) {
    openAppSettings();
  }
}
```

### Issue 3: Response Parsing Error

```dart
// Add error handling
try {
  final response = await request.send();
  final responseString = await response.stream.bytesToString();
  
  print('Raw response: $responseString');
  
  final jsonResponse = jsonDecode(responseString);
  // Process...
} catch (e) {
  print('Parse error: $e');
}
```

---

## 📊 Performance Baseline

Expected performance (untuk reference):

| Metric | Expected | Status |
|--------|----------|--------|
| Health check | < 50ms | ✅ |
| Model info | < 100ms | ✅ |
| Line recognition (GPU) | 100-200ms | ✅ |
| Line recognition (CPU) | 300-500ms | ✅ |
| Paragraph recognition | 500ms - 2s | ✅ |
| Memory usage | < 2GB | ✅ |
| CPU usage (idle) | 0-5% | ✅ |

Jika performance lebih lambat, check masalah:
- Network latency (Ngrok?)
- System resources (GPU memory, disk space)
- Model complexity settings

---

## ✅ Quick Checklist

Sebelum contact support:

- [ ] Python 3.8+ installed
- [ ] All dependencies installed (`pip list`)
- [ ] Model file exists
- [ ] LM file exists
- [ ] Flask app runs locally
- [ ] Health endpoint accessible
- [ ] cURL test works
- [ ] Logs checked for errors
- [ ] System resources adequate
- [ ] Ngrok active (if using remote)
- [ ] Flutter app has network permission

---

## 📞 Getting Help

1. **Check logs**:
   ```bash
   tail -f app.log | grep -i error
   ```

2. **Run tests**:
   ```bash
   python test_api.py
   ```

3. **Test manually**:
   ```bash
   curl http://localhost:5000/api/health
   ```

4. **Check system**:
   ```bash
   python -c "import torch; print(torch.cuda.is_available())"
   ```

5. **Review this guide** for your specific issue

---

**Version**: 1.0.0  
**Date**: March 16, 2026  
**Last Updated**: March 16, 2026
