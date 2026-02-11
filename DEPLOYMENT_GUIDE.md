# VetRAI Deployment Guide - Complete Navigation

Welcome! This guide helps you choose the right deployment method for your needs.

## 🚀 Quick Decision Tree

**What's your situation?**

### 1. **I'm on Windows and want the easiest option**
   → Follow [WINDOWS_QUICK_START.md](WINDOWS_QUICK_START.md)
   - Single PowerShell command
   - All-in-one deployment
   - 2-3 minutes
   - **Recommended for most Windows users**

### 2. **I'm on Linux/Mac or already SSH'd into Lightsail**
   → Use [lightsail-auto-deploy.sh](lightsail-auto-deploy.sh)
   - Run: `bash lightsail-auto-deploy.sh`
   - All-in-one deployment
   - 2-3 minutes
   - **Recommended for Linux/Mac users**

### 3. **I want maximum control and detailed steps**
   → Follow [DEPLOY_TO_LIGHTSAIL.md](DEPLOY_TO_LIGHTSAIL.md)
   - 10 detailed steps with explanations
   - Execute commands manually
   - Understand what happens
   - Perfect for learning
   - ~5-10 minutes

### 4. **I want a quick reference for common commands**
   → Use [LIGHTSAIL_QUICK_REFERENCE.md](LIGHTSAIL_QUICK_REFERENCE.md)
   - Quick lookup table
   - Common tasks & commands
   - Troubleshooting tips
   - Best for post-deployment

### 5. **I want a complete 10-step walkthrough**
   → Follow [LIGHTSAIL_DEPLOYMENT.md](LIGHTSAIL_DEPLOYMENT.md)
   - Comprehensive guide
   - All prerequisites explained
   - Advanced configurations
   - Perfect for first-time deployments

### 6. **I need advanced configuration help**
   → Check [vetrai_prod/ADVANCED_CONFIG.md](vetrai_prod/ADVANCED_CONFIG.md)
   - Scaling options
   - Performance tuning
   - Monitoring setup
   - SSL configuration
   - Database optimization

---

## 📋 File Overview

### Deployment Files

| File | Purpose | Best For | Time |
|------|---------|----------|------|
| **WINDOWS_QUICK_START.md** | Windows-specific quick guide | Windows users | 5 min |
| **lightsail-auto-deploy.ps1** | PowerShell deployment script | Windows (run locally) | 3 min |
| **lightsail-auto-deploy.sh** | Bash deployment script | Linux/Mac (run on instance) | 3 min |
| **DEPLOY_TO_LIGHTSAIL.md** | Manual step-by-step guide | Learning & control | 10 min |
| **LIGHTSAIL_DEPLOYMENT.md** | Complete 10-step guide | Comprehensive walkthrough | 15 min |
| **LIGHTSAIL_QUICK_REFERENCE.md** | Command reference | After deployment | N/A |

### Configuration Files

| File | Purpose | When To Use |
|------|---------|-------------|
| **vetrai_prod/docker-compose.yml** | Production setup | Deployment |
| **vetrai_prod/.env** | Environment template | Customization |
| **vetrai_prod/README.md** | Production overview | Understanding setup |
| **vetrai_prod/ADVANCED_CONFIG.md** | Advanced settings | Scaling, monitoring |

### Support Files

| File | Purpose | When To Use |
|------|---------|-------------|
| **AWS_CREDENTIALS_SETUP.md** | AWS credential management | Secure access setup |
| **deploy-prod.py** | Python orchestration | Advanced deployments |

---

## 🎯 Recommended Path by User Type

### Beginner (First Time)

```
1. Read: WINDOWS_QUICK_START.md (5 min)
2. Run: .\lightsail-auto-deploy.ps1 (3 min)
3. Verify: http://18.208.169.120 (1 min)
✓ Done! Total: 9 minutes
```

### Intermediate (Want to Learn)

