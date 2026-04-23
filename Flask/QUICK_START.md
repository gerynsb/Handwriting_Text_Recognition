# Flask HTR API - Quick Start (5 Minutes)

Langsung mulai tanpa baca dokumentasi panjang. ⚡

---

## ⚡ 5-Minute Startup

### Step 1: Install Dependencies (2 min)
```bash
cd "D:\Dokumen Kuliah\TA\Kode Kaggle\Integrasi_Mobile\FlaskAPI"
pip install -r requirements.txt
```

### Step 2: Verify Model Path (30 sec)
Check that these files exist:
- ✅ `D:\Dokumen Kuliah\TA\Kode Kaggle\Experiment\2_23_2026_Eksperiment_RNN\exp_architecture_rnn_20260223_042857\best_model.pt`
- ✅ `D:\Dokumen Kuliah\TA\Kode Kaggle\Experiment\2_25_2026_Advanced_Deslanting++_Final\language_model\char_5gram.json`

If paths are different, edit `config.py` and update MODEL_PATH and LM_PATH.

### Step 3: Run Flask Server (30 sec)
```bash
python app.py
```

Expected output:
```
 * Running on http://0.0.0.0:5000
```

### Step 4: Test API (1 min)
**Terminal 2**:
```bash
python test_api.py
```

Expected: All tests PASS ✅

### Step 5: Get Public URL (30 sec)
**Terminal 3**:
```bash
# Download from https://ngrok.com/download and install first
ngrok http 5000
```

Copy the HTTPS URL and use in Flutter! 🎉

---

## ✅ You're Done!

### What Now?
1. **Local only?** → Use `http://localhost:5000`
2. **Flutter app?** → Use Ngrok URL
3. **Production?** → Read DEPLOYMENT.md

### Next Step Options

**For Flutter Integration**:
```dart
// Copy from API_EXAMPLES.md → Flutter section
final apiUrl = 'https://your-ngrok-url.ngrok.io';
```

**For Python Integration**:
```python
# Copy from API_EXAMPLES.md → Python section
from htr_client import HTRClient
client = HTRClient('http://localhost:5000')
text = client.recognize_line('image.png')
```

**For Production**:
```
Read DEPLOYMENT.md for Railway / DigitalOcean / AWS setup
```

---

## 🔗 Quick API Test

### With cURL

```bash
# Health check
curl http://localhost:5000/api/health

# Recognize line
curl -X POST -F "file=@image.png" \
  http://localhost:5000/api/recognize/line
```

### With Python
```python
import requests

response = requests.post(
    'http://localhost:5000/api/recognize/line',
    files={'file': open('image.png', 'rb')}
)
print(response.json())
```

### With Flutter
```dart
final response = await http.post(
  Uri.parse('http://localhost:5000/api/recognize/line'),
  files: {'file': image},
);
```

---

## ❓ Troubleshooting

| Problem | Fix |
|---------|-----|
| `Module not found` | Run `pip install -r requirements.txt` |
| `Model not found` | Update paths in `config.py` |
| `Port in use` | Edit `config.py` SERVER_PORT or run `ngrok http 5001` instead |
| `CUDA error` | Edit `config.py` set `DEVICE = 'cpu'` |
| `Connection refused` | Is Flask running? Check Terminal 1 |
| More issues? | Read `TROUBLESHOOTING.md` |

---

## 📚 Full Documentation

If you need more details:

| Document | For What |
|----------|----------|
| **README.md** | API endpoint reference |
| **SETUP.md** | Detailed setup guide |
| **API_EXAMPLES.md** | Code examples (Dart, Python, Node.js, etc) |
| **DEPLOYMENT.md** | Production deployment |
| **TROUBLESHOOTING.md** | Error solutions |
| **INDEX.md** | Navigation guide |

---

## 🎯 Common Goals

### "I want to test the API locally"
```bash
python app.py
curl http://localhost:5000/api/health
```

### "I want to integrate with Flutter"
1. Run Flask: `python app.py`
2. Run Ngrok: `ngrok http 5000`
3. Copy Ngrok URL
4. Use in Flutter: See API_EXAMPLES.md → Flutter section

### "I want to deploy to production"
1. Read DEPLOYMENT.md
2. Choose platform (Railway recommended)
3. Follow deployment steps

### "I want code examples"
Open API_EXAMPLES.md and find your platform:
- Flutter/Dart
- Node.js/JavaScript  
- Python
- cURL
- Postman

### "Something doesn't work"
1. Check TROUBLESHOOTING.md for your error
2. Or run: `python test_api.py`
3. Check logs in terminal

---

## 🚀 Most Common Next Steps

### For Testing
```bash
python test_api.py
```

### For Public Access
```bash
ngrok http 5000
# Copy HTTPS URL to Flutter or frontend
```

### For Production
```
Edit DEPLOYMENT.md → Choose Railway (easiest)
```

### For Flutter Dev
```
File: API_EXAMPLES.md → Flutter/Dart section
Get the HTRService class code
```

---

## 📞 Need Help?

1. **Quick answer?** → Check 📖 README.md
2. **Setup issue?** → Check ⚙️ SETUP.md  
3. **Error?** → Check 🔧 TROUBLESHOOTING.md
4. **Code example?** → Check 💻 API_EXAMPLES.md
5. **Deploy?** → Check 🚀 DEPLOYMENT.md
6. **Lost?** → Check 🗺️ INDEX.md

---

## ⏱️ Typical Time

| Task | Time |
|------|------|
| Full setup | 5 min |
| Test API | 1 min |
| Get Ngrok URL | 1 min |
| Flutter integration | 15-30 min |
| Production deploy | 10-20 min |

---

**Status**: ✅ Ready to go!  
**Start**: `python app.py`  
**Test**: `python test_api.py`  
**Deploy**: `ngrok http 5000`

Have fun! 🎉
