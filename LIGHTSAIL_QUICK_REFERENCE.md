# AWS Lightsail Deployment Quick Reference

Rapid deployment guide for getting VetRAI running on AWS Lightsail.

---

## Quick Start (5 Minutes)

### 1. Create Lightsail Instance

**Via AWS Console:**
- AWS → Lightsail → Create instance
- Ubuntu 22.04 LTS
- Plan: $5/month (1GB) or $10/month (2GB) recommended
- Name: `vetrai-prod`
- Create

### 2. Get Connection Details

```powershell
# Windows PowerShell
$LightsailIP = "18.208.169.120"  # Replace with your IP
$KeyPath = "C:\Users\LENOVO\vetrai-prod.pem"  # Your SSH key
```

### 3. Deploy (Windows)

```powershell
# From vetrai_new directory
.\lightsail-deploy.ps1 -LightsailIP $LightsailIP -KeyPath $KeyPath
```

### 4. Access Application

```
Frontend: http://18.208.169.120
Docs:     http://18.208.169.120/docs
API:      http://18.208.169.120/api/v1/
```

---

## Manual Deployment (Linux/Mac)

### 1. SSH to Instance

```bash
ssh -i /path/to/key.pem ubuntu@18.208.169.120
```

### 2. Run Deployment Script

```bash
# Download and run deployment script
curl -fsSL https://raw.githubusercontent.com/your-repo/lightsail-deploy.sh | bash

# Or manually:
chmod +x lightsail-deploy.sh
./lightsail-deploy.sh
```

### 3. Services Start Automatically

```bash
# Check status
docker compose ps

# View logs
docker compose logs -f
```

---

## Common Tasks

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f nginx
docker compose logs -f vetrai
docker compose logs -f postgres
```

### Restart Services

```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart vetrai
```

### Update Images

```bash
docker compose pull
docker compose up -d
```

### Stop All Services

```bash
docker compose down
```

### Create Backup

```bash
# Backup database
docker compose exec -T postgres pg_dump -U vetrai vetrai > backup_$(date +%Y%m%d).sql

# Compress
gzip backup_*.sql
```

### Monitor Resources

```bash
# Real-time stats
docker stats

# Disk usage
df -h

# Memory
free -h
```

---

## Firewall Configuration

**In AWS Console → Lightsail → Instance → Networking:**

Add these rules:
```
IPv4 | 80   | HTTP  | Allow all  ✅
IPv4 | 443  | HTTPS | Allow all  ✅
IPv4 | 22   | SSH   | Allow all  ✅
IPv4 | 5432 | PostgreSQL | Restrict (internal)
IPv4 | 7860 | Backend | Restrict (internal)
```

---

## Domain Setup (Optional)

### With Lightsail DNS

```bash
# In AWS Console
# Lightsail → Domains
# Create/register domain
# Add A record pointing to Lightsail static IP
```

### With External DNS (Route53, Namecheap, etc.)

```ini
Type:  A
Host:  vetrai.example.com
Value: YOUR_LIGHTSAIL_STATIC_IP
TTL:   300
```

---

## SSL Certificate (Let's Encrypt)

```bash
ssh ubuntu@18.208.169.120

# Install Certbot
sudo apt install -y certbot

# Get certificate (stop nginx first)
docker compose stop nginx
sudo certbot certonly --standalone -d vetrai.example.com
docker compose start nginx

# Certificates at: /etc/letsencrypt/live/vetrai.example.com/
```

---

## Monitoring Commands

### Health Status

```bash
curl http://18.208.169.120/health_check
# Expected: {"status":"ok","chat":"ok","db":"ok"}

curl http://18.208.169.120/api/v1/version
# Expected: {"version":"1.8.0","main_version":"1.8.0","package":"Vetrai"}
```

### Top Running Processes

```bash
docker ps --format "{{.Names}}\t{{.Status}}"
```

### Database Size

```bash
docker compose exec postgres psql -U vetrai -d vetrai -c "SELECT pg_size_pretty(pg_database_size(current_database()));"
```

---

## Troubleshooting

### Services Not Starting

```bash
# Check logs
docker compose logs

# Check if ports are available
sudo netstat -tulpn | grep LISTEN

# Restart
docker compose down
docker compose up -d
```

### Out of Memory

```bash
# Check memory usage
free -h
docker stats

# If needed, upgrade Lightsail instance
# AWS Console → Instance → Power
```

### Database Connection Failed

```bash
# Check PostgreSQL
docker compose logs postgres

# Test connection
docker compose exec postgres psql -U vetrai -c "SELECT 1"

# Restart PostgreSQL
docker compose restart postgres
```

### High CPU Usage

```bash
# Find resource hogs
docker stats

# Check specific service logs
docker compose logs vetrai

# Limit resources in docker-compose.yml
```

---

## Cost Optimization

### Minimize Costs:
- Use **Small (1GB)** plan for testing: $5/month
- Use **Medium (2GB)** plan for production: $10/month
- Static IP: **Free** (if instance running)
- Data transfer: First 1TB free per month

### Avoid Charges:
- Delete unused snapshots
- Remove static IPs before deleting instance
- Monitor data transfer usage

---

## Backup Strategy

### Daily Backups

```bash
#!/bin/bash
# Create ~/backup-daily.sh

mkdir -p ~/backups
BACKUP_FILE=~/backups/vetrai_$(date +%Y%m%d).sql.gz

docker compose exec -T postgres pg_dump -U vetrai vetrai | gzip > $BACKUP_FILE

# Keep only last 7 days
find ~/backups -name "vetrai_*.sql.gz" -mtime +7 -delete
```

Schedule with crontab:
```bash
crontab -e
# Add line:
# 0 2 * * * ~/backup-daily.sh
```

### Lightsail Snapshots

```bash
# AWS Console
# Instance → Snapshots → Create snapshot
# Name: vetrai-prod-backup-YYYY-MM-DD

# Or via AWS CLI
aws lightsail create-instance-snapshot \
  --instance-name vetrai-prod \
  --snapshot-name vetrai-prod-backup-$(date +%Y-%m-%d)
```

---

## Performance Tuning

### For Small (1GB) Plans:

```yaml
services:
  vetrai:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M

  postgres:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
```

### Enable Swap

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## Security Checklist

- [ ] Change default PostgreSQL password
- [ ] Configure firewall (close unnecessary ports)
- [ ] Set up SSH key authentication only
- [ ] Enable SSL/TLS certificates
- [ ] Set up regular backups
- [ ] Monitor CloudWatch metrics
- [ ] Disable password-based SSH
- [ ] Configure auto-updates (optional)

---

## Restore from Snapshot

```bash
# AWS Console or CLI
aws lightsail create-instances-from-snapshot \
  --instance-snapshot-name vetrai-prod-backup-2026-02-07 \
  --instance-names vetrai-prod-restored \
  --region us-east-1
```

---

## Useful Links

- [AWS Lightsail Documentation](https://docs.aws.amazon.com/lightsail/)
- [Lightsail Pricing](https://lightsail.aws.amazon.com/pricing)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [PostgreSQL Backup Guide](https://www.postgresql.org/docs/16/backup.html)

---

## Support

For issues:
1. Check service logs: `docker compose logs`
2. Review this guide's troubleshooting section
3. Check AWS Lightsail status: https://status.aws.amazon.com/
4. Contact AWS Support (premium plans)

---

**Last Updated**: February 7, 2026
**VetRAI Version**: 1.8.0