```
1. Read: DEPLOY_TO_LIGHTSAIL.md (5 min)
2. Manually follow the 10 steps (10 min)
3. Run verification commands (2 min)
4. Keep LIGHTSAIL_QUICK_REFERENCE.md handy
✓ Done! Total: 17 minutes
```

### Advanced (Custom Setup)

```
1. Review: LIGHTSAIL_DEPLOYMENT.md (10 min)
2. Copy docker-compose.yml from vetrai_prod/ (1 min)
3. Customize environment variables (5 min)
4. Deploy with custom settings (5 min)
5. Configure advanced options (20 min)
✓ Done! Total: 41 minutes (includes customization)
```

---

## 💻 Quick Start Commands

### For Windows Users (Recommended)

```powershell
# 1. Open PowerShell
# 2. Navigate to project folder
cd "C:\Users\LENOVO\Rajesh\vetraiv1\vetrai_new"

# 3. Run one command (replace paths with your actual paths)
.\lightsail-auto-deploy.ps1 -KeyPath "C:\path\to\key.pem" -InstanceIP "18.208.169.120"

# 4. Wait for "✓ VetRAI is Now Running!"
# 5. Visit http://18.208.169.120 in browser
```

**Total time: 5 minutes**

### For Linux/Mac Users (Recommended)

```bash
# 1. SSH into Lightsail instance
ssh -i /path/to/key.pem ubuntu@18.208.169.120

# 2. Download and run script
bash <(curl -fsSL https://raw.githubusercontent.com/your-repo/lightsail-auto-deploy.sh)

# 3. Wait for "✓ VetRAI is Now Running!"
# 4. Visit http://18.208.169.120 in browser
```

**Total time: 5 minutes**

---

## 🔍 Choosing Your Method

### Auto-Deploy Scripts
✅ **Pros**:
- Completely automated
- Handles all steps
- Fast (2-3 minutes)
- Less room for error
- Color-coded output

❌ **Cons**:
- Limited customization
- Hard to stop/inspect
- Harder to debug if issues

**When to use**: Most users, quick deployment

### Manual Step-by-Step
✅ **Pros**:
- Full control
- Can stop and inspect
- Learn what's happening
- Easy to customize
- Easy to debug

❌ **Cons**:
- Takes longer (10 minutes)
- More manual work
- Higher chance of typos

**When to use**: Learning, custom setup, troubleshooting

### Hybrid Approach
✅ **Best of both worlds**:
- Use auto-deploy script
- Customize docker-compose.yml first
- Run script with `-SkipUpdate` flag
- Review logs after

**When to use**: Custom production setup

---

## 📝 Pre-Deployment Checklist

Before running any script, verify:

