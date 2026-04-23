# Flask HTR API - Documentation Index

Dokumentasi lengkap untuk Flask API integration dengan Flutter mobile app.

---

## 📚 Documentation Files

### 1. **README.md** 📖
Dokumentasi utama dengan overview lengkap.

**Berguna untuk**:
- Quick start guide
- API endpoint reference
- CORS configuration
- Ngrok setup (basic)
- Flutter integration example

**Baca kapan**: Pertama kali setup atau need quick reference

---

### 2. **SETUP.md** ⚙️
Step-by-step setup guide dari instalasi sampai testing.

**Berguna untuk**:
- Install Python dependencies
- Verify model path
- Run Flask server locally
- Test dengan curl
- Public hosting dengan Ngrok
- Flutter integration code
- Troubleshooting basic issues
- Performance tips
- Performance checklist

**Baca kapan**: Pertama kali setup, atau perlu langkah detail

---

### 3. **DEPLOYMENT.md** 🚀
Production deployment options dan best practices.

**Berguna untuk**:
- Deployment ke Railway (recommended)
- Deployment ke DigitalOcean
- AWS EC2 setup
- Docker containerization
- Performance optimization
- Security best practices
- CI/CD pipeline setup
- Monitoring & logging

**Baca kapan**: Siap untuk production deployment

---

### 4. **API_EXAMPLES.md** 💻
Code examples dalam berbagai bahasa/framework.

**Tersedia untuk**:
- **Flutter/Dart**: Complete service class + UI widget
- **Node.js/JavaScript**: Backend client + Express integration + Browser fetch
- **Python**: Simple client + Streamlit web app
- **cURL**: Command examples untuk testing
- **Postman**: JSON collection untuk testing

**Baca kapan**: Develop integration di platform manapun

---

### 5. **TROUBLESHOOTING.md** 🔧
Solusi untuk error dan issues yang sering terjadi.

**Covers**:
- 10 common errors with solutions
- Debugging steps
- Performance debugging
- Logging & monitoring
- Flutter-specific issues
- Performance baseline
- Quick checklist

**Baca kapan**: Encounter error atau something not working

---

### 6. **CONFIG.py** ⚙️
File konfigurasi dengan path model dan setting server.

**Contains**:
- Model path configuration
- Language model path
- Server settings (host, port)
- Device selection (CUDA/CPU)
- Preprocessing parameters
- Decoding parameters (beam search, LM weight)
- Flask config classes

**Edit kapan**: Need to change model path or server settings

---

## 🎯 Quick Navigation Guide

### 🆕 First Time Setup
1. Read: **README.md** (overview)
2. Follow: **SETUP.md** (step-by-step)
3. Check: **TROUBLESHOOTING.md** (if error)

### 🚀 Ready for Production
1. Review: **DEPLOYMENT.md**
2. Choose deployment option
3. Follow deployment guide

### 💻 Development Integration
1. Check: **API_EXAMPLES.md** (your platform)
2. Copy code example
3. Adapt untuk your project

### 🔧 Problem Solving
1. Check: **TROUBLESHOOTING.md**
2. Find your error
3. Follow solution

### ⚙️ Configuration Changes
1. Edit: **config.py**
2. Verify: Model path exists
3. Restart: Flask app

---

## 📋 Quick Reference

### Model Info
- **Architecture**: CRNN with BiLSTM 2×256
- **Classes**: 80 (79 characters + blank)
- **Input Size**: 64 × 512 (height × width)
- **Best Test CER**: 6.70% (Beam Search + 5-gram LM)
- **Framework**: PyTorch 2.0.1

### Model Files
- **Model**: `best_model.pt` (from exp_architecture_rnn_20260223_042857)
- **Language Model**: `char_5gram.json` (5-gram character level)
- **Batch Processing**: ❌ Not supported (one at a time)
- **GPU/CPU**: Auto-detect

### API Endpoints

| Endpoint | Method | Purpose | Speed |
|----------|--------|---------|-------|
| `/api/health` | GET | Health check | < 50ms |
| `/api/model/info` | GET | Model metadata | < 100ms |
| `/api/recognize/line` | POST | Single line recognition | 100-200ms (GPU) |
| `/api/recognize/paragraph` | POST | Multi-line recognition | 500ms - 2s |
| `/api/preprocess` | POST | Image preprocessing preview | < 100ms |

### Server
- **Default Host**: 0.0.0.0
- **Default Port**: 5000
- **URL (Local)**: http://localhost:5000
- **URL (Ngrok)**: https://[ngrok-id].ngrok.io
- **CORS**: Enabled for all origins

### Connection
- **Device**: CPU (default) or GPU (if available)
- **Inference Method**: Beam Search (width=10, lm_weight=0.1)
- **Timeout**: 30s (line), 60s (paragraph)

---

## 🛠️ Common Tasks

### Setup Flask API
1. Open terminal in FlaskAPI folder
2. Run: `pip install -r requirements.txt`
3. Run: `python app.py`
4. Test: `curl http://localhost:5000/api/health`

### Test All Endpoints
```bash
python test_api.py
```

### Expose Public URL
```bash
ngrok http 5000
# Copy the HTTPS URL
```

