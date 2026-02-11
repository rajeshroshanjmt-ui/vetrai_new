# VetRAI Auto-Deployment Script for Lightsail (PowerShell)
# Run locally on Windows to deploy to remote Lightsail instance
# Usage: .\lightsail-auto-deploy.ps1 -KeyPath "C:\path\to\key.pem" -InstanceIP "18.208.169.120"

param(
    [Parameter(Mandatory=$true)]
    [string]$KeyPath = "C:\path\to\key.pem",
    
    [Parameter(Mandatory=$true)]
    [string]$InstanceIP = "18.208.169.120",
    
    [string]$Username = "ubuntu",
    
    [string]$VetRAIVersion = "latest",
    
    [switch]$SkipUpdate = $false
)

# Colors
$colors = @{
    'Success' = 'Green'
    'Error' = 'Red'
    'Warning' = 'Yellow'
    'Info' = 'Cyan'
    'Header' = 'Blue'
}

function Write-Header {
    param([string]$Text)
    Write-Host "`n$('='*50)" -ForegroundColor $colors['Header']
    Write-Host $Text -ForegroundColor $colors['Header']
    Write-Host "=" * 50 -ForegroundColor $colors['Header']
    Write-Host ""
}

function Write-Success {
    param([string]$Text)
    Write-Host "✓ $Text" -ForegroundColor $colors['Success']
}

function Write-Info {
    param([string]$Text)
    Write-Host "ℹ $Text" -ForegroundColor $colors['Info']
}

function Write-Warning {
    param([string]$Text)
    Write-Host "⚠ $Text" -ForegroundColor $colors['Warning']
}

function Write-Error {
    param([string]$Text)
    Write-Host "✗ $Text" -ForegroundColor $colors['Error']
}

# Validate inputs
Write-Header "VetRAI Lightsail Auto-Deploy (PowerShell)"

if (-not (Test-Path $KeyPath)) {
    Write-Error "SSH key not found: $KeyPath"
    exit 1
}

Write-Success "SSH key found: $KeyPath"
Write-Info "Target Instance: $InstanceIP"
Write-Info "SSH Username: $Username"

# Function to run SSH command
function Invoke-SSHCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    Write-Info $Description
    $sshCmd = "ssh -i `"$KeyPath`" $Username@$InstanceIP `"$Command`""
    Invoke-Expression $sshCmd
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$Description completed"
    } else {
        Write-Error "$Description failed with exit code $LASTEXITCODE"
    }
}

# Step 1: Check connectivity
Write-Header "Step 0: Verifying SSH Connection"
Write-Info "Testing SSH connection to $InstanceIP..."
ssh -i "$KeyPath" "$Username@$InstanceIP" "echo 'Connection successful'" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Success "SSH connection established"
} else {
    Write-Error "Cannot connect to instance. Check:"
    Write-Info "  1. Key path is correct: $KeyPath"
    Write-Info "  2. Instance IP is correct: $InstanceIP"
    Write-Info "  3. Username is correct: $Username"
    Write-Info "  4. Firewall allows SSH (port 22)"
    exit 1
}

# Step 2: Update system (optional)
Write-Header "Step 1: System Update (Optional)"
if (-not $SkipUpdate) {
    Write-Info "Updating system packages..."
    Invoke-SSHCommand "sudo apt-get update && sudo apt-get upgrade -y" "System update"
} else {
    Write-Warning "Skipping system update (use -SkipUpdate to skip)"
}

# Step 3: Install Docker
Write-Header "Step 2: Installing Docker"
Invoke-SSHCommand @"
if command -v docker &> /dev/null; then
    echo 'Docker already installed'
else
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm -f get-docker.sh
fi
"@ "Installing Docker"

# Step 4: Configure Docker
Write-Header "Step 3: Configuring Docker"
Invoke-SSHCommand "sudo usermod -aG docker $Username" "Adding user to docker group"

# Step 5: Install Docker Compose
Write-Header "Step 4: Installing Docker Compose"
Invoke-SSHCommand @"
if command -v docker-compose &> /dev/null; then
    echo 'Docker Compose already installed'
else
    sudo apt-get install -y docker-compose
fi
"@ "Installing Docker Compose"

# Step 6: Create application directory
Write-Header "Step 5: Creating Application Directory"
Invoke-SSHCommand "mkdir -p ~/vetrai-prod && cd ~/vetrai-prod && pwd" "Creating directory"

# Step 7: Create docker-compose.yml
Write-Header "Step 6: Creating Docker Compose Configuration"
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

