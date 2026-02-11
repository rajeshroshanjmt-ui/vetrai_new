# Docker Compose Setup Guide for Vetrai

This guide covers containerizing the Vetrai application with Docker Compose, including the new JWT authentication system.

---

## 🎯 Overview

The Docker Compose setup provides:
- ✅ **PostgreSQL Database** - Data persistence
- ✅ **FastAPI Backend** - Langflow + JWT auth
- ✅ **React Frontend** - With authentication UI
- ✅ **Health Checks** - Auto-restart on failure
- ✅ **Networks** - Isolated service communication
- ✅ **Volumes** - Persistent data storage
- ✅ **Environment Variables** - Production-ready configuration

---

## 📋 Prerequisites

### Required
- **Docker** - v20.10+
- **Docker Compose** - v2.0+

### Installation
```bash
# macOS (via Homebrew)
brew install docker docker-compose

# Linux (Ubuntu/Debian)
sudo apt-get install docker.io docker-compose

# Windows
# Download and install Docker Desktop from https://www.docker.com/products/docker-desktop
```

---

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/rajeshroshanjmt-ui/vetrai_new.git
cd vetrai_new
cp .env.example .env
```

### 2. Configure Environment Variables
Edit `.env` file:
```bash
# Set strong JWT secret
SECRET_KEY=$(python -c "import secrets; print(secrets.token_urlsafe(32))")

# Update .env with the secret
sed -i "s/your-super-secret-key-change-in-production/$SECRET_KEY/" .env
```

Or manually:
```bash
# Generate secret
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Copy to .env
SECRET_KEY=<generated-key>
```

### 3. Start Services
```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Watch specific service
docker-compose logs -f backend
docker-compose logs -f frontend
```

### 4. Verify Services
```bash
# Check service status
docker-compose ps

# Test API
curl http://localhost:7860/health_check

# Test Frontend
open http://localhost:3000  # or http://localhost
```

### 5. Login
```
URL: http://localhost:3000
Username: admin
Password: admin123
```

---

## 📊 Service Configuration

### Services in docker-compose.yml

| Service | Port | Role | Image |
|---------|------|------|-------|
| postgres | 5432 | Database | postgres:16-alpine |
| backend | 7860 | API + Langflow | FastAPI (custom build) |
| frontend | 3000/80 | Web UI | Node.js/Nginx (multi-stage) |

### Environment Variables

```bash
# Database
DB_USER=vetrai
DB_PASSWORD=vetrai           # CHANGE IN PRODUCTION!
DB_NAME=vetrai
DB_PORT=5432

# JWT Authentication
SECRET_KEY=your-secret-key   # CHANGE - use secrets.token_urlsafe(32)
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Services
BACKEND_PORT=7860
FRONTEND_PORT=3000

# Superuser (auto-created on first run)
SUPERUSER=admin
SUPERUSER_PASSWORD=admin123  # CHANGE IN PRODUCTION!
```

---

## 🛠️ Common Commands

### Start/Stop Services
```bash
# Start all services in background
docker-compose up -d

# Start with logging
docker-compose up

# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: loses data!)
docker-compose down -v

# Restart specific service
docker-compose restart backend
```

### View Logs
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs backend
docker-compose logs frontend
docker-compose logs postgres

# Live logs with follow
docker-compose logs -f

# Last N lines
docker-compose logs --tail=100 backend

# With timestamps
docker-compose logs --timestamps backend
```

### Build Images
```bash
# Build without cache
docker-compose build --no-cache

# Build specific service
docker-compose build backend
docker-compose build frontend

# Rebuild and restart
docker-compose up -d --build
```

### Execute Commands
```bash
# SSH into container
docker-compose exec backend bash
docker-compose exec frontend sh

# Run database migrations
docker-compose exec backend alembic upgrade head

# Create test user
docker-compose exec backend python -c \
  "from vetrai.auth.service import AuthService, UserService; ... "

# Check database
docker-compose exec postgres psql -U vetrai -d vetrai
```

### Database Operations
```bash
# Access database shell
docker-compose exec postgres psql -U vetrai -d vetrai

# Create backup
docker-compose exec postgres pg_dump -U vetrai vetrai > backup.sql

# Restore backup
docker-compose exec -T postgres psql -U vetrai vetrai < backup.sql

# Reset database (WARNING: deletes all data!)
docker-compose exec -T postgres psql -U vetrai -c "DROP DATABASE vetrai; CREATE DATABASE vetrai;"
```

---

## 🔐 Production Deployment

### Security Checklist
- [ ] Change `SECRET_KEY` to a strong random value
- [ ] Change `DB_PASSWORD` to a strong random value
- [ ] Change `SUPERUSER_PASSWORD` to a strong random value
- [ ] Set `NODE_ENV=production`
- [ ] Set `LOG_LEVEL=warning` or `error`
- [ ] Enable HTTPS (use nginx with SSL)
- [ ] Restrict `CORS_ORIGINS` to your domain
- [ ] Set up automated backups
- [ ] Enable monitoring/alerting
- [ ] Use environment variables from secure vaults