- [ ] **Lightsail instance created** (18.208.169.120)
- [ ] **Instance is running** (status = "Running")
- [ ] **SSH key downloaded** from Lightsail
- [ ] **SSH key path known** (e.g., `C:\Users\...\key.pem`)
- [ ] **Can ping instance** (shows it's network-reachable)
- [ ] **System updated** (optional, but recommended)
- [ ] **Docker Hub images available** (root2wings/vetrai:latest)
- [ ] **Firewall allows SSH** (port 22 inbound)

If anything is missing, check the relevant guide before proceeding.

---

## 🔐 Security Reminders

Before deploying to production:

1. **Change default credentials**
   - Edit docker-compose.yml
   - Change POSTGRES_USER and POSTGRES_PASSWORD
   - Change VETRAI_SUPERUSER and VETRAI_SUPERUSER_PASSWORD

2. **Secure SSH access**
   - Disable password authentication
   - Use only SSH key access
   - Store key securely (not in git)

3. **Configure firewall**
   - Only allow needed ports (HTTP 80, HTTPS 443, SSH 22)
   - Restrict to specific IPs if possible

4. **Set up monitoring**
   - Check logs regularly
   - Monitor CPU/disk/memory
   - Set up alerts

5. **Enable backups**
   - Automate database backups
   - Test restore procedures
   - Store backups separately

See [AWS_CREDENTIALS_SETUP.md](AWS_CREDENTIALS_SETUP.md) for detailed security guide.

---

## 🆘 Troubleshooting Quick Links

### Deployment Issues
- **Script won't run**: [WINDOWS_QUICK_START.md#Troubleshooting](WINDOWS_QUICK_START.md#troubleshooting)
- **SSH connection fails**: [WINDOWS_QUICK_START.md#SSH-connection-timeout](WINDOWS_QUICK_START.md#ssh-connection-timeout)
- **Docker won't start**: [LIGHTSAIL_QUICK_REFERENCE.md#Troubleshooting](LIGHTSAIL_QUICK_REFERENCE.md#-troubleshooting--debugging)

### Service Issues
- **Services don't start**: [LIGHTSAIL_QUICK_REFERENCE.md#Services-not-starting](LIGHTSAIL_QUICK_REFERENCE.md#-services-not-starting)
- **Can't connect to API**: [LIGHTSAIL_QUICK_REFERENCE.md#Connection-issues](LIGHTSAIL_QUICK_REFERENCE.md#%EF%B8%8F-connection--networking-issues)
- **Database won't connect**: [LIGHTSAIL_QUICK_REFERENCE.md#Database-issues](LIGHTSAIL_QUICK_REFERENCE.md#-database--persistence-issues)

### Post-Deployment Issues
- **Need to update**: [LIGHTSAIL_QUICK_REFERENCE.md#Updating](LIGHTSAIL_QUICK_REFERENCE.md#-updating--maintenance)
- **Performance problems**: [LIGHTSAIL_QUICK_REFERENCE.md#Performance](LIGHTSAIL_QUICK_REFERENCE.md#-performance--scaling)
- **Out of space**: [LIGHTSAIL_QUICK_REFERENCE.md#Storage](LIGHTSAIL_QUICK_REFERENCE.md#-storage--disk-space)

---

## 📚 Documentation Structure

```
vetrai_new/
├── 🚀 DEPLOYMENT (Start Here)
│   ├── WINDOWS_QUICK_START.md          ← Windows users start here
│   ├── DEPLOY_TO_LIGHTSAIL.md          ← Manual step-by-step
│   ├── LIGHTSAIL_DEPLOYMENT.md         ← Complete guide
│   ├── LIGHTSAIL_QUICK_REFERENCE.md    ← Command lookup & troubleshooting
│   └── DEPLOYMENT_GUIDE.md             ← This file
│
├── 🔧 DEPLOYMENT SCRIPTS
│   ├── lightsail-auto-deploy.ps1       ← Windows PowerShell script
│   ├── lightsail-auto-deploy.sh        ← Linux/Mac Bash script
│   └── deploy-prod.py                  ← Python orchestration script
│
├── 📦 PRODUCTION CONFIG
│   ├── vetrai_prod/
│   │   ├── docker-compose.yml          ← Production setup
│   │   ├── .env                        ← Environment template
│   │   ├── README.md                   ← Production overview
│   │   ├── ADVANCED_CONFIG.md          ← Advanced settings
│   │   └── .gitignore                  ← Git ignore rules
│   │
│   └── AWS_CREDENTIALS_SETUP.md        ← AWS security guide
│
└── 📖 OTHER DOCS
    ├── CONTRIBUTING.md
    ├── DEVELOPMENT.md
    ├── README.md
    └── ...
```

---

## ✅ Deployment Success Checklist

After deployment completes, verify:

### Immediate Checks (1 min)
- [ ] No errors in deployment output
- [ ] All 3 services show "healthy" in `docker compose ps`
- [ ] Can SSH into instance: `ssh -i key.pem ubuntu@18.208.169.120`

### Browser Checks (2 min)
- [ ] Frontend loads: http://18.208.169.120
- [ ] API docs work: http://18.208.169.120/docs
- [ ] Health check passes: http://18.208.169.120/health_check
- [ ] API responds: http://18.208.169.120/api/v1/version

### Service Checks (2 min)
```bash
docker compose ps                # Should show 3 healthy services
docker compose logs              # Should show no major errors
curl http://localhost/health_check  # Should return {"status":"ok"}
```

### Database Check (1 min)
```bash
docker exec vetrai_postgres_prod psql -U vetrai -d vetrai -c "SELECT version();"
```

### Full System Check (2 min)
```bash
docker stats                     # Should show reasonable resource usage
df -h                           # Should have >10GB free space
free -h                         # Should have >200MB free RAM
```

If all checks pass ✓, you're ready for production! 🎉

---

## 📞 Getting Help

### Documentation
- Full deployment guide: [DEPLOY_TO_LIGHTSAIL.md](DEPLOY_TO_LIGHTSAIL.md)
- Quick commands: [LIGHTSAIL_QUICK_REFERENCE.md](LIGHTSAIL_QUICK_REFERENCE.md)
- Advanced config: [vetrai_prod/ADVANCED_CONFIG.md](vetrai_prod/ADVANCED_CONFIG.md)

### Common Issues
1. Check [LIGHTSAIL_QUICK_REFERENCE.md](#-troubleshooting--debugging)
2. Review logs: `docker compose logs`
3. SSH in and check: `docker ps`, `docker logs <container>`
4. Consult [DEPLOY_TO_LIGHTSAIL.md](#troubleshooting)

### Still Stuck?
- Check AWS Lightsail console for instance status
- Verify SSH key permissions
- Confirm firewall rules allow SSH (port 22)
- Check network connectivity to instance
- Review deployment script output for specific errors

---

## 🎯 Next Actions

**Choose your path**:

1. **Windows + Quick**: [WINDOWS_QUICK_START.md](WINDOWS_QUICK_START.md)
2. **Linux/Mac + Quick**: Run `./lightsail-auto-deploy.sh`
3. **Any OS + Manual**: [DEPLOY_TO_LIGHTSAIL.md](DEPLOY_TO_LIGHTSAIL.md)
4. **Help Needed**: [LIGHTSAIL_QUICK_REFERENCE.md](LIGHTSAIL_QUICK_REFERENCE.md)

---

## 📊 Deployment Methods Comparison

| Aspect | Auto Script | Manual Steps | Python Script |
|--------|-----------|--------------|---------------|
| **Time** | 2-3 min | 10 min | 3-5 min |
| **Ease** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Control** | Low | High | Medium |
| **Learning** | Low | High | Medium |
| **Customization** | Limited | Unlimited | Good |
| **Best For** | Quick deploy | Learning | Complex setups |
| **Error Recovery** | Hard | Easy | Medium |

---

## 🚀 Getting Started Right Now

### The Fastest Path (≤5 minutes)

**Windows**:
```powershell
cd "C:\Users\LENOVO\Rajesh\vetraiv1\vetrai_new"
.\lightsail-auto-deploy.ps1 -KeyPath "YOUR_KEY_PATH" -InstanceIP "18.208.169.120"
# Done! Access at http://18.208.169.120
```

**Linux/Mac**:
```bash
ssh -i your-key.pem ubuntu@18.208.169.120
bash <(curl -fsSL https://your-repo-url/lightsail-auto-deploy.sh)
# Done! Access at http://18.208.169.120
```

---

## 📅 Timeline

| Step | Duration | When |
|------|----------|------|
| Verify prerequisites | 2 min | Now |
| Run deployment script | 3 min | Next |
| Services start | 2 min | During script |
| Verify endpoints | 2 min | After script |
| **Total** | **~9 min** | **Next 10 minutes** |

---

**Ready to deploy? Start with your platform above!** ⬆️

For detailed instructions, visit the relevant guide from the Quick Decision Tree at the top.
