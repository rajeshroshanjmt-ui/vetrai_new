# Manual Step-by-Step VetRAI Deployment
# This guides you through manual deployment if automated script times out

param(
    [string]$KeyPath = " C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem",
    [string]$InstanceIP = "18.208.169.120",
    [string]$Username = "ubuntu"
)

Write-Host "VetRAI Manual Deployment Guide for Lightsail" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will guide you through manual deployment steps." -ForegroundColor Yellow
Write-Host "Instance: $InstanceIP" -ForegroundColor Yellow
Write-Host ""

# Step 1: Test SSH
Write-Host "[STEP 1] Test SSH Connection" -ForegroundColor Cyan
Write-Host "Run this SSH command and confirm you see output:" -ForegroundColor Green
Write-Host ""
Write-Host "  ssh -i `"$KeyPath`" $Username@$InstanceIP `"uname -a`"" -ForegroundColor Yellow
Write-Host ""
$response = Read-Host "Did SSH work? (yes/no)"
if ($response -ne "yes") {
    Write-Host "SSH not working. Please check:" -ForegroundColor Red
    Write-Host "  1. Key path correct: $KeyPath" -ForegroundColor Red
    Write-Host "  2. Instance IP correct: $InstanceIP" -ForegroundColor Red
    Write-Host "  3. Lightsail firewall allows port 22" -ForegroundColor Red
    exit 1
}

Write-Host "`nSSH connection confirmed!" -ForegroundColor Green

# Step 2: Create docker-compose file locally
Write-Host "`n[STEP 2] Create docker-compose.yml" -ForegroundColor Cyan

$dockerComposeContent = @'
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

$tempFile = [System.IO.Path]::GetTempFileName()
$dockerComposeContent | Out-File -FilePath $tempFile -Encoding UTF8
Write-Host "Created temporary docker-compose.yml: $tempFile" -ForegroundColor Green

# Step 3: Copy to remote
Write-Host "`n[STEP 3] Copy docker-compose.yml to Lightsail" -ForegroundColor Cyan
Write-Host "Run this SCP command:" -ForegroundColor Green
Write-Host ""
Write-Host "  scp -i `"$KeyPath`" `"$tempFile`" $Username@$InstanceIP`:~/docker-compose.yml" -ForegroundColor Yellow
Write-Host ""
$response = Read-Host "Run this command (copy-paste to terminal) then press Enter (yes when done)"

Write-Host "`nAssuming SCP completed..." -ForegroundColor Green

# Step 4: Start services
Write-Host "`n[STEP 4] Start Docker Services" -ForegroundColor Cyan
Write-Host "Run this SSH command:" -ForegroundColor Green
Write-Host ""
Write-Host "  ssh -i `"$KeyPath`" $Username@$InstanceIP `"cd HOME && docker compose -f docker-compose.yml pull`"" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Then:" -ForegroundColor Green
Write-Host ""
Write-Host "  ssh -i `"$KeyPath`" $Username@$InstanceIP `"cd ~ && docker compose -f docker-compose.yml up -d`"" -ForegroundColor Yellow
Write-Host ""
$response = Read-Host "Run both commands then press Enter (yes when done)"

Write-Host "`nServices started!" -ForegroundColor Green

# Step 5: Verify
Write-Host "`n[STEP 5] Verify Deployment" -ForegroundColor Cyan
Write-Host "Check service status with:" -ForegroundColor Green
Write-Host ""
Write-Host "  ssh -i `"$KeyPath`" $Username@$InstanceIP `"docker compose ps`"" -ForegroundColor Yellow
Write-Host ""
Write-Host "All services should show 'Up' status and be 'healthy'" -ForegroundColor Cyan
Write-Host ""

# Step 6: Access
Write-Host "[STEP 6] Access Your Application" -ForegroundColor Cyan
Write-Host ""
Write-Host "Open in browser:" -ForegroundColor Green
Write-Host "  Frontend:   http://$InstanceIP" -ForegroundColor Yellow
Write-Host "  API Docs:   http://$InstanceIP/docs" -ForegroundColor Yellow
Write-Host "  Health:     http://$InstanceIP/health_check" -ForegroundColor Yellow
Write-Host ""

# Cleanup
Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

Write-Host "Deployment guide complete!" -ForegroundColor Green
