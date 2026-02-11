# VetRAI Production Deployment

This folder contains the production-ready docker-compose configuration for deploying VetRAI.

## Quick Start

### 1. Clone/Setup
```bash
cd vetrai_prod
```

### 2. Configure Environment (Optional)
Edit `.env` file with your custom settings:
```bash
cp .env .env.local
# Edit .env.local with your values
```

### 3. Deploy
```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Check service status
docker compose ps
```

### 4. Access Services
- **Frontend**: http://localhost
- **Backend API**: http://localhost/api/v1/
- **Health Check**: http://localhost/health_check
- **API Version**: http://localhost/api/v1/version

---

## Services

### 1. PostgreSQL Database
- **Image**: `postgres:16-alpine`
- **Port**: 5432 (internal only)
- **Volume**: `vetrai_postgres_data` - persistent database storage
- **Status**: Healthy when `pg_isready` returns success

### 2. VetRAI Backend API
- **Image**: `root2wings/vetrai:latest`
- **Port**: 7860 (internal)
- **Framework**: FastAPI + Uvicorn
- **Dependencies**: 125 Python packages (langchain, PostgreSQL driver, etc.)
- **Health Check**: `/health_check` endpoint

### 3. Nginx Reverse Proxy
- **Image**: `root2wings/vetrai-nginx:latest`
- **Port**: 80 (HTTP public)
- **Purpose**: Routes external traffic to backend on port 7860
- **Health Check**: HTTP GET on root path

---

## Management Commands

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f vetrai
docker compose logs -f nginx
docker compose logs -f postgres
```

### Stop Services
```bash
docker compose down
```

### Stop and Remove Data
```bash
docker compose down -v
```

### Restart Services
```bash
docker compose restart
docker compose restart vetrai   # Specific service
```

### Update Images
```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d
```

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `VETRAI_DATABASE_URL` | PostgreSQL connection string | `postgresql://vetrai:vetrai@postgres:5432/vetrai` |
| `VETRAI_SUPERUSER` | Admin username | `vetrai` |
| `VETRAI_SUPERUSER_PASSWORD` | Admin password | `vetrai` |
| `BACKEND_URL` | Backend service URL (internal) | `http://vetrai:7860` |
| `FRONTEND_PORT` | Nginx listening port | `80` |
| `LANGFLOW_MAX_FILE_SIZE_UPLOAD` | Max upload size (MB) | `100` |

---

## Health Checks

- **PostgreSQL**: `pg_isready` command (interval: 10s)
- **Backend**: `curl http://localhost:7860/health_check` (interval: 30s)
- **Frontend**: `curl http://localhost/` (interval: 30s)

Check health status:
```bash
docker compose ps
```

Look for `(healthy)` status:
```
vetrai_app_prod      Up 2 minutes (healthy)     ✅
vetrai_nginx_prod    Up 2 minutes (healthy)     ✅
vetrai_postgres_prod Up 2 minutes (healthy)     ✅
```

---

## Troubleshooting

### Services not healthy
```bash
# Check service logs
docker compose logs vetrai

# Check specific error
docker compose ps

# Restart unhealthy service
docker compose restart vetrai
```

### Database connection errors
```bash
# Verify PostgreSQL is running
docker compose logs postgres

# Check database credentials in .env
cat .env | grep POSTGRES
```

### Port already in use
If port 80 is already in use:
```bash
# Edit docker-compose.yml
# Change: "80:80" to "8080:80" to use port 8080 instead
```

### Image pull errors
```bash
# Verify you're logged into Docker Hub
docker login

# Pull images manually
docker pull root2wings/vetrai:latest
docker pull root2wings/vetrai-nginx:latest
```

---

## Security Notes

⚠️ **For Production**:
1. Change default passwords in `.env`
2. Use environment variables for sensitive data
3. Use HTTPS/SSL certificates
4. Restrict database port 5432 access
5. Set up proper firewall rules
6. Use strong credentials for Docker Hub

---

## Performance Tuning

### Database
- Adjust `shared_buffers` in PostgreSQL settings
- Enable query caching
- Set up read replicas for scaling

### Backend
- Increase `uvicorn` workers: `--workers 4`
- Enable gzip compression
- Use CDN for static assets

### Frontend
- Serve static files via CDN
- Enable browser caching
- Minimize JavaScript bundles

---

## Deployment to Cloud Providers

### AWS ECS
```bash
# Create ECS task definition from docker-compose.yml
ecs-cli compose create --file docker-compose.yml
```

### Google Cloud Run
```bash
# Push images
docker push root2wings/vetrai:latest
docker push root2wings/vetrai-nginx:latest

# Deploy via Cloud Run
gcloud run deploy vetrai --image root2wings/vetrai:latest
```

### DigitalOcean App Platform
- Use docker-compose.yml directly in App Platform UI
- Set environment variables
- Configure domain and SSL

---

## Support & Documentation

- **Issues**: Check logs with `docker compose logs`
- **API Docs**: http://localhost/docs (Swagger UI)
- **ReDoc**: http://localhost/redoc
- **Version Info**: http://localhost/api/v1/version

---

## Next Steps

1. ✅ Verify all services are healthy: `docker compose ps`
2. ✅ Test API endpoints: `curl http://localhost/api/v1/version`
3. ✅ Access Frontend: Open browser to http://localhost
4. 📊 Set up monitoring and alerting
5. 🔐 Configure SSL/TLS certificates
6. 📈 Set up backups for PostgreSQL database

---

**Last Updated**: February 7, 2026
**Images**: root2wings/vetrai:latest | root2wings/vetrai-nginx:latest
