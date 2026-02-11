# VetRAI Lightsail Deployment - Manual Commands

Copy and paste each command one at a time into PowerShell.

## Prerequisites
- SSH key: `C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem`
- Instance IP: `18.208.169.120`

---

## STEP 1: Test SSH Connection
```powershell
ssh -i "C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem" ubuntu@18.208.169.120 "whoami"
```
**Expected output**: `ubuntu`

If this works, continue. If it times out or fails, your instance may need a restart in AWS Console.

---

## STEP 2: Create Application Directory
```powershell
ssh -i "C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem" ubuntu@18.208.169.120 "mkdir -p ~/vetrai-prod"
```

---

## STEP 3: Copy docker-compose.yml to Instance

First, save this docker-compose.yml content locally:

```powershell
$compose = @'
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
'@

$compose | Out-File -FilePath "$env:TEMP\docker-compose.yml" -Encoding UTF8
```

Then copy it to the instance:

```powershell
scp -i "C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem" "$env:TEMP\docker-compose.yml" ubuntu@18.208.169.120:~/vetrai-prod/docker-compose.yml
```

---

## STEP 4: Pull Docker Images
```powershell
ssh -i "C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem" ubuntu@18.208.169.120 "cd ~/vetrai-prod && docker compose pull"
```

**Expected**: Shows "Pull complete" for 3 services (postgres, vetrai, nginx)

---

## STEP 5: Start Services
```powershell
ssh -i "C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem" ubuntu@18.208.169.120 "cd ~/vetrai-prod && docker compose up -d"
```

**Expected**: Shows 3 services started

---

## STEP 6: Wait for Services to Be Healthy
```powershell
ssh -i "C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem" ubuntu@18.208.169.120 "sleep 15 && cd ~/vetrai-prod && docker compose ps"
```

**Expected output shows all services healthy**:
```
NAME                     STATUS
vetrai_postgres_prod     Up (healthy)
vetrai_app_prod          Up (healthy)
vetrai_nginx_prod        Up (healthy)
```

---

## STEP 7: Verify API Endpoints (Optional)
```powershell
ssh -i "C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem" ubuntu@18.208.169.120 "curl -s http://localhost/health_check"
```

**Expected**: Returns JSON like `{"status":"ok"}`

---

## STEP 8: Access Your Application

Open in your web browser:
- **Frontend**: http://18.208.169.120
- **API Documentation**: http://18.208.169.120/docs
- **Health Check**: http://18.208.169.120/health_check

---

## Troubleshooting

**If SSH times out**:
1. Go to AWS Console → Lightsail → Instances
2. If status is "Pending", wait for it to complete
3. Click "Restart instance" and wait 60 seconds
4. Try SSH again

**If services don't start**:
```powershell
ssh -i "C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem" ubuntu@18.208.169.120 "cd ~/vetrai-prod && docker compose logs"
```

**If images won't download**:
Try pulling again:
```powershell
ssh -i "C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem" ubuntu@18.208.169.120 "docker pull root2wings/vetrai:latest"
```

---

## Quick Reference Commands

```powershell
# View logs
ssh -i "C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem" ubuntu@18.208.169.120 "cd ~/vetrai-prod && docker compose logs -f"

# Stop services
ssh -i "C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem" ubuntu@18.208.169.120 "cd ~/vetrai-prod && docker compose down"

# Restart services  
ssh -i "C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem" ubuntu@18.208.169.120 "cd ~/vetrai-prod && docker compose restart"

# Check memory usage
ssh -i "C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem" ubuntu@18.208.169.120 "docker stats --no-stream"
```

---

## Success Criteria

When deployment is complete, you should be able to:
✅ Access http://18.208.169.120 in browser
✅ See VetRAI interface loading
✅ Visit http://18.208.169.120/docs to see API documentation
✅ All 3 services show "healthy" in `docker compose ps`

🎉 **Deployment successful!**
