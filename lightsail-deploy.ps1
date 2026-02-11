# VetRAI Lightsail Deployment Script for Windows PowerShell
# This script connects to a Lightsail instance and deploys VetRAI
# Usage: .\lightsail-deploy.ps1 -LightsailIP <IP> -KeyPath <path/to/key.pem> -Username ubuntu

param(
    [Parameter(Mandatory=$true)]
    [string]$LightsailIP,
    
    [Parameter(Mandatory=$true)]
    [string]$KeyPath,
    
    [Parameter(Mandatory=$false)]
    [string]$Username = "ubuntu",
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 22
)

# Colors (Windows-compatible)
$Info = "INFO"
$Success = "SUCCESS"
$Warning = "WARNING"
$Error = "ERROR"

function Write-Info {
    param([string]$Message)
    Write-Host "[$Info] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[$Success] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[$Warning] $Message" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "[$Error] $Message" -ForegroundColor Red
}

# Validate inputs
Write-Info "Validating inputs..."

if (-not (Test-Path $KeyPath)) {
    Write-ErrorMsg "SSH key not found: $KeyPath"
    exit 1
}

Write-Success "SSH key found: $KeyPath"

# Check if SSH is available
if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "SSH is not available. Please install OpenSSH for Windows or use WSL."
    exit 1
}

Write-Success "SSH command found"

# Prepare deployment script
$DeployScript = @'
#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}VetRAI Lightsail Deployment${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Update system
echo_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
echo_info "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm -f get-docker.sh

# Add user to docker group
echo_info "Configuring Docker permissions..."
sudo usermod -aG docker ubuntu

# Install Docker Compose
echo_info "Installing Docker Compose..."
sudo apt install -y docker-compose

# Create app directory
echo_info "Creating application directory..."
mkdir -p ~/vetrai-prod
cd ~/vetrai-prod

# Create docker-compose.yml
cat > docker-compose.yml << 'COMPOSE'
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
COMPOSE

# Start services
echo_info "Starting VetRAI services..."
docker compose pull
docker compose up -d

# Wait for services
echo_info "Waiting for services to be healthy..."
sleep 15

# Test endpoints
echo_info "Testing endpoints..."
docker compose ps

# Display access information
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}VetRAI is now running!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\nAccess at: http://${PUBLIC_IP}"
echo -e "API Docs: http://${PUBLIC_IP}/docs"
echo_success "Deployment complete!"
'@

# Display connection details
Write-Host "`n========================================" -ForegroundColor Blue
Write-Host "VetRAI Lightsail Deployment" -ForegroundColor Blue
Write-Host "========================================`n" -ForegroundColor Blue

Write-Info "Lightsail Instance: $LightsailIP"
Write-Info "SSH User: $Username"
Write-Info "SSH Key: $KeyPath"
Write-Info "SSH Port: $Port"

# Connect and deploy
Write-Info "Connecting to Lightsail instance..."
Write-Info "Running deployment script on remote server..."

# Transfer and execute deployment script using SSH
$DeployScript | ssh -i "$KeyPath" -o StrictHostKeyChecking=no -p $Port "${Username}@${LightsailIP}" "bash -s"

$DeploymentStatus = $LASTEXITCODE

if ($DeploymentStatus -eq 0) {
    Write-Success "Deployment completed successfully!"
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "Access Information" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
    Write-Host "Frontend:   http://$LightsailIP" -ForegroundColor Cyan
    Write-Host "API Docs:   http://$LightsailIP/docs" -ForegroundColor Cyan
    Write-Host "Health:     http://$LightsailIP/health_check" -ForegroundColor Cyan
    Write-Host "`nManagement:" -ForegroundColor Yellow
    Write-Host "SSH into instance: ssh -i '$KeyPath' $Username@$LightsailIP" -ForegroundColor Yellow
    Write-Host "View logs: docker compose logs -f" -ForegroundColor Yellow
    Write-Host "Stop services: docker compose down" -ForegroundColor Yellow
} else {
    Write-ErrorMsg "Deployment failed with exit code: $DeploymentStatus"
    exit 1
}
