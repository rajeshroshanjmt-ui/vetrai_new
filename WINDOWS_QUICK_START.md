# VetRAI Lightsail Deployment - Windows Quick Start

## TL;DR - Deploy in 5 Minutes (Windows)

### Prerequisites
- PowerShell 5.0+ (built into Windows 10 and later)
- SSH private key file (`.pem`)
- Lightsail instance running Ubuntu 22.04
- Lightsail firewall allows TCP 22 (SSH) from your IP

### One-Command Deployment

```powershell
# From Windows PowerShell
cd "C:\Users\LENOVO\Rajesh\vetraiv1\vetrai_new"
.\lightsail-auto-deploy.ps1 -KeyPath "C:\path\to\your\key.pem" -InstanceIP "18.208.169.120"
```

That's it! The script will:
1. ✓ Connect to your Lightsail instance
2. ✓ Install Docker & Docker Compose
3. ✓ Download and start VetRAI
4. ✓ Verify all services are healthy

**Total time**: ~2-3 minutes

---

## Detailed Windows Instructions

### Step 1: Locate Your SSH Key

When you created the Lightsail instance, you downloaded an SSH key file (`.pem`).

**Find it**:
- Usually in `C:\Users\YourUsername\Downloads\`
- File name like: `LightsailDefaultKey-us-east-1.pem`
- Remember the exact path for Step 3

**Move it somewhere safe**:
```
C:\Users\LENOVO\.ssh\lightsail-key.pem
```

### Step 2: Fix SSH Key Permissions (Windows)

PowerShell might complain about key permissions. Run this first:

```powershell
# Open PowerShell as Administrator and run:
$KeyPath = "C:\path\to\your\key.pem"
icacls $KeyPath /inheritance:r /grant:r "$env:USERNAME`:`(F`)"
```

### Step 3: Get Your Instance IP

From AWS Console:
1. Go to **Lightsail** → **Instances**
2. Click your instance name
3. Copy the **Public IP** (should be `18.208.169.120`)

### Step 4: Run the Deployment Script

```powershell
# Open PowerShell and navigate to project folder
cd "C:\Users\LENOVO\Rajesh\vetraiv1\vetrai_new"

# Run deployment
.\lightsail-auto-deploy.ps1 -KeyPath "C:\Users\LENOVO\.ssh\lightsail-key.pem" -InstanceIP "18.208.169.120"
```

### Step 5: Wait for Completion

The script displays progress:
```
✓ SSH connection established
ℹ Installing Docker
✓ Installing Docker completed
ℹ Installing Docker Compose
✓ Installing Docker Compose completed
ℹ Pulling Docker images
✓ Pulling Docker images completed
ℹ Starting services
✓ Starting services completed
✓ VetRAI is Now Running!
```

When you see "✓ VetRAI is Now Running!", deployment is complete.

### Step 6: Access Your Application

Open browser and visit:
- **Frontend**: http://18.208.169.120
- **API Docs**: http://18.208.169.120/docs
- **Health Check**: http://18.208.169.120/health_check

---

## Customization Options

### Skip System Update (Faster Deployment)

```powershell
.\lightsail-auto-deploy.ps1 -KeyPath "C:\Users\LENOVO\.ssh\lightsail-key.pem" `
  -InstanceIP "18.208.169.120" `
  -SkipUpdate
```

**Saves ~2 minutes** if your instance is already up-to-date.

### Use Different SSH Username

If your Lightsail instance uses a different username (not `ubuntu`):

```powershell
.\lightsail-auto-deploy.ps1 -KeyPath "C:\Users\LENOVO\.ssh\lightsail-key.pem" `
  -InstanceIP "18.208.169.120" `
  -Username "ec2-user"
```

---

## Troubleshooting

### "Cannot find path 'lightsail-auto-deploy.ps1'"

**Solution**: Make sure you're in the correct directory:
```powershell
cd "C:\Users\LENOVO\Rajesh\vetraiv1\vetrai_new"
dir lightsail-auto-deploy.ps1  # Should list the file
```

### "Permission denied" or SSH fails

**Problem**: Windows Defender or antivirus blocking SSH

**Solutions**:
1. Allow PowerShell through Windows Firewall
2. Temporarily disable antivirus
3. Run PowerShell as Administrator:
   - Right-click PowerShell
   - Select "Run as Administrator"

### "SSH connection timeout"

**Problem**: Can't reach Lightsail instance

**Check**:
1. Instance IP is correct: `18.208.169.120` ✓
2. Lightsail firewall allows SSH (port 22)
   - AWS Console → Lightsail → Instance → Networking
   - Check if port 22 is open
3. Your IP is whitelisted (or open to 0.0.0.0/0)
4. Instance is running (status shows "Running" in AWS Console)

### "Docker images fail to pull"

**Problem**: Docker Hub API rate limiting

**Solution**: Wait 5-10 minutes and try again, or manually SSH and run:
```bash
cd ~/vetrai-prod
docker compose pull
```

### Services don't start

**Manual Check**:
```powershell
# SSH into instance
ssh -i "C:\path\to\key.pem" ubuntu@18.208.169.120

# Check service status
cd ~/vetrai-prod
docker compose ps
docker compose logs
```

---

## Manual Deployment (If Script Fails)

If the script has issues, manually follow these steps:

### 1. SSH into Instance
```powershell
ssh -i "C:\path\to\key.pem" ubuntu@18.208.169.120
```

### 2. Install Docker
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm -f get-docker.sh
sudo usermod -aG docker ubuntu
sudo apt-get install -y docker-compose
```

