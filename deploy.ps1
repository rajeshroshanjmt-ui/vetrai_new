# Robust VetRAI Deployment to Lightsail
param(
    [string]$KeyPath = "C:\Users\LENOVO\Downloads\LightsailDefaultKey-us-east-1.pem",
    [string]$InstanceIP = "18.208.169.120",
    [string]$Username = "ubuntu"
)

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "VetRAI Lightsail Deployment" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Instance: $InstanceIP" -ForegroundColor Yellow
Write-Host "Key: $KeyPath" -ForegroundColor Yellow
Write-Host ""

# Verify SSH key exists
if (-not (Test-Path $KeyPath)) {
    Write-Host "ERROR: SSH key not found at $KeyPath" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] SSH key found" -ForegroundColor Green

# Function for SSH commands
function Run-RemoteCommand {
    param([string]$Command, [string]$Label)
    Write-Host "[*] $Label..." -ForegroundColor Cyan
    $result = ssh -i "$KeyPath" "$Username@$InstanceIP" $Command 2>&1
    if ($result) { Write-Host $result -ForegroundColor Gray }
    Start-Sleep -Seconds 1
}

# Step 1: Test connection
Write-Host "`n[STEP 1] Testing SSH Connection" -ForegroundColor Cyan
$testResult = ssh -i "$KeyPath" "$Username@$InstanceIP" "echo OK" 2>&1
if ($testResult) {
    Write-Host "[OK] SSH connection verified" -ForegroundColor Green
} else {
    Write-Host "[WARN] SSH connection test failed, but continuing..." -ForegroundColor Yellow
}

# Step 2: Install Docker
Write-Host "`n[STEP 2] Installing Docker and Docker Compose" -ForegroundColor Cyan
Run-RemoteCommand "sudo apt-get update" "Updating package list"
Run-RemoteCommand "sudo apt-get install -y docker.io docker-compose" "Installing Docker/Compose"
Write-Host "[OK] Docker ready" -ForegroundColor Green
Start-Sleep -Seconds 2

# Step 3: Create app directory
Write-Host "`n[STEP 3] Creating application directory" -ForegroundColor Cyan
Run-RemoteCommand "mkdir -p ~/vetrai-prod" "Creating directory"

# Step 4: Copy docker-compose.yml
Write-Host "`n[STEP 4] Deploying docker-compose configuration" -ForegroundColor Cyan

$dockerCompose = @'
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
'@

$tempFile = [System.IO.Path]::GetTempFileName() + ".yml"
$dockerCompose | Out-File -FilePath $tempFile -Encoding UTF8
Write-Host "[*] Copying docker-compose.yml to instance..." -ForegroundColor Gray
scp -i "$KeyPath" $tempFile "$Username@$InstanceIP`:~/vetrai-prod/docker-compose.yml" 2>&1 | Where-Object { $_ -notmatch "^\d+\s" } | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
Write-Host "[OK] docker-compose.yml deployed" -ForegroundColor Green
Start-Sleep -Seconds 2

# Step 5: Pull images
Write-Host "`n[STEP 5] Pulling Docker images" -ForegroundColor Cyan
Write-Host "[*] Downloading images from Docker Hub (may take 1-2 minutes)..." -ForegroundColor Gray
Run-RemoteCommand "cd ~/vetrai-prod && docker compose pull" "Pulling images"

# Step 6: Start services
Write-Host "`n[STEP 6] Starting services" -ForegroundColor Cyan
Run-RemoteCommand "cd ~/vetrai-prod && docker compose up -d" "Starting containers"
Start-Sleep -Seconds 3

# Step 7: Check status
Write-Host "`n[STEP 7] Checking service status" -ForegroundColor Cyan
Write-Host "[*] Waiting for services to stabilize (15 seconds)..." -ForegroundColor Gray
Start-Sleep -Seconds 15
Run-RemoteCommand "cd ~/vetrai-prod && docker compose ps" "Service status"

# Step 8: Verify endpoints
Write-Host "`n[STEP 8] Verifying endpoints" -ForegroundColor Cyan
Run-RemoteCommand "curl -s http://localhost/health_check" "Health check"

Write-Host "`n" + ("="*50) -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host ("="*50) -ForegroundColor Cyan
Write-Host ""
Write-Host "Your VetRAI instance is available at:" -ForegroundColor Yellow
Write-Host "  Frontend:      http://$InstanceIP" -ForegroundColor Cyan
Write-Host "  API Docs:      http://$InstanceIP/docs" -ForegroundColor Cyan
Write-Host "  Health Check:  http://$InstanceIP/health_check" -ForegroundColor Cyan
Write-Host ""
Write-Host "Database (change in production):" -ForegroundColor Yellow
Write-Host "  User:     vetrai" -ForegroundColor Gray
Write-Host "  Password: vetrai" -ForegroundColor Gray
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host ""
Write-Host "View logs:" -ForegroundColor Gray
Write-Host "  ssh -i `"$KeyPath`" $Username@$InstanceIP `"cd ~/vetrai-prod && docker compose logs -f`"" -ForegroundColor Gray
Write-Host ""
Write-Host "Check status:" -ForegroundColor Gray  
Write-Host "  ssh -i `"$KeyPath`" $Username@$InstanceIP `"cd ~/vetrai-prod && docker compose ps`"" -ForegroundColor Gray
Write-Host ""
Write-Host "Restart services:" -ForegroundColor Gray
Write-Host "  ssh -i `"$KeyPath`" $Username@$InstanceIP `"cd ~/vetrai-prod && docker compose restart`"" -ForegroundColor Gray
Write-Host ""
Write-Host "Success! VetRAI is now live!" -ForegroundColor Green
