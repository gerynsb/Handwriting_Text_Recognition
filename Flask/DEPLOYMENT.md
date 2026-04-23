# Flask HTR API - Deployment Guide

Panduan deployment Flask API ke production.

---

## 📋 Deployment Options

| Option | Pros | Cons | Best For |
|--------|------|------|----------|
| **Ngrok** | Free, Easy, Tunneling | Not production-ready, Limited bandwidth | Development, Testing |
| **Railway** | Simple, Auto-deploy, Free tier | Limited resources | Small-medium apps |
| **Heroku** | Easy, Great for beginners | Paid plans only | Learning, hobby projects |
| **AWS EC2** | Flexible, Scalable | Complex setup, Need DevOps knowledge | Production, Large scale |
| **Google Cloud** | Similar to AWS | Complex | Enterprise apps |
| **DigitalOcean** | Simple, Affordable | Less scalable than AWS | Small-medium production |

---

## 🚀 Option 1: Railway (Recommended for HTR)

Railway is best for this project: Simple, reliable, 500 hours free/month.

### A. Create Railway Account

1. Visit https://railway.app
2. Sign up with GitHub
3. Create new project

### B. Prepare for Deployment

Create `.railway.json`:
```json
{
  "build": {
    "builder": "nixpacks"
  },
  "start": "python app.py"
}
```

Or create `Procfile`:
```
web: python app.py
```

### C. Deploy via Git Push

```bash
# Initialize git repo
git init
git add .
git commit -m "Initial Flask HTR API"

# Add Railway remote
railway link

# Deploy
git push railway main
```

### D. Configure Environment

In Railway dashboard:
1. Go to Variables
2. Add:
   ```
   MODEL_PATH=
   LM_PATH=
   FLASK_ENV=production
   DEVICE=cpu
   ```

3. Restart deployment

### E. Get Public URL

Railway gives you: `https://xxxx.railway.app`

Use this in Flutter!

---

## 🚀 Option 2: DigitalOcean App Platform

### A. Prepare Code

Make sure `requirements.txt` is up-to-date:
```bash
pip freeze > requirements.txt
```

### B. Create DigitalOcean Account

1. Visit https://www.digitalocean.com
2. Sign up / login
3. Create account

### C. Connect GitHub

1. Go to Apps
2. Create App
3. Select GitHub repository
4. Connect
5. Select branch

### D. Configure App

Set environment:
```
FLASK_ENV=production
DEVICE=cpu
```

### E. Deploy

Click "Deploy" and wait for build to complete.

Get URL: `https://xxxx.ondigitalocean.app`

---

## 🚀 Option 3: AWS EC2 (Advanced)

### A. Create EC2 Instance

1. AWS Console → EC2 → Launch Instance
2. Select Ubuntu 22.04 LTS (free tier eligible)
3. Instance type: t2.micro or t3.micro
4. Storage: 20GB minimum
5. Security group: Allow port 5000, 22, 80, 443

### B. SSH into Instance

```bash
ssh -i "your-key.pem" ubuntu@your-ec2-ip
```

### C. Install Dependencies

```bash
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv

# Clone code from GitHub
git clone https://github.com/yourusername/your-htr-repo.git
cd your-htr-repo

# Create venv
python3 -m venv venv
source venv/bin/activate

# Install requirements
pip install -r requirements.txt
```

### D. Setup Supervisor (Process Manager)

```bash
sudo apt-get install -y supervisor
```

Create `/etc/supervisor/conf.d/htr-api.conf`:
```ini
[program:htr-api]
directory=/home/ubuntu/your-htr-repo
command=/home/ubuntu/your-htr-repo/venv/bin/python app.py
autostart=true
autorestart=true
stderr_logfile=/var/log/htr-api.err.log
stdout_logfile=/var/log/htr-api.out.log
user=ubuntu
```

Start supervisor:
```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start htr-api
```

### E. Setup Nginx (Reverse Proxy)

```bash
sudo apt-get install -y nginx
```

Edit `/etc/nginx/sites-enabled/default`:
```nginx
upstream htr_api {
    server 127.0.0.1:5000;
}

server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://htr_api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Restart nginx:
```bash
sudo systemctl restart nginx
```

### F. Setup SSL Certificate (Let's Encrypt)

```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot certonly --nginx -d yourdomain.com
```

Update nginx config for HTTPS (refer to Certbot instructions).

### G. Get Public URL

Your API is now at: `http://your-ec2-ip/` or `https://yourdomain.com/`

---

## 🐳 Option 4: Docker Containerization

For all deployment options, containerize first:

### A. Create Dockerfile

```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV FLASK_ENV=production
ENV DEVICE=cpu

EXPOSE 5000

CMD ["python", "app.py"]
```

### B. Create .dockerignore

```
.git
.gitignore
requirements.txt.bak
__pycache__
*.pyc
*.pyo
*.pyd
.env
.DS_Store
```

### C. Build Image

```bash
docker build -t htr-api:latest .
```

### D. Test Locally

```bash
docker run -p 5000:5000 htr-api:latest
```

### E. Push to Docker Hub

```bash
docker login
docker tag htr-api:latest yourusername/htr-api:latest
docker push yourusername/htr-api:latest
```

Now deploy on any platform using the Docker image!

---

## 📊 Performance Optimization for Production

### 1. Model Optimization

Option A: Model Quantization
```python
# In model_loader.py
model = torch.quantization.quantize_dynamic(
    model, {torch.nn.Linear}, dtype=torch.qint8
)
```

Option B: Model Distillation (requires separate training)
- Create smaller model that learns from large model
- 30-50% faster with minimal accuracy loss

### 2. Caching

