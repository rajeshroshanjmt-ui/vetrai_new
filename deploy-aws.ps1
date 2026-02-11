# ================================
# VetRAI Frontend + Backend Deploy
# ================================

param(
    [string]$ProjectDir = "C:\Users\LENOVO\Rajesh\vetraiv1\vetrai_new",
    [string]$KeyPath    = "C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem",
    [string]$InstanceIP = "54.166.127.93",
    [string]$Username   = "ubuntu"
)

Write-Host "===================================" -ForegroundColor Cyan
Write-Host " VetRAI Deployment to AWS Lightsail " -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# 1️⃣ Validate project directory
if (-not (Test-Path $ProjectDir)) {
    Write-Host "ERROR: Project directory not found: $ProjectDir" -ForegroundColor Red
    exit 1
}

Set-Location $ProjectDir
Write-Host "Project directory OK" -ForegroundColor Green

# 2️⃣ Validate required files/folders
$required = @("docker-compose.yml")
foreach ($item in $required) {
    if (-not (Test-Path $item)) {
        Write-Host "ERROR: Missing required item: $item" -ForegroundColor Red
        exit 1
    }
}
Write-Host "Required files validated" -ForegroundColor Green

# 3️⃣ Verify docker-compose.yml is accessible
Write-Host "docker-compose.yml validated" -ForegroundColor Green

# 4️⃣ Test SSH connectivity
Write-Host "Testing SSH connection..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i "$KeyPath" "$Username@$InstanceIP" "echo SSH_OK" | Out-Null
Write-Host "SSH connection verified" -ForegroundColor Green

# 5️⃣ Create docker-compose.yml optimized for Lightsail (uses pre-built images)
Write-Host "Creating optimized docker-compose for Lightsail..." -ForegroundColor Cyan

$dockerComposeContent = @'
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: vetrai_postgres
    restart: always
    environment:
      POSTGRES_USER: vetrai
      POSTGRES_PASSWORD: vetrai
      POSTGRES_DB: vetrai
      POSTGRES_INITDB_ARGS: "-E UTF8"
    ports:
      - "5432:5432"
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
    container_name: vetrai_app
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
    volumes:
      - vetrai_config_data:/var/lib/vetrai
    networks:
      - vetrai_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:7860/health_check"]
      interval: 30s
      timeout: 10s
      retries: 3

  nginx:
    image: root2wings/vetrai-nginx:latest
    container_name: vetrai_nginx
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
  vetrai_config_data:
    driver: local

networks:
  vetrai_network:
    driver: bridge
'@

$tempFile = [System.IO.Path]::GetTempFileName() + ".yml"
$dockerComposeContent | Out-File -FilePath $tempFile -Encoding UTF8
Write-Host "Uploading optimized docker-compose.yml..." -ForegroundColor Cyan
scp -o StrictHostKeyChecking=no -i "$KeyPath" $tempFile "$Username@$InstanceIP`:~/vetrai-prod/docker-compose.yml"
Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
Write-Host "Docker compose configuration updated" -ForegroundColor Green

# 6️⃣ Create .env file on remote
Write-Host "Preparing deployment directory..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i "$KeyPath" "$Username@$InstanceIP" "mkdir -p ~/vetrai-prod && touch ~/vetrai-prod/.env"

# 7️⃣ Deploy on server with pre-built images
Write-Host "Stopping existing services..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i "$KeyPath" "$Username@$InstanceIP" "cd ~/vetrai-prod && docker-compose down 2>/dev/null || true"

Write-Host "Starting services with pre-built images..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i "$KeyPath" "$Username@$InstanceIP" "cd ~/vetrai-prod && docker-compose pull && docker-compose up -d"

Write-Host "Waiting 20 seconds for services to stabilize..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# 8️⃣ Check container status
Write-Host "Checking container status..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i "$KeyPath" "$Username@$InstanceIP" "cd ~/vetrai-prod && docker-compose ps"

# 9️⃣ Completion message
Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host " DEPLOYMENT COMPLETED SUCCESSFULLY " -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your VetRAI instance is running on Lightsail!" -ForegroundColor Green
Write-Host ""
Write-Host "Access your VetRAI instance:" -ForegroundColor Yellow
Write-Host "  Frontend:      http://$InstanceIP" -ForegroundColor Cyan
Write-Host "  API Docs:      http://$InstanceIP/api/docs" -ForegroundColor Cyan
Write-Host "  API ReDoc:     http://$InstanceIP/redoc" -ForegroundColor Cyan
Write-Host "  Health Check:  http://$InstanceIP/health_check" -ForegroundColor Cyan
Write-Host ""
Write-Host "Database credentials (remember to change in production!):" -ForegroundColor Yellow
Write-Host "  User:     vetrai" -ForegroundColor Gray
Write-Host "  Password: vetrai" -ForegroundColor Gray
Write-Host ""
Write-Host "Useful SSH commands:" -ForegroundColor Cyan
Write-Host "  View logs:     ssh -i `"$KeyPath`" $Username@$InstanceIP `"cd ~/vetrai-prod && docker-compose logs -f`"" -ForegroundColor Gray
Write-Host "  Check status:  ssh -i `"$KeyPath`" $Username@$InstanceIP `"cd ~/vetrai-prod && docker-compose ps`"" -ForegroundColor Gray
Write-Host "  Restart:       ssh -i `"$KeyPath`" $Username@$InstanceIP `"cd ~/vetrai-prod && docker-compose restart`"" -ForegroundColor Gray
Write-Host ""