### 3. Create Application Directory
```bash
mkdir -p ~/vetrai-prod
cd ~/vetrai-prod
```

### 4. Create docker-compose.yml

Copy the content from `vetrai_prod/docker-compose.yml` and paste into:
```bash
nano docker-compose.yml
# Paste content, then Ctrl+O, Enter, Ctrl+X
```

### 5. Start Services
```bash
docker compose pull
docker compose up -d
docker compose ps
```

### 6. Verify
```bash
curl http://localhost/health_check
```

---

## Post-Deployment Tasks (Optional)

### Configure Lightsail Firewall

1. Go to **AWS Lightsail Console**
2. Click your instance
3. Go to **Networking** tab
4. Add firewall rules:
   - **HTTP** (80) from Anywhere (0.0.0.0/0)
   - **HTTPS** (443) from Anywhere (optional, for SSL)

### Set Up Domain Name

1. Buy domain from Route 53 or external provider
2. Update DNS to point to `18.208.169.120`
3. Test: `http://yourdomain.com`

### Enable SSL Certificate (Let's Encrypt)

SSH into instance and run:
```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot certonly --standalone -d yourdomain.com
```

Then update Nginx configuration in docker-compose.yml.

### Monitor Services

SSH in and run:
```bash
cd ~/vetrai-prod
docker stats  # Real-time stats
docker compose logs -f  # Follow logs
```

### Backup Database

```bash
cd ~/vetrai-prod
docker compose exec -T postgres pg_dump -U vetrai vetrai > backup.sql
```

### Update Application

When new versions release:
```bash
cd ~/vetrai-prod
docker compose pull
docker compose up -d
```

---

## Quick Reference: Common Commands

Once deployed, SSH in and use:

| Task | Command |
|------|---------|
| **View logs** | `docker compose logs -f` |
| **Stop services** | `docker compose down` |
| **Restart services** | `docker compose restart` |
| **Check status** | `docker compose ps` |
| **CPU/Memory usage** | `docker stats` |
| **Update images** | `docker compose pull && docker compose up -d` |
| **View database** | `docker exec vetrai_postgres_prod psql -U vetrai -d vetrai` |
| **Backup database** | `docker compose exec -T postgres pg_dump -U vetrai vetrai > backup.sql` |
| **Restore database** | `docker exec -i vetrai_postgres_prod psql -U vetrai -d vetrai < backup.sql` |

---

## Support & Debugging

### Display Detailed Logs

```powershell
# From your Windows machine
ssh -i "C:\path\to\key.pem" ubuntu@18.208.169.120 "cd ~/vetrai-prod && docker compose logs"
```

### Check Individual Service Logs

```bash
docker compose logs vetrai      # Backend logs
docker compose logs postgres    # Database logs
docker compose logs nginx       # Web server logs
```

### Restart a Single Service

```bash
docker compose restart vetrai
docker compose restart postgres
docker compose restart nginx
```

### Full System Restart

```bash
docker compose down
docker compose up -d
```

---

## Security Notes

⚠️ **IMPORTANT for Production**:

1. **Change Default Credentials**
   - Database user: `vetrai`
   - Database password: `vetrai`
   - UPDATE THESE in docker-compose.yml before deployment!

2. **Enable SSH Key-Only Access**
   - Disable password authentication on instance
   - Use only SSH key for access

3. **Configure Firewall**
   - Only allow HTTP/HTTPS from needed IPs
   - Block unused ports

4. **Use Static IP**
   - Allocate static IP to instance
   - Prevents IP changes

5. **Enable Backups**
   - Set up automated database backups
   - Test restore procedures

---

## Estimated Timeline

| Step | Duration |
|------|----------|
| Run script | Start |
| SSH connect | 5-10 sec |
| Install Docker | 30-45 sec |
| Install Docker Compose | 10-15 sec |
| Pull images | 60-90 sec |
| Start services | 10-20 sec |
| Services healthy | 20-30 sec |
| **Total** | **2-3 min** |

---

## Get Help

If you encounter issues:

1. **Check logs**: `docker compose logs`
2. **Verify connectivity**: `curl http://localhost/health_check`
3. **Read full documentation**: See `DEPLOY_TO_LIGHTSAIL.md`
4. **Review troubleshooting**: See `LIGHTSAIL_QUICK_REFERENCE.md`

---

## Success Checklist

After deployment, verify:

- [ ] Script runs without errors
- [ ] Shows "✓ VetRAI is Now Running!"
- [ ] Can access http://18.208.169.120 in browser
- [ ] Can access http://18.208.169.120/docs for API docs
- [ ] Health check returns `{"status":"ok"}`
- [ ] All 3 services show "healthy" in `docker compose ps`
- [ ] Can view logs with `docker compose logs`

If all checkmarks pass, **you're done!** 🎉

---

## Next Steps

1. **Test the Application**
   - Open http://18.208.169.120 in browser
   - Create a test project
   - Test chat and API endpoints

2. **Configure Production Settings** (recommended)
   - Change default database credentials
   - Set up backups
   - Configure custom domain
   - Enable SSL

3. **Monitor & Maintain**
   - Check logs regularly
   - Monitor resource usage
   - Keep Docker images updated
   - Maintain database backups

---

For detailed information, see:
- `DEPLOY_TO_LIGHTSAIL.md` - Complete deployment guide
- `LIGHTSAIL_QUICK_REFERENCE.md` - Command reference
- `vetrai_prod/ADVANCED_CONFIG.md` - Advanced configuration
