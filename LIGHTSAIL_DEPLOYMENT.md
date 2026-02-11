# VetRAI Deployment to AWS Lightsail

AWS Lightsail is a simple, affordable way to launch and manage cloud instances. This guide covers deploying VetRAI to Lightsail.

---

## Prerequisites

1. AWS Account with Lightsail enabled
2. Docker & Docker Compose installed on Lightsail instance
3. SSH access to your Lightsail instance
4. 2GB+ RAM and 20GB+ storage recommended

---

## Step 1: Create Lightsail Instance

### Via AWS Console:

1. Go to **AWS Lightsail** → **Instances**
2. Click **Create instance**
3. **Choose location**: Select your region (e.g., us-east-1)
4. **Choose image**: Select "Ubuntu 22.04 LTS"
5. **Choose plan**: 
   - Basic: $3.50/month (512MB RAM) - NOT recommended
   - **Standard: $5/month (1GB RAM)** - Minimum for testing
   - **Performance: $10/month (2GB RAM)** - ✅ Recommended for production
6. **Instance name**: e.g., `vetrai-prod`
7. Click **Create instance**

### Via AWS CLI:

```bash
aws lightsail create-instances \
  --instance-names vetrai-prod \
  --availability-zone us-east-1a \
  --blueprint-id ubuntu_22_04 \
  --bundle-id small_2_0 \
  --region us-east-1
```

---

## Step 2: Connect to Lightsail Instance

### Option 1: Browser SSH (Easiest)
1. In AWS Console → Lightsail Instances
2. Click your instance
3. Click **Connect** (opens browser-based SSH terminal)

### Option 2: Terminal SSH

First, download key pair from Lightsail:
```bash
# Lightsail generates one default key pair for your account
# Download from: AWS Lightsail → Account page → SSH keys
```

Then connect:
```bash
ssh -i path/to/key.pem ubuntu@YOUR_LIGHTSAIL_IP
```

---

## Step 3: Install Docker & Docker Compose

Once connected to your Lightsail instance:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo apt install -y docker-compose

# Verify installation
docker --version
docker compose version

# Exit and reconnect for group changes to take effect
exit
# Then SSH back in
```

---

## Step 4: Deploy VetRAI to Lightsail

### Create deployment directory:

```bash
ssh ubuntu@YOUR_LIGHTSAIL_IP

# Create app directory
mkdir -p ~/vetrai-prod
cd ~/vetrai-prod
```

### Copy docker-compose.yml:

```bash
# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:16-alpine
    container_name: vetrai_postgres_prod
    restart: always
    environment:
      POSTGRES_USER: vetrai
      POSTGRES_PASSWORD: vetrai
      POSTGRES_DB: vetrai
      POSTGRES_INITDB_ARGS: "-E UTF8"
    volumes:
      - vetrai_postgres_data:/var/lib/postgresql/data
    networks:
      - vetrai_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U vetrai -d vetrai"]
      interval: 10s
      timeout: 5s
      retries: 5

  # VetRAI Backend
  vetrai:
    image: root2wings/vetrai:latest
    container_name: vetrai_app_prod
    restart: always
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      PYTHONDONTWRITEBYTECODE: 1
      VETRAI_DATABASE_URL: postgresql://vetrai:vetrai@postgres:5432/vetrai
      VETRAI_SUPERUSER: vetrai
      VETRAI_SUPERUSER_PASSWORD: vetrai
      VETRAI_CONFIG_DIR: /var/lib/vetrai
    ports:
      - "7860:7860"
    networks:
      - vetrai_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:7860/health_check"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Nginx Frontend
  nginx:
    image: root2wings/vetrai-nginx:latest
    container_name: vetrai_nginx_prod
    restart: always
    depends_on:
      - vetrai
    environment:
      BACKEND_URL: http://vetrai:7860
      FRONTEND_PORT: 80
      LANGFLOW_MAX_FILE_SIZE_UPLOAD: "100"
    ports:
      - "80:80"
    networks:
      - vetrai_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  vetrai_postgres_data:
    driver: local

networks:
  vetrai_network:
    driver: bridge
EOF
```

### Start services:

```bash
# Start VetRAI stack
docker compose up -d

# Monitor startup (wait ~30-60 seconds)
docker compose logs -f
```

---

## Step 5: Configure Lightsail Networking

### Open Firewall Ports:

In AWS Console → Lightsail Instances → **Manage** → **Networking**

**Add these rules:**
- ✅ IPv4: 80 (HTTP) - Allow all (0.0.0.0/0)
- ✅ IPv4: 443 (HTTPS) - Allow all (for future SSL)

**Keep closed:**
- ❌ 5432 (PostgreSQL) - Internal only
- ❌ 7860 (Backend) - Internal only (accessed via Nginx)

### Verify firewall:
```bash
ssh ubuntu@YOUR_LIGHTSAIL_IP

# Check listening ports
sudo netstat -tulpn | grep LISTEN
# or
docker compose ps
```

---

## Step 6: Enable Static IP (Optional but Recommended)

In AWS Console → Lightsail:

1. **Instances** → Your instance
2. **Networking** → **Create static IP**
3. Attach to your instance

Benefits:
- IP won't change if instance restarts
- Use domain name more reliably
- Better for DNS configuration

---

## Step 7: Configure Custom Domain (Optional)

### Option 1: Use Lightsail DNS

1. Go to **Lightsail** → **Domains**
2. Create new domain or register
3. Point DNS records to your Lightsail static IP
4. Wait for DNS propagation (24-48 hours)

### Option 2: Use External DNS (Route53, Namecheap, etc.)

Create A record pointing to Lightsail static IP:
```
Type: A
Name: vetrai.example.com
Value: YOUR_LIGHTSAIL_IP
TTL: 300
```

---

## Step 8: SSL/TLS Certificate (Let's Encrypt via Certbot)

```bash
ssh ubuntu@YOUR_LIGHTSAIL_IP

# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get certificate
sudo certbot certonly --standalone -d vetrai.example.com

# Certificates stored at:
# /etc/letsencrypt/live/vetrai.example.com/
```

---

## Step 9: Monitor & Manage

### Check service status:

```bash
ssh ubuntu@YOUR_LIGHTSAIL_IP
cd ~/vetrai-prod

# View running containers
docker compose ps

# Check logs
docker compose logs -f vetrai
docker compose logs -f nginx
docker compose logs -f postgres

# View resource usage
docker stats
```

### Common commands:

```bash
# Stop all services
docker compose down

# Start all services
docker compose up -d

# Restart a service
docker compose restart vetrai

# Update images and restart
docker compose pull
docker compose up -d

# View specific service logs
docker compose logs nginx --tail=100
```

---

## Step 10: Verify Deployment

### Test endpoints:

```bash
# From your local machine or Lightsail
curl http://YOUR_LIGHTSAIL_IP/health_check
# Expected: {"status":"ok","chat":"ok","db":"ok"}

curl http://YOUR_LIGHTSAIL_IP/api/v1/version
# Expected: {"version":"1.8.0","main_version":"1.8.0","package":"Vetrai"}
```

### Access in browser:

- **Frontend**: http://YOUR_LIGHTSAIL_IP
- **API Docs**: http://YOUR_LIGHTSAIL_IP/docs
- **ReDoc**: http://YOUR_LIGHTSAIL_IP/redoc

---

## Performance Tuning for Lightsail

### Option 1: Upgrade Instance Size

If slow performance:
```bash
# In AWS Console
# Lightsail Instance → Manage → Power
# Choose higher plan (small → medium → large)
```

### Option 2: Optimize Docker Configuration

Edit docker-compose.yml:
```yaml
services:
  vetrai:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
```

### Option 3: Enable Swap (for 1GB RAM instances)

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

---

## Backup & Recovery

### Backup Database:

```bash
# Create backup directory
mkdir -p ~/backups

# Backup PostgreSQL database
docker compose exec -T postgres pg_dump -U vetrai vetrai > ~/backups/vetrai_$(date +%Y%m%d_%H%M%S).sql

# Compress backup
gzip ~/backups/vetrai_*.sql
```

### Create Lightsail Snapshot:

In AWS Console → Lightsail Instances:
1. Select your instance
2. **Snapshots**
3. **Create snapshot**
4. Name it (e.g., `vetrai-prod-backup-2026-02-07`)

Benefits:
- Full instance backup
- Can restore to new instance
- Stored separately (separate charges)

### Restore from Snapshot:

```bash
aws lightsail create-instances-from-snapshot \
  --instance-snapshot-name vetrai-prod-backup-2026-02-07 \
  --instance-names vetrai-prod-restored \
  --region us-east-1
```

---

## Monitoring & Alerts (Optional)

### Enable CloudWatch monitoring:

```bash
# View metrics in AWS Console
# Lightsail Dashboard → Metrics

# Key metrics to watch:
# - CPU utilization
# - Network in/out
# - Disk read/write
```

### Set up email alerts:

```bash
# In AWS Console → CloudWatch → Alarms
# Create alarm for high CPU, high memory, etc.
```

---

## Troubleshooting

### Services not starting:

```bash
ssh ubuntu@YOUR_LIGHTSAIL_IP
cd ~/vetrai-prod

# Check logs
docker compose logs

# Restart services
docker compose down
docker compose up -d

# Check disk space
df -h

# Check memory
free -h
```

### Database connection errors:

```bash
# Check PostgreSQL
docker compose logs postgres

# Test connection
docker compose exec postgres psql -U vetrai -d vetrai -c "SELECT 1"
```

### High memory usage:

```bash
# Check which container uses most memory
docker stats

# Limit container resources
# Edit docker-compose.yml and add resources limits
```

---

## Cost Estimation

| Instance Type | Price/Month | Specs | Recommended For |
|---------------|------------|-------|-----------------|
| Nano (512MB) | $3.50 | 512MB RAM, 20GB SSD | Testing only |
| Small (1GB) | $5.00 | 1GB RAM, 40GB SSD | **Development** |
| Medium (2GB) | $10.00 | 2GB RAM, 60GB SSD | **Small production** |
| Large (4GB) | $20.00 | 4GB RAM, 80GB SSD | Production |

Additional costs:
- Static IP: Free (if instance running)
- Data transfer: $0.09/GB (after 1TB/month free)
- Database snapshots: $0.05/GB

---

## Cleanup

To avoid charges:

```bash
# Delete Lightsail instance
aws lightsail delete-instances --instance-names vetrai-prod

# Delete static IP
aws lightsail release-static-ip --static-ip-name vetrai-prod-ip

# Delete snapshots
aws lightsail delete-instance-snapshot --instance-snapshot-name vetrai-prod-backup-*
```

---

## Production Checklist

- [ ] Instance created with adequate resources (2GB+ RAM)
- [ ] Docker & Docker Compose installed
- [ ] VetRAI deployed and running
- [ ] Firewall rules configured (80, 443 open)
- [ ] Static IP assigned
- [ ] Domain configured (optional)
- [ ] SSL certificate obtained (optional)
- [ ] Backup snapshot created
- [ ] Health checks verified
- [ ] Monitoring enabled
- [ ] Team trained on management

---

For assistance, check service logs or consult the main README.md in vetrai_prod folder.

