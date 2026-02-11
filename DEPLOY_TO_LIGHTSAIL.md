# Deployment Guide for Your Lightsail Instance

**Instance Details:**
- IP Address: `18.208.169.120`
- IPv6: `2600:1f18:4def:ab00:65ff:7c7a:b3b:7f97`
- OS: Ubuntu 22.04 LTS
- Specs: 1 GB RAM, 2 vCPUs, 40 GB SSD
- Region: Virginia Zone A
- Status: Running ✅

---

## Step 1: SSH into Your Instance

### Windows (PowerShell)

```powershell
# Find your SSH key (usually named lightsail_default_key.pem or similar)
$keyPath = "C:\Users\LENOVO\Downloads\lightsail_key.pem"
$ip = "18.208.169.120"

# Connect
ssh -i $keyPath ubuntu@$ip
```

### Mac/Linux

```bash
ssh -i ~/Downloads/lightsail_key.pem ubuntu@18.208.169.120
```

---

## Step 2: System Preparation

Once connected via SSH:

```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo apt install -y docker-compose

# Verify installations
docker --version
docker compose version

# Exit and reconnect for group changes
exit
```

Then SSH back in:
```bash
ssh -i ~/path/to/key.pem ubuntu@18.208.169.120
```

---

## Step 3: Deploy VetRAI

### Create application directory

```bash
# Create directory
mkdir -p ~/vetrai-prod
cd ~/vetrai-prod

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
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
    deploy:
      resources:
        limits:
          memory: 512M

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

### Start services

```bash
# Pull images (1-2 minutes)
docker compose pull

# Start services (this will take a moment)
docker compose up -d

# Monitor startup (wait 30 seconds)
docker compose logs -f
```

Press `Ctrl+C` to exit logs when startup is complete.

---

## Step 4: Verify Deployment

```bash
# Check service status
docker compose ps

# Should show:
# NAME              SERVICE    STATUS              PORTS
# vetrai_nginx_prod      nginx          Up (healthy)        0.0.0.0:80->80/tcp
# vetrai_app_prod        vetrai         Up (healthy)        0.0.0.0:7860->7860/tcp
# vetrai_postgres_prod   postgres       Up (healthy)        
```

---

## Step 5: Configure Lightsail Firewall

**In AWS Console:**
1. Go to **Lightsail** → **Instances**
2. Click **vetrai** instance
3. Click **Networking** tab
4. **IPv4 Firewall** section

**Add these rules:**
- Protocol: HTTP, Port: 80, Allowed: 0.0.0.0/0 ✅
- Protocol: HTTPS, Port: 443, Allowed: 0.0.0.0/0 ✅
- Protocol: SSH, Port: 22, Allowed: 0.0.0.0/0 ✅

---

## Step 6: Access Your Application

### From Browser:

```
Frontend:    http://18.208.169.120
API Docs:    http://18.208.169.120/docs
ReDoc:       http://18.208.169.120/redoc
Health:      http://18.208.169.120/health_check
API Version: http://18.208.169.120/api/v1/version
```

### Test from CLI:

```bash
# On your local machine
curl http://18.208.169.120/health_check
# Expected: {"status":"ok","chat":"ok","db":"ok"}

curl http://18.208.169.120/api/v1/version
# Expected: {"version":"1.8.0",...}
```

---

## Management Commands

```bash
# SSH back into instance
ssh -i ~/path/to/key.pem ubuntu@18.208.169.120
cd ~/vetrai-prod

# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f vetrai
docker compose logs -f nginx
docker compose logs -f postgres

# Check resource usage
docker stats

# Stop all services
docker compose down

# Start all services
docker compose up -d

# Restart a service
docker compose restart vetrai

# Update to latest images
docker compose pull
docker compose up -d
```

---

## Memory Optimization (1GB RAM Instance)

For your 1GB instance, resource limits are already set:

```bash
# Check memory usage
docker stats