### Generate Secrets
```bash
# JWT Secret (run once, store securely)
python -c "import secrets; print('SECRET_KEY=' + secrets.token_urlsafe(32))"

# DB Password
python -c "import secrets; print(secrets.token_urlsafe(24))"

# Or use openssl
openssl rand -base64 32
```

### Production docker-compose
```bash
# Use environment file for sensitive data
docker-compose --env-file .env.production up -d

# Use specific compose file
docker-compose -f docker-compose.yml -f docker-compose.production.yml up -d
```

### Backup Strategy
```bash
# Daily automatic backup
0 2 * * * docker-compose exec -T postgres pg_dump -U vetrai vetrai > /backups/vetrai_$(date +\%Y\%m\%d).sql
```

---

## 📈 Scaling & Performance

### Horizontal Scaling
```bash
# Scale backend services (requires load balancer)
docker-compose up -d --scale backend=3

# Note: Current setup supports single backend; use swarm/k8s for scaling
```

### Resource Limits
Add to docker-compose.yml for each service:
```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
```

### Database Optimization
```bash
# Connect to database
docker-compose exec postgres psql -U vetrai -d vetrai

# Run VACUUM (optimize)
VACUUM ANALYZE;

# Check indexes
\d auth_users

# Add performance indexes
CREATE INDEX idx_auth_users_org_id ON auth_users(org_id);
CREATE INDEX idx_auth_users_created_at ON auth_users(created_at);
```

---

## 🐛 Troubleshooting

### Service Won't Start
```bash
# Check logs
docker-compose logs backend

# Common issues:
# 1. Port already in use
lsof -i :7860
# Kill process: kill -9 <PID>

# 2. Database not ready
docker-compose up -d postgres
sleep 10
docker-compose up -d backend

# 3. Build errors
docker-compose build --no-cache backend
```

### Database Connection Error
```bash
# Test database connection
docker-compose exec postgres psql -U vetrai -d vetrai -c "SELECT 1"

# Check database URL is correct
echo $LANGFLOW_DATABASE_URL

# Verify network
docker network inspect vetrai_network
```

### Migration Failed
```bash
# Check migration status
docker-compose exec backend alembic current

# View specific revision
docker-compose exec backend alembic show a001_add_auth_users_table

# Re-run migrations
docker-compose exec backend alembic upgrade head
```

### Authentication Issues
```bash
# Check JWT secret is set
grep SECRET_KEY .env

# Test login endpoint
curl -X POST http://localhost:7860/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Check frontend logs
docker-compose logs frontend
```

### Disk Space Issues
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Check volume sizes
du -sh /var/lib/docker/volumes/*/

# Clean Docker system
docker system prune -a --volumes
docker system df
```

---

## 📊 Monitoring

### Basic Monitoring
```bash
# View resource usage
docker stats

# Persistent monitoring
docker stats --no-stream

# Check specific service
docker stats vetrai_backend
```

### Health Checks
```bash
# View health status
docker-compose ps

# Manual health check
docker-compose exec backend curl -f http://localhost:7860/health_check
docker-compose exec postgres pg_isready -U vetrai
```

---

## 🔄 Upgrades & Maintenance

### Update Services
```bash
# Pull latest code
git pull origin main

# Rebuild images
docker-compose build --no-cache

# Restart services with new images
docker-compose up -d
```

### Database Migration
```bash
# Before upgrading, backup database
docker-compose exec postgres pg_dump -U vetrai vetrai > backup_before_upgrade.sql

# Apply migrations
docker-compose exec backend alembic upgrade head

# Verify
docker-compose exec backend alembic current
```

### Rolling Restart (zero downtime)
```bash
# Restart one service at a time
docker-compose up -d --no-deps --build backend
docker-compose up -d --no-deps --build frontend
```

---

## 📁 File Structure

```
vetrai_new/
├── docker-compose.yml           # Main compose config
├── .env.example                 # Environment template
├── .env                         # Production config (create from example)
├── docker/
│   ├── fix.Dockerfile          # Backend build
│   └── frontend/
│       ├── Dockerfile.frontend # Frontend build
│       └── nginx.conf          # Nginx config
├── src/
│   ├── backend/
│   │   └── base/vetrai/auth/  # JWT auth module
│   └── frontend/               # React app
└── volumes/
    └── (auto-created by Docker)
```

---

## 🆘 Support

### View Detailed Logs
```bash
docker-compose logs --timestamps --tail=200 backend
```

### Export Diagnostics
```bash
# Save system info and logs
docker version > diagnostics.txt
docker-compose version >> diagnostics.txt
docker-compose ps >> diagnostics.txt
docker-compose logs --timestamps >> diagnostics.txt
```

---

## 📚 Related Documentation

- [Bearer Token Auth Setup](./AUTH_SETUP_GUIDE.md)
- [Quick Reference](./AUTH_QUICK_REFERENCE.md)
- [Docker Official Docs](https://docs.docker.com/)
- [Docker Compose Docs](https://docs.docker.com/compose/)

---

**Last Updated:** February 11, 2026  
**Version:** 1.0