### Debug Issues
1. Check logs in terminal
2. Run: `python test_api.py`
3. Read **TROUBLESHOOTING.md**

### Deploy to Production
1. Read **DEPLOYMENT.md**
2. Choose platform (Railway recommended)
3. Follow deployment steps

### Integrate with Flutter
1. Check **API_EXAMPLES.md** → Flutter section
2. Create HTRService class
3. Update API_URL with your Ngrok URL
4. Test with real images

---

## 📊 File Sizes & Timing

| File | Purpose | Size |
|------|---------|------|
| app.py | Flask application | ~350 lines |
| model_loader.py | Model & inference | ~500 lines |
| config.py | Configuration | ~100 lines |
| test_api.py | Testing suite | ~300 lines |
| requirements.txt | Dependencies | 9 packages |
| README.md | Main documentation | ~200 lines |
| SETUP.md | Setup guide | ~450 lines |
| DEPLOYMENT.md | Deploy guide | ~600 lines |
| API_EXAMPLES.md | Code examples | ~900 lines |
| TROUBLESHOOTING.md | Troubleshooting | ~550 lines |
| **Total** | **Complete system** | **~4000 lines** |

---

## 🔒 Security Notes

### Always Do
- ✅ Use environment variables for paths
- ✅ Validate input files
- ✅ Use HTTPS for production
- ✅ Rate limit endpoints
- ✅ Whitelist CORS origins
- ✅ Monitor system resources

### Never Do
- ❌ Hardcode file paths in code
- ❌ Accept unlimited file sizes
- ❌ Use debug mode in production
- ❌ Log sensitive information
- ❌ Allow public CUDA access
- ❌ Expose detailed error messages

---

## 📈 Performance Expectations

### Local (GPU)
- Health check: < 50ms
- Model info: < 100ms
- Line recognition: 100-200ms
- Paragraph: 500ms - 2s
- Memory: 800MB - 1.5GB

### Local (CPU)
- Health check: < 50ms
- Model info: < 100ms
- Line recognition: 300-500ms
- Paragraph: 2-5s
- Memory: 600MB - 1GB

### Production (Ngrok)
- Add 50-200ms network latency
- Same computation time
- May need to increase timeouts

---

## 📞 Support Decision Tree

```
Error or Issue?
│
├─ "No module named..." → SETUP.md Step 1
├─ "File not found" → SETUP.md Step 2, TROUBLESHOOTING.md Error 2
├─ "Port already in use" → TROUBLESHOOTING.md Error 4
├─ "Connection refused" → TROUBLESHOOTING.md Error 5
├─ "Slow inference" → TROUBLESHOOTING.md Performance
├─ "Memory error" → TROUBLESHOOTING.md Error 9
├─ "Ready for production" → DEPLOYMENT.md
├─ "Need code example" → API_EXAMPLES.md [your platform]
└─ "Unknown issue" → TROUBLESHOOTING.md Debugging Steps
```

---

## ✅ Setup Completion Checklist

- [ ] Read README.md
- [ ] Follow SETUP.md Steps 1-4
- [ ] Run test_api.py successfully
- [ ] All tests pass (green)
- [ ] Health endpoint responds
- [ ] Model info shows correct model
- [ ] Line recognition works
- [ ] Paragraph recognition works
- [ ] Ngrok tunnel active (if needed)
- [ ] Flutter can reach API
- [ ] Integration code ready
- [ ] Bookmarked TROUBLESHOOTING.md for reference

---

## 🚀 Next Steps

### Immediate (Today)
1. ✅ Setup Flask API locally
2. ✅ Run tests
3. ✅ Get Ngrok URL

### Short Term (This Week)
1. 🔄 Develop Flutter app
2. 🔄 Test with real images
3. 🔄 Optimize based on performance

### Medium Term (This Month)
1. ⏳ Deploy to production (Railway)
2. ⏳ Monitor performance
3. ⏳ Document system architecture (Tujuan 4)

### Long Term
1. ⏳ Mobile distribution (Play Store/App Store)
2. ⏳ User feedback & improvements
3. ⏳ Scaling if needed

---

## 📞 Documentation Version

- **Version**: 1.0.0
- **Date**: March 16, 2026
- **Status**: ✅ Complete
- **Maintained by**: Your Team
- **Last Updated**: March 16, 2026

---

## 🎓 Learning Resources

### About HTR (Handwriting Text Recognition)
- CRNN Architecture: https://arxiv.org/abs/1507.05717
- Beam Search Decoding: https://en.wikipedia.org/wiki/Beam_search
- Language Model Integration: https://kheeniesandez.github.io/posts/lm/

### Framework Documentation
- Flask: https://flask.palletsprojects.com/
- PyTorch: https://pytorch.org/docs/stable/index.html
- Flutter: https://flutter.dev/docs
- Ngrok: https://ngrok.com/docs

### Deployment Guides
- Railway: https://docs.railway.app/
- DigitalOcean: https://docs.digitalocean.com/
- AWS EC2: https://docs.aws.amazon.com/ec2/

---

**Happy coding! 🚀**

For issues, refer to **TROUBLESHOOTING.md** or check logs with:
```bash
tail -f app.log | grep -i error
```