# If memory is full, check what's using it
docker ps -q | xargs docker inspect -f '{{.Name}} {{.Config.Memory}}' | head -10
```

If needed, enable swap:

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## Backup Setup

### Daily Database Backup

Create backup script:

```bash
mkdir -p ~/backups

cat > ~/backup-daily.sh << 'BACKUP'
#!/bin/bash
BACKUP_DIR="$HOME/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/vetrai_backup_${TIMESTAMP}.sql"

cd ~/vetrai-prod

# Backup database
docker compose exec -T postgres pg_dump -U vetrai vetrai > "$BACKUP_FILE"

# Compress
gzip "$BACKUP_FILE"

# Keep only last 7 days
find "$BACKUP_DIR" -name "vetrai_backup_*.sql.gz" -mtime +7 -delete

# Show result
ls -lh "$BACKUP_DIR" | tail -5
BACKUP

chmod +x ~/backup-daily.sh
```

Schedule it:

```bash
# Edit crontab
crontab -e

# Add this line (runs daily at 2 AM):
# 0 2 * * * $HOME/backup-daily.sh
```

---

## Static IP Setup (Optional)

To keep the same IP permanently:

1. **AWS Console** → **Lightsail** → **Instances** → **vetrai**
2. **Networking** tab
3. **Create static IP**
4. Attach to instance

Then use the static IP instead of the dynamic one.

---

## Domain Name Setup (Optional)

### Option 1: Lightsail Domains

1. **Lightsail** → **Domains**
2. Create or register domain
3. Add A record pointing to your IP (18.208.169.120)

### Option 2: External DNS Provider

Create A record:
```
Type: A
Host: vetrai.example.com
Value: 18.208.169.120
TTL: 300
```

---

## SSL Certificate (Let's Encrypt)

```bash
ssh ubuntu@18.208.169.120

# Install Certbot
sudo apt install -y certbot

# Stop Nginx temporarily
cd ~/vetrai-prod
docker compose stop nginx

# Get certificate
sudo certbot certonly --standalone -d vetrai.example.com

# Start Nginx
docker compose start nginx

# Certificate files:
# /etc/letsencrypt/live/vetrai.example.com/cert.pem
# /etc/letsencrypt/live/vetrai.example.com/privkey.pem
```

---

## Troubleshooting

### Services won't start

```bash
# Check logs for errors
docker compose logs

# Common issues on 1GB RAM:
# - Out of memory: Enable swap (see above)
# - Ports in use: sudo lsof -i :80
# - Disk full: df -h
```

### Database connection fails

```bash
# Check PostgreSQL
docker compose logs postgres

# Test connection
docker compose exec postgres psql -U vetrai -d vetrai -c "SELECT 1"
```

### High memory usage

```bash
# Monitor
docker stats

# Reduce limits if needed in docker-compose.yml
# Set memory: 256M instead of 512M
```

---

## Monitoring

### Check service health

```bash
# All services
curl http://18.208.169.120/health_check

# API version
curl http://18.208.169.120/api/v1/version

# Docker health status
docker compose ps
```

### View CloudWatch Metrics

1. **AWS Console** → **Lightsail** → **vetrai** → **Metrics**
2. Monitor CPU, Network, Disk I/O

---

## Next Steps

1. ✅ SSH into instance
2. ✅ Install Docker & Docker Compose
3. ✅ Deploy VetRAI (docker-compose.yml)
4. ✅ Configure Lightsail firewall
5. ✅ Access application at http://18.208.169.120
6. 📋 (Optional) Set up domain name
7. 📋 (Optional) Enable SSL certificate
8. 📋 (Optional) Configure backups

---

## Support Resources

- VetRAI Docs: Check README.md and API docs at http://18.208.169.120/docs
- Docker Docs: https://docs.docker.com/
- Lightsail Docs: https://docs.aws.amazon.com/lightsail/
- PostgreSQL Docs: https://www.postgresql.org/docs/

---

**Your VetRAI instance is ready to deploy!** 🚀

