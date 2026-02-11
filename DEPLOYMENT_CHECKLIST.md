# VetRAI Lightsail Deployment - Complete Checklist

Use this checklist throughout your deployment process.

---

## 📋 Phase 1: Pre-Deployment Verification (Do This First!)

### Lightsail Instance Setup
- [ ] **Instance Created**
  - AWS Console → Lightsail → Instances
  - Status shows "Running" (not "Pending" or "Stopped")
  
- [ ] **Instance Specs Verified**
  - [ ] 1GB RAM minimum
  - [ ] 2vCPUs minimum
  - [ ] 40GB SSD minimum
  - [ ] Ubuntu 22.04 LTS OS
  - [ ] Region: Virginia, Zone A (18.208.169.120)

- [ ] **Public IP Address Known**
  - [ ] IP is: `18.208.169.120`
  - [ ] Can see it in Lightsail console
  - [ ] IP is not changing (static IP recommended)

### SSH Access Setup
- [ ] **SSH Key Downloaded**
  - [ ] File exists (usually `.pem` format)
  - [ ] Typical location: `C:\Users\YourUsername\Downloads\LightsailDefaultKey*.pem`
  - [ ] Key file size is reasonable (>1KB)
  
- [ ] **SSH Key Secured** (NOT in git repo!)
  - [ ] Key stored outside project folder
  - [ ] Suggested: `C:\Users\YourUsername\.ssh\`
  - [ ] File permissions secure (Windows: admin only)
  - [ ] Not backed up to cloud sync (OneDrive/Dropbox)

- [ ] **SSH Access Tested**
  ```powershell
  ssh -i "path\to\key.pem" ubuntu@18.208.169.120
  # Should connect without errors
  ```

### Network & Firewall
- [ ] **Lightsail Firewall Allows SSH**
  - [ ] AWS Console → Lightsail → Instance → Networking
  - [ ] Port 22 (SSH) is **OPEN**
  - [ ] Source allows your IP (or 0.0.0.0/0)
  
- [ ] **Local Firewall Allows Outbound SSH**
  - [ ] Windows Defender configured
  - [ ] Corporate firewall doesn't block port 22
  - [ ] VPN doesn't interfere (if using VPN, test)

### Docker Images Ready
- [ ] **Docker Hub Images Available**
  - [ ] `root2wings/vetrai:latest` exists
  - [ ] `root2wings/vetrai-nginx:latest` exists
  - [ ] Both images publicly accessible (not private)

- [ ] **Can Download Images**
  ```bash
  # This will happen during deployment, but can test with:
  docker pull root2wings/vetrai:latest
  ```

### Documentation Prepared
- [ ] **All Guides Downloaded/Available**
  - [ ] START_HERE.md
  - [ ] WINDOWS_QUICK_START.md or relevant deployment guide
  - [ ] DEPLOY_TO_LIGHTSAIL.md
  - [ ] LIGHTSAIL_QUICK_REFERENCE.md

### System Requirements on Local Machine
- [ ] **Windows Users**:
  - [ ] PowerShell 5.0+ installed
  - [ ] OpenSSH client available (built-in Windows 10+)
  - [ ] Administrative access optional (for key permissions)

- [ ] **Linux/Mac Users**:
  - [ ] SSH client available (bash or terminal)
  - [ ] curl or wget available
  - [ ] Sudo access (for some commands)

---

## ✅ Phase 2: Pre-Deployment Confirmation

Before starting deployment, verify all items above are checked.

- [ ] All Pre-Deployment items above: **✓ COMPLETE**
- [ ] Ready to proceed with deployment: **YES**

If ANY item is not checked, go back and fix it first!

---

## 🚀 Phase 3: Deployment Execution

### Choose Your Deployment Method

#### Option A: Windows PowerShell (Fastest - 5 min)
- [ ] **PowerShell Script Ready**
  - [ ] `lightsail-auto-deploy.ps1` exists in project folder
  - [ ] PowerShell execution policy allows script
  - [ ] Have SSH key path ready: `C:\path\to\key.pem`

- [ ] **Execute Script**
  ```powershell
  cd "C:\Users\LENOVO\Rajesh\vetraiv1\vetrai_new"
  
  # Set execution policy if needed
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  
  # Run deployment
  .\lightsail-auto-deploy.ps1 -KeyPath "C:\path\to\key.pem" -InstanceIP "18.208.169.120"
  ```
  - [ ] Script runs without errors
  - [ ] See progress messages (blue/green output)

- [ ] **Monitor Script Output**
  ```
  ✓ SSH connection established
  ℹ Installing Docker
  ✓ Installing Docker completed
  ...
  ✓ VetRAI is Now Running!
  ```

#### Option B: Linux/Mac Bash (Fastest - 5 min)
- [ ] **Bash Script Ready**
  - [ ] `lightsail-auto-deploy.sh` exists
  - [ ] SSH into instance first

- [ ] **Execute Script**
  ```bash
  # Already SSHed into instance
  bash <(curl -fsSL https://your-repo-url/lightsail-auto-deploy.sh)
  ```
  - [ ] Script runs without errors
  - [ ] See progress messages

#### Option C: Manual Deployment (10 min)
- [ ] **SSH into Instance**
  ```powershell
  ssh -i "path\to\key.pem" ubuntu@18.208.169.120
  ```

- [ ] **Follow [DEPLOY_TO_LIGHTSAIL.md](DEPLOY_TO_LIGHTSAIL.md) Step-by-Step**
  - [ ] Step 1-3: System setup
  - [ ] Step 4-5: Docker & Docker Compose
  - [ ] Step 6: Application directory
  - [ ] Step 7-8: Configuration & startup
  - [ ] Step 9-10: Verification

### During Deployment
- [ ] **System Updates** (if not skipped)
  - [ ] apt-get update completes
  - [ ] apt-get upgrade completes (or skipped)
  - Estimated time: ~1-2 minutes

- [ ] **Docker Installation**
  - [ ] Docker setup script downloads and runs
  - [ ] No errors in installation
  - Estimated time: ~30-45 seconds

- [ ] **Docker Compose Installation**
  - [ ] Installs successfully
  - [ ] Can run `docker-compose --version`
  - Estimated time: ~10-15 seconds

- [ ] **Docker Image Pull**
  - [ ] Images download from Docker Hub
  - [ ] No authentication errors
  - [ ] Shows progress for 2 images
  - Estimated time: ~60-90 seconds
  - Note: May show "Pull complete" multiple times

- [ ] **Application Startup**
  - [ ] docker-compose up -d executes
  - [ ] Returns `Done` or similar message
  - [ ] Services start in background
  - Estimated time: ~10-20 seconds

- [ ] **Services Health Check**
  - [ ] Script waits for services to stabilize
  - [ ] Shows docker compose ps output
  - [ ] All 3 services visible

---

## ✨ Phase 4: Post-Deployment Verification

### Immediate Checks (After Script Completes)

#### Service Status
- [ ] **Docker Services Running**
  ```bash
  docker compose ps
  # Should show:
  # NAME                      STATUS      PORTS
  # vetrai_postgres_prod      Up (healthy)
  # vetrai_app_prod           Up (healthy)
  # vetrai_nginx_prod         Up (healthy)
  ```
  - [ ] postgres: healthy (or status shows "up")
  - [ ] vetrai: healthy (or status shows "up")
  - [ ] nginx: healthy (or status shows "up")

- [ ] **No Error Messages**
  - [ ] Check docker compose logs for errors
  ```bash
  docker compose logs | grep -i error
  # Should show nothing (no errors)
  ```

#### Endpoint Verification
- [ ] **Health Check Endpoint**
  ```bash
  curl http://localhost/health_check
  # Should return: {"status":"ok","chat":"ok","db":"ok"}
  ```
  ✓ Response code: 200 OK
  ✓ Returns JSON status

- [ ] **API Version Endpoint**
  ```bash
  curl http://localhost/api/v1/version
  # Should return version information
  ```
  ✓ Response code: 200 OK
  ✓ Returns JSON

- [ ] **Basic Connectivity**
  ```bash
  curl http://localhost/
  # Should return HTML content (frontend)
  ```
  ✓ Response code: 200 OK
  ✓ Returns HTML

### Remote Browser Testing (From Your Windows Machine)

- [ ] **Frontend Loading**
  - [ ] Open: http://18.208.169.120 in browser
  - [ ] Page loads (doesn't timeout)
  - [ ] See VetRAI interface (or blank page is OK)
  - [ ] No 502/503 errors

- [ ] **API Documentation**
  - [ ] Open: http://18.208.169.120/docs
  - [ ] Swagger UI loads
  - [ ] Can see API endpoints listed

- [ ] **Health Check in Browser**
  - [ ] Open: http://18.208.169.120/health_check
  - [ ] Returns JSON or "ok" message
  - [ ] No error response

### Database Connection
- [ ] **Database Accessible**
  ```bash
  docker exec vetrai_postgres_prod psql -U vetrai -d vetrai -c "SELECT 1;"
  # Should return: 1
  ```

- [ ] **Database Initialized**
  ```bash
  docker exec vetrai_postgres_prod psql -U vetrai -d vetrai -c "\dt"
  # Should show database tables (ok if empty)
  ```

### Logs Inspection
- [ ] **Backend Logs Normal**
  ```bash
  docker compose logs vetrai | head -20
  # Should show startup messages, no fatal errors
  ```

- [ ] **Database Logs Normal**
  ```bash
  docker compose logs postgres | head -20
  # Should show PostgreSQL startup, no connection errors
  ```

- [ ] **Nginx Logs Normal**
  ```bash
  docker compose logs nginx | head -20
  # Should show nginx startup, no error logs
  ```

### Resource Usage
- [ ] **Memory Usage Reasonable**
  ```bash
  docker stats --no-stream
  # Total should be <700MB for 1GB instance
  ```

- [ ] **Disk Space Available**
  ```bash
  df -h / | tail -1
  # Available should be >10GB
  ```

- [ ] **No Major Errors in Dmesg**
  ```bash
  dmesg | tail -20
  # Should show normal boot/startup messages
  ```

---

## 🔧 Phase 5: Firewall Configuration (Required for Remote Access)

### Lightsail Firewall Rules
- [ ] **HTTP Port 80 Open**
  - [ ] AWS Console → Lightsail → Instances → Networking
  - [ ] See "Firewall" section
  - [ ] Rule: TCP 80 from 0.0.0.0/0 (or your IP)
  - [ ] Status: "Enabled" or "Active"

- [ ] **HTTPS Port 443** (Optional, for SSL later)
  - [ ] Rule: TCP 443 from 0.0.0.0/0 (if adding SSL)
  - [ ] Status: "Enabled" or "Active"

- [ ] **SSH Port 22** (May already be configured)
  - [ ] Rule: TCP 22 from YOUR IP or 0.0.0.0/0
  - [ ] Status: "Enabled" or "Active"

### Verify Remote Access
- [ ] **From Another Network** (if possible)
  - [ ] Try accessing http://18.208.169.120 from phone hotspot
  - [ ] Or from different home network
  - [ ] Page should load without timeout

---

## ✅ Phase 6: Final Success Verification

All items below should be checked for successful deployment:

### ✅ Application Running
- [ ] All 3 docker services show "healthy" or "running"
- [ ] No "restarting" or "exited" status
- [ ] Logs show no fatal errors

### ✅ Endpoints Responding
- [ ] http://18.208.169.120 loads in browser
- [ ] http://18.208.169.120/docs shows Swagger UI
- [ ] http://18.208.169.120/health_check returns success
- [ ] http://18.208.169.120/api/v1/version returns data

### ✅ Database Connected
- [ ] Backend can connect to PostgreSQL
- [ ] Database has tables (can query \dt)
- [ ] No connection errors in logs

### ✅ Firewall Configured
- [ ] Port 80 (HTTP) is open
- [ ] Can access from any browser
- [ ] No "connection refused" errors

### ✅ Resources Available
- [ ] Memory usage <700MB (out of 1GB available)
- [ ] Disk space >10GB available
- [ ] CPU usage reasonable when idle

### ✅ All Documentation
- [ ] Bookmarked: [LIGHTSAIL_QUICK_REFERENCE.md](LIGHTSAIL_QUICK_REFERENCE.md)
- [ ] Saved: [DEPLOY_TO_LIGHTSAIL.md](DEPLOY_TO_LIGHTSAIL.md) for reference
- [ ] Quick access: [vetrai_prod/ADVANCED_CONFIG.md](vetrai_prod/ADVANCED_CONFIG.md) for later

---

## 🎉 Success! You're Done!

If all items in Phase 6 are checked:

✓ **VetRAI is successfully deployed to Lightsail!**

Your application is now:
- Live on the internet at: **http://18.208.169.120**
- Running 24/7 in the cloud
- Accessible from anywhere
- Backed by PostgreSQL database

---

## 📝 Phase 7: Post-Deployment (Next Steps)

### Optional Configuration

- [ ] **Change Default Credentials** (Recommended for Production)
  - [ ] Edit docker-compose.yml to change POSTGRES_PASSWORD
  - [ ] Restart with: `docker compose restart`

- [ ] **Enable Automated Backups**
  - [ ] Set up backup script in crontab
  - [ ] Test restore procedure

- [ ] **Configure Domain Name** (Optional)
  - [ ] Get static IP from Lightsail
  - [ ] Point domain DNS to IP
  - [ ] Update application URLs

- [ ] **Enable HTTPS/SSL** (Optional but Recommended)
  - [ ] Install Certbot: `sudo apt-get install certbot`
  - [ ] Get Let's Encrypt certificate: `certbot certonly --standalone -d yourdomain.com`
  - [ ] Update Nginx configuration
  - [ ] Restart: `docker compose restart nginx`

- [ ] **Set Up Monitoring** (Optional)
  - [ ] Configure CloudWatch alerts
  - [ ] Set up log rotation
  - [ ] Monitor disk usage

### Common Commands to Know

```bash
# View logs
docker compose logs -f

# Check status
docker compose ps

# Restart service
docker compose restart vetrai

# Stop all services
docker compose down

# Update images
docker compose pull && docker compose up -d

# SSH into instance
ssh -i key.pem ubuntu@18.208.169.120

# Backup database
docker compose exec -T postgres pg_dump -U vetrai vetrai > backup.sql
```

---

## 🆘 Troubleshooting Reference

If something goes wrong:

| Issue | Check | Reference |
|-------|-------|-----------|
| **Can't SSH to instance** | Firewall, key permissions, instance running | [WINDOWS_QUICK_START.md#SSH-connection-timeout](WINDOWS_QUICK_START.md#ssh-connection-timeout) |
| **Services won't start** | Check logs, disk space | [LIGHTSAIL_QUICK_REFERENCE.md#Services-not-starting](LIGHTSAIL_QUICK_REFERENCE.md) |
| **Can't access http://18.208.169.120** | Firewall rules, services status | [LIGHTSAIL_QUICK_REFERENCE.md#Connection-issues](LIGHTSAIL_QUICK_REFERENCE.md) |
| **502 Bad Gateway** | Backend service status | [LIGHTSAIL_QUICK_REFERENCE.md#Services-not-starting](LIGHTSAIL_QUICK_REFERENCE.md) |
| **Out of disk space** | Run `df -h`; increase instance size | [LIGHTSAIL_QUICK_REFERENCE.md#Storage](LIGHTSAIL_QUICK_REFERENCE.md) |
| **Slow performance** | Check `docker stats`; upgrade instance | [LIGHTSAIL_QUICK_REFERENCE.md#Performance](LIGHTSAIL_QUICK_REFERENCE.md) |

---

## 📞 Help & Support

- **Deployment Issues**: [WINDOWS_QUICK_START.md](WINDOWS_QUICK_START.md#troubleshooting)
- **Command Reference**: [LIGHTSAIL_QUICK_REFERENCE.md](LIGHTSAIL_QUICK_REFERENCE.md)
- **Advanced Setup**: [vetrai_prod/ADVANCED_CONFIG.md](vetrai_prod/ADVANCED_CONFIG.md)
- **Complete Guide**: [DEPLOY_TO_LIGHTSAIL.md](DEPLOY_TO_LIGHTSAIL.md)

---

## 📋 Summary

**Pre-Deployment**: 20 items to verify
**Deployment**: Execute script or follow manual steps
**Post-Deployment**: 20+ verification checkpoints
**Final Success**: All endpoints responding, all services healthy

**Estimated Total Time**: 
- Preparation: ~5 minutes
- Deployment: ~3-5 minutes  
- Verification: ~5 minutes
- **Total: ~13-15 minutes to fully deployed system**

---

**Use this checklist throughout your deployment process.**
**Check items as you complete them.**
**Your deployment is successful when all Phase 6 items are checked!**

Good luck! 🚀
