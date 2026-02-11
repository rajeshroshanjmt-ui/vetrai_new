# VetRAI Production Advanced Configuration

This file contains advanced configuration examples for production deployments.

## 1. Scaling the Backend (Load Balancing)

To run multiple backend instances with a load balancer:

```yaml
services:
  backend-1:
    image: root2wings/vetrai:latest
    environment:
      VETRAI_DATABASE_URL: postgresql://vetrai:vetrai@postgres:5432/vetrai
    networks:
      - vetrai_network

  backend-2:
    image: root2wings/vetrai:latest
    environment:
      VETRAI_DATABASE_URL: postgresql://vetrai:vetrai@postgres:5432/vetrai
    networks:
      - vetrai_network

  backend-3:
    image: root2wings/vetrai:latest
    environment:
      VETRAI_DATABASE_URL: postgresql://vetrai:vetrai@postgres:5432/vetrai
    networks:
      - vetrai_network

  # HAProxy Load Balancer
  haproxy:
    image: haproxy:2.8
    ports:
      - "7860:7860"
    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
    networks:
      - vetrai_network
    depends_on:
      - backend-1
      - backend-2
      - backend-3
```

### HAProxy Configuration (haproxy.cfg):

```
global
  log stdout local0
  maxconn 4096

defaults
  mode http
  timeout connect 5s
  timeout client 50s
  timeout server 50s

frontend vetrai_frontend
  bind *:7860
  default_backend vetrai_backends

backend vetrai_backends
  balance roundrobin
  server backend-1 backend-1:7860 check
  server backend-2 backend-2:7860 check
  server backend-3 backend-3:7860 check
```

---

## 2. SSL/TLS with Nginx

To enable HTTPS, modify docker-compose.yml:

```yaml
nginx:
  image: root2wings/vetrai-nginx:latest
  ports:
    - "80:80"
    - "443:443"  # HTTPS
  volumes:
    - /path/to/ssl/cert.pem:/etc/nginx/ssl/cert.pem:ro
    - /path/to/ssl/key.pem:/etc/nginx/ssl/key.pem:ro
    - ./nginx-ssl.conf:/etc/nginx/conf.d/default.conf.template:ro
  environment:
    ENABLE_SSL: "true"
```

### Nginx SSL Configuration (nginx-ssl.conf):

```nginx
upstream vetrai_backend {
    server vetrai:7860;
}

server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://vetrai_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 3. Database Optimization

### PostgreSQL Connection Pooling with PgBouncer

```yaml
pgbouncer:
  image: pgbouncer:latest
  environment:
    DATABASES_HOST: postgres
    DATABASES_PORT: 5432
    DATABASES_USER: vetrai
    DATABASES_PASSWORD: vetrai
    DATABASES_DBNAME: vetrai
    POOL_MODE: transaction
    MAX_CLIENT_CONN: 1000
    DEFAULT_POOL_SIZE: 25
  ports:
    - "6432:6432"
  depends_on:
    - postgres
```

Update backend connection string:
```
VETRAI_DATABASE_URL=postgresql://vetrai:vetrai@pgbouncer:6432/vetrai
```

---

## 4. Monitoring & Logging (Prometheus + Grafana)

```yaml
prometheus:
  image: prom/prometheus:latest
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    - prometheus_data:/prometheus
  ports:
    - "9090:9090"
  networks:
    - vetrai_network

grafana:
  image: grafana/grafana:latest
  environment:
    GF_SECURITY_ADMIN_PASSWORD: admin
  ports:
    - "3000:3000"
  volumes:
    - grafana_data:/var/lib/grafana
  networks:
    - vetrai_network
  depends_on:
    - prometheus

volumes:
  prometheus_data:
  grafana_data:
```

### Prometheus Configuration (prometheus.yml):

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'vetrai'
    static_configs:
      - targets: ['vetrai:8000']

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres_exporter:9187']

  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx_exporter:9113']
```

---

## 5. Backup & Recovery

### Automated Backup Script

```bash
#!/bin/bash
# backup.sh - Daily database backup

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/vetrai_backup_$TIMESTAMP.sql"

mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL database
docker compose exec -T postgres pg_dump -U vetrai vetrai > "$BACKUP_FILE"
gzip "$BACKUP_FILE"

# Keep only last 7 days of backups
find "$BACKUP_DIR" -name "vetrai_backup_*.sql.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_FILE.gz"
```

### Recovery Script

```bash
#!/bin/bash
# restore.sh - Restore from backup

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Restore PostgreSQL database
gunzip -c "$BACKUP_FILE" | docker compose exec -T postgres psql -U vetrai vetrai

echo "Database restored from: $BACKUP_FILE"
```

---

## 6. Resource Limits & Health Checks

```yaml
services:
  vetrai:
    image: root2wings/vetrai:latest
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:7860/health_check"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  postgres:
    image: postgres:16-alpine
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 1G
```

---

## 7. Multi-Region Deployment (Docker Swarm)

Initialize Docker Swarm:
```bash
docker swarm init
docker swarm join-token worker
```

Deploy stack:
```bash
docker stack deploy -c docker-compose.yml vetrai_prod
```

---

## 8. Environment-Specific Configurations

### Development (.env.dev)
```
LOG_LEVEL=DEBUG
DATABASE_ECHO=true
ENABLE_DOCS=true
```

### Staging (.env.staging)
```
LOG_LEVEL=INFO
DATABASE_ECHO=false
ENABLE_DOCS=true
CORS_ORIGINS=https://staging.example.com
```

### Production (.env.prod)
```
LOG_LEVEL=WARNING
DATABASE_ECHO=false
ENABLE_DOCS=false
CORS_ORIGINS=https://example.com
```

Load with:
```bash
docker compose --env-file .env.prod up -d
```

---

## 9. Zero-Downtime Deployments

### Blue-Green Deployment

```bash
#!/bin/bash
# blue-green-deploy.sh

# Deploy new version to "green"
docker compose -f docker-compose.green.yml up -d

# Test green environment
curl http://localhost:8081/health_check

# Switch nginx routing to green
cp nginx-green.conf nginx.conf

# Reload nginx
docker compose exec nginx reload

# Stop blue environment
docker compose -f docker-compose.blue.yml down
```

---

## 10. Disaster Recovery Plan

1. **Regular Backups**: Weekly database backups to S3
2. **Backup Testing**: Monthly restore drills
3. **Documentation**: Keep deployment notes updated
4. **Monitoring**: Set up alerts for critical issues
5. **Runbook**: Create incident response procedures
6. **Replication**: Consider database replication
7. **DNS**: Use dynamic DNS for failover

---

## Performance Tuning Checklist

- [ ] Enable database connection pooling (PgBouncer)
- [ ] Configure resource limits for containers
- [ ] Set up monitoring (Prometheus + Grafana)
- [ ] Enable SSL/TLS certificates
- [ ] Configure CDN for static assets
- [ ] Enable caching (Redis/Memcached)
- [ ] Load balance multiple backend instances
- [ ] Set up log aggregation (ELK Stack)
- [ ] Configure backup and recovery procedures
- [ ] Set up alerts and notifications

---

**For support**: Check README.md or Docker logs