Add Redis caching for repeated images:
```python
import redis

cache = redis.Redis(host='localhost', db=0)

@app.route('/api/recognize/line', methods=['POST'])
def recognize_line():
    # Generate image hash
    img_hash = hashlib.md5(image_data).hexdigest()
    
    # Check cache
    result = cache.get(img_hash)
    if result:
        return json.loads(result)
    
    # If not in cache, process
    result = inference_engine.recognize_line(image)
    cache.set(img_hash, json.dumps(result), ex=3600)
    
    return result
```

### 3. Load Balancing

Multiple instances with Nginx:
```nginx
upstream htr_api {
    server 127.0.0.1:5001;
    server 127.0.0.1:5002;
    server 127.0.0.1:5003;
}
```

Run 3 Flask instances on different ports:
```bash
python app.py --port 5001 &
python app.py --port 5002 &
python app.py --port 5003 &
```

### 4. Database Connection Pooling

For logging/monitoring:
```python
from sqlalchemy.pool import QueuePool

db = SQLAlchemy(engine_options={
    'poolclass': QueuePool,
    'pool_size': 10,
    'max_overflow': 20,
})
```

---

## 🔒 Security Best Practices

### 1. Environment Variables

Never hardcode paths! Use `.env`:
```bash
MODEL_PATH=/path/to/model
LM_PATH=/path/to/lm
FLASK_SECRET_KEY=your-secret-key
```

Load in app:
```python
from dotenv import load_dotenv
load_dotenv()

MODEL_PATH = os.getenv('MODEL_PATH')
```

### 2. CORS Configuration

Whitelist specific domains:
```python
CORS(app, resources={
    r"/api/*": {
        "origins": ["https://yourmobileapp.com", "https://api.yourdomain.com"],
        "methods": ["GET", "POST"],
        "allow_headers": ["Content-Type"]
    }
})
```

### 3. Rate Limiting

```python
from flask_limiter import Limiter

limiter = Limiter(
    app=app,
    key_func=lambda: request.remote_addr,
    default_limits=["200 per day", "50 per hour"]
)

@app.route('/api/recognize/line', methods=['POST'])
@limiter.limit("10 per minute")
def recognize_line():
    ...
```

### 4. Input Validation

```python
from werkzeug.utils import secure_filename

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/api/recognize/line', methods=['POST'])
def recognize_line():
    if 'file' not in request.files:
        return {'error': 'No file provided'}, 400
    
    file = request.files['file']
    
    if not allowed_file(file.filename):
        return {'error': 'Invalid file type'}, 400
    
    if len(file.read()) > MAX_FILE_SIZE:
        return {'error': 'File too large'}, 413
    
    file.seek(0)  # Reset file pointer
    ...
```

### 5. HTTPS Only

In production app:
```python
@app.before_request
def enforce_https():
    if not request.is_secure and os.getenv('FLASK_ENV') == 'production':
        url = request.url.replace('http://', 'https://', 1)
        return redirect(url, code=301)
```

---

## 📈 Monitoring & Logging

### Setup Logging

```python
import logging
from logging.handlers import RotatingFileHandler

if not app.debug:
    if not os.path.exists('logs'):
        os.mkdir('logs')
    
    file_handler = RotatingFileHandler(
        'logs/htr_api.log',
        maxBytes=10240000,
        backupCount=10
    )
    
    file_handler.setFormatter(logging.Formatter(
        '%(asctime)s %(levelname)s: %(message)s'
    ))
    
    app.logger.addHandler(file_handler)
    app.logger.setLevel(logging.INFO)
    app.logger.info('Flask HTR API startup')
```

### Monitor with Sentry

```python
import sentry_sdk

sentry_sdk.init(
    dsn="your-sentry-dsn",
    traces_sample_rate=1.0
)
```

### Health Check Endpoint

```python
@app.route('/health')
def health_check():
    return {
        'status': 'ok',
        'timestamp': datetime.now().isoformat(),
        'memory_usage': get_memory_usage(),
        'gpu_memory': get_gpu_memory(),
    }
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest
      
      - name: Run tests
        run: pytest tests/
      
      - name: Deploy to Railway
        run: |
          railway deploy --environment production
```

---

## 📊 Expected Performance (Production)

| Metric | Value |
|--------|-------|
| Memory Usage | 800MB - 2GB |
| CPU Usage | 20-40% (per request) |
| Inference Time | 100-200ms (GPU) |
| Throughput | 10 requests/sec (single instance) |
| Uptime SLA | 99.9% (with load balancer) |
| Latency (p50) | 150ms |
| Latency (p95) | 300ms |

---

## 🎯 Recommended Setup for This Project

For best balance of cost, ease, and reliability:

1. **Development**: Local + Ngrok (current setup) ✅
2. **Testing**: Railway free tier
3. **Production**: Railway paid or DigitalOcean

Deploy steps:
```bash
# 1. Test locally
python test_api.py

# 2. Create Railway account
# 3. Connect GitHub repo
# 4. Set environment variables
# 5. Deploy
# 6. Test with Flutter
# 7. Monitor performance
```

---

## 📋 Pre-Production Checklist

- [ ] All tests pass locally
- [ ] Model path correct
- [ ] Error handling complete
- [ ] Logging configured
- [ ] CORS properly configured
- [ ] Rate limiting enabled
- [ ] Input validation added
- [ ] HTTPS configured (if using domain)
- [ ] Environment variables set
- [ ] Database backups scheduled (if applicable)
- [ ] Monitoring alerts set up
- [ ] Documentation updated
- [ ] Flutter app tested with production URL
- [ ] Performance benchmarks recorded
- [ ] Rollback plan created

---

**Version**: 1.0.0  
**Date**: March 16, 2026  
**Status**: ✅ Ready for deployment

