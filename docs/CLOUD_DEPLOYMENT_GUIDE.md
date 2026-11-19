# SmartPlot AI — Cloud Backend Deployment Guide (Phase 9)

**Project Number:** 22  
**System Architecture:** Two-Tier Microservice Architecture (Node.js Gateway + Python FastAPI)  
**Author:** Mueed Ahmad (14724) — CUSIT FYP  

---

## 1. Architectural Topology

```
                  ┌───────────────────────────────────────────────┐
                  │            Client Applications                │
                  │   (Android Flutter APK / iOS Flutter IPA)     │
                  └───────────────────────┬───────────────────────┘
                                          │ HTTPS / HTTP
                                          ▼
                  ┌───────────────────────────────────────────────┐
                  │          Node.js Express API Gateway          │
                  │     (Port 5000 / Reverse Proxy / Auth / CORS) │
                  └───────────────────────┬───────────────────────┘
                                          │ Internal Network (HTTP)
                                          ▼
                  ┌───────────────────────────────────────────────┐
                  │           Python FastAPI Microservice         │
                  │  (Port 8000 / OR-Tools CP-SAT / ML RF Models) │
                  └───────────────────────────────────────────────┘
```

---

## 2. Resource Requirements & Hosting Sizing

| Component | Minimum Specification | Recommended Specification |
|:---|:---|:---|
| **RAM** | 1.5 GB (models + solver in memory) | 2.0 GB - 4.0 GB |
| **vCPU** | 1 core | 2 cores |
| **Disk Storage** | 2 GB (including 123 MB ML models) | 10 GB SSD |
| **Bandwidth** | 100 Mbps | 1 Gbps |

### Cost-Effective Hosting Provider Evaluation

1. **Self-Hosted VPS (Hetzner / DigitalOcean / Linode):**
   - **Cost:** ~$4 - $6 / month
   - **Specs:** 2 GB RAM, 1 vCPU, 20 GB SSD.
   - **Recommendation:** **Best value for production deployment.** Easily handles both Docker containers with high concurrency.
2. **Render / Railway (PaaS Container Hosting):**
   - **Cost:** Free tier has memory limits (512MB) which will OOM on ML model load; Starter tier ~$7/month (2GB RAM).
   - **Recommendation:** Quick automated git-push deploys.
3. **Local Tunnel / Cloudflare Tunnel (Zero-Cost FYP Demo Mode):**
   - **Cost:** $0.00
   - **Specs:** Runs on developer workstation, exposed via secure HTTPS tunnel.
   - **Recommendation:** Ideal for presentation day without paying recurring subscription fees.

---

## 3. Docker Container Deployment

### 3.1 Docker Compose Deployment (Recommended)

1. Clone repository to server:
   ```bash
   git clone https://github.com/rickdieguez055-byte/smart-plot-ai.git
   cd smart-plot-ai
   ```
2. Pull Git LFS model artifacts:
   ```bash
   git lfs install
   git lfs pull
   ```
3. Copy environment configuration:
   ```bash
   cp .env.production.example .env
   ```
4. Build and run containers:
   ```bash
   docker-compose up -d --build
   ```
5. Verify health:
   ```bash
   curl http://localhost:5000/health
   ```

---

## 4. HTTPS Configuration with Reverse Proxy (Nginx + Let's Encrypt)

```nginx
server {
    server_name api.smartplot.ai;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 60s;
        proxy_connect_timeout 60s;
    }

    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/api.smartplot.ai/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.smartplot.ai/privkey.pem;
}
```

---

## 5. Mobile Client Connection Configuration

In the Flutter application (`ApiConfig`):
- For **Cloud HTTPS**, select preset `Cloud HTTPS Gateway (https://api.smartplot.ai)` or your tunnel URL.
- For **Local Wi-Fi Demo**, select preset `Local Wi-Fi Host (192.168.18.11:5000)`.
- For **USB Cable Demo (Android)**, select preset `Physical Device USB Reverse (127.0.0.1:5000)` and execute `adb reverse tcp:5000 tcp:5000`.