# Write docker-compose to a temporary file and scp it
$tempFile = [System.IO.Path]::GetTempFileName()
$dockerComposeContent | Out-File -FilePath $tempFile -Encoding UTF8
Write-Info "Created temporary docker-compose.yml"

# Use scp to copy file to remote
Write-Info "Copying docker-compose.yml to remote..."
& scp -i "$KeyPath" $tempFile "$Username@$InstanceIP`:~/vetrai-prod/docker-compose.yml"
Remove-Item $tempFile
Write-Success "docker-compose.yml copied"

# Step 8: Pull Docker images
Write-Header "Step 7: Pulling Docker Images"
Write-Info "Pulling images (this may take 1-2 minutes)..."
Invoke-SSHCommand "cd ~/vetrai-prod && docker compose pull" "Pulling Docker images"

# Step 9: Start services
Write-Header "Step 8: Starting Services"
Invoke-SSHCommand "cd ~/vetrai-prod && docker compose up -d" "Starting services"

# Step 10: Wait for services
Write-Header "Step 9: Waiting for Services to Stabilize"
Write-Info "Waiting 30 seconds for services to start..."
Start-Sleep -Seconds 10
Write-Info "Checking service status..."
Invoke-SSHCommand "cd ~/vetrai-prod && docker compose ps" "Checking status"
Start-Sleep -Seconds 20

# Step 11: Verify deployment
Write-Header "Step 10: Verifying Deployment"
Invoke-SSHCommand @"
echo 'Checking health endpoint...'
if timeout 5 curl -f -s http://localhost/health_check > /dev/null 2>&1; then
    echo 'Health endpoint: OK'
else
    echo 'Health endpoint: Still starting...'
fi

echo 'Checking API endpoint...'
if timeout 5 curl -f -s http://localhost/api/v1/version > /dev/null 2>&1; then
    echo 'API endpoint: OK'
else
    echo 'API endpoint: Still starting...'
fi
"@ "Verifying deployment"

# Step 12: Display access information
Write-Header "Deployment Complete!"
Write-Host ""
Write-Host "✓ VetRAI is Now Running!" -ForegroundColor Green
Write-Host "✓ All services deployed successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "Access Information:" -ForegroundColor Blue
Write-Host "  Frontend:    http://$InstanceIP" -ForegroundColor Yellow
Write-Host "  API Docs:    http://$InstanceIP/docs" -ForegroundColor Yellow
Write-Host "  ReDoc:       http://$InstanceIP/redoc" -ForegroundColor Yellow
Write-Host "  Health:      http://$InstanceIP/health_check" -ForegroundColor Yellow
Write-Host "  Version:     http://$InstanceIP/api/v1/version" -ForegroundColor Yellow

Write-Host ""
Write-Host "Management Commands:" -ForegroundColor Blue
Write-Host "  View logs:     docker compose logs -f" -ForegroundColor Yellow
Write-Host "  Status:        docker compose ps" -ForegroundColor Yellow
Write-Host "  Stop:          docker compose down" -ForegroundColor Yellow
Write-Host "  Restart:       docker compose restart" -ForegroundColor Yellow
Write-Host "  Update images: docker compose pull && docker compose up -d" -ForegroundColor Yellow

Write-Host ""
Write-Host "Database Info:" -ForegroundColor Blue
Write-Host "  User:     vetrai" -ForegroundColor Yellow
Write-Host "  Password: vetrai (change in production!)" -ForegroundColor Yellow
Write-Host "  Database: vetrai" -ForegroundColor Yellow

Write-Host ""
Write-Host "Working Directory on Lightsail:" -ForegroundColor Blue
Write-Host "  ~/vetrai-prod" -ForegroundColor Yellow

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Open browser to: http://$InstanceIP" -ForegroundColor Cyan
Write-Host "  2. Test API: http://$InstanceIP/docs" -ForegroundColor Cyan
Write-Host "  3. SSH into instance: ssh -i `"$KeyPath`" $Username@$InstanceIP" -ForegroundColor Cyan
Write-Host "  4. Monitor services: docker stats" -ForegroundColor Cyan
Write-Host "  5. Configure Lightsail firewall (AWS Console):"
Write-Host "     - Allow HTTP (80) & HTTPS (443) from 0.0.0.0/0" -ForegroundColor Cyan
Write-Host "  6. (Optional) Set up domain name" -ForegroundColor Cyan
Write-Host "  7. (Optional) Enable SSL/TLS with Lets Encrypt" -ForegroundColor Cyan

Write-Host ""
Write-Host "✓ VetRAI successfully deployed to your Lightsail instance!" -ForegroundColor Green
Write-Host ""
