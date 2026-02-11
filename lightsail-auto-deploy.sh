#!/bin/bash
# VetRAI Auto-Deployment for Lightsail
# This script automates the entire deployment process
# Run on your Lightsail instance: bash <(curl -fsSL https://raw.githubusercontent.com/your-repo/lightsail-auto-deploy.sh)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_step() {
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}\n"
}

echo_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

echo_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

echo_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Main deployment
echo_step "VetRAI Lightsail Deployment"

# Step 1: Check OS
echo_info "Verifying Ubuntu system..."
if ! grep -q "ubuntu" /etc/*-release; then
    echo_error "This script is designed for Ubuntu only"
    exit 1
fi
echo_success "Ubuntu detected"

# Step 2: Update system
echo_step "Step 1: Updating System"
sudo apt-get update
sudo apt-get upgrade -y
echo_success "System updated"

# Step 3: Install Docker
echo_step "Step 2: Installing Docker"
if command -v docker &> /dev/null; then
    echo_success "Docker already installed: $(docker --version)"
else
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm -f get-docker.sh
    echo_success "Docker installed"
fi

# Step 4: Configure Docker
echo_step "Step 3: Configuring Docker"
sudo usermod -aG docker ubuntu
echo_success "Ubuntu user added to docker group"

# Step 5: Install Docker Compose
echo_step "Step 4: Installing Docker Compose"
if command -v docker-compose &> /dev/null; then
    echo_success "Docker Compose already installed: $(docker-compose --version)"
else
    sudo apt-get install -y docker-compose
    echo_success "Docker Compose installed"
fi

# Step 6: Create application directory
echo_step "Step 5: Creating Application Directory"
mkdir -p ~/vetrai-prod
cd ~/vetrai-prod
echo_success "Directory created: $(pwd)"

# Step 7: Create docker-compose.yml
echo_step "Step 6: Creating Docker Compose Configuration"
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
echo_success "Docker Compose configuration created"

# Step 8: Pull Docker images
echo_step "Step 7: Pulling Docker Images"
echo_info "This may take 1-2 minutes..."
docker compose pull
echo_success "Docker images pulled"

# Step 9: Start services
echo_step "Step 8: Starting Services"
docker compose up -d
echo_success "Services started"

# Step 10: Wait for services to be healthy
echo_step "Step 9: Waiting for Services to Be Healthy"
echo_info "Waiting 30 seconds for services to stabilize..."
sleep 10
echo_info "Checking service status..."
docker compose ps
sleep 20

# Step 11: Verify deployment
echo_step "Step 10: Verifying Deployment"

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo_info "Testing health endpoint..."
if timeout 5 curl -f -s http://localhost/health_check > /dev/null 2>&1; then
    echo_success "Health check endpoint responding ✓"
else
    echo_warning "Health endpoint not ready yet (still starting)"
fi

echo_info "Testing API endpoint..."
if timeout 5 curl -f -s http://localhost/api/v1/version > /dev/null 2>&1; then
    echo_success "API endpoint responding ✓"
else
    echo_warning "API endpoint not ready yet (still starting)"
fi

# Step 12: Display access information
echo_step "Deployment Complete!"

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  VetRAI is Now Running!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}\n"

echo -e "${BLUE}Access Information:${NC}"
echo -e "  Frontend:    ${YELLOW}http://${PUBLIC_IP}${NC}"
echo -e "  API Docs:    ${YELLOW}http://${PUBLIC_IP}/docs${NC}"
echo -e "  ReDoc:       ${YELLOW}http://${PUBLIC_IP}/redoc${NC}"
echo -e "  Health:      ${YELLOW}http://${PUBLIC_IP}/health_check${NC}"
echo -e "  Version:     ${YELLOW}http://${PUBLIC_IP}/api/v1/version${NC}"

echo -e "\n${BLUE}Management Commands:${NC}"
echo -e "  View logs:     ${YELLOW}docker compose logs -f${NC}"
echo -e "  Status:        ${YELLOW}docker compose ps${NC}"
echo -e "  Stop:          ${YELLOW}docker compose down${NC}"
echo -e "  Restart:       ${YELLOW}docker compose restart${NC}"
echo -e "  Update images: ${YELLOW}docker compose pull && docker compose up -d${NC}"

echo -e "\n${BLUE}Database Info:${NC}"
echo -e "  User:     ${YELLOW}vetrai${NC}"
echo -e "  Password: ${YELLOW}vetrai${NC} (change in production!)"
echo -e "  Database: ${YELLOW}vetrai${NC}"

echo -e "\n${BLUE}Working Directory:${NC}"
echo -e "  ${YELLOW}~/vetrai-prod${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "  1. Open browser to: ${BLUE}http://${PUBLIC_IP}${NC}"
echo -e "  2. Test API: ${BLUE}http://${PUBLIC_IP}/docs${NC}"
echo -e "  3. Create database backups: ${BLUE}docker compose exec -T postgres pg_dump -U vetrai vetrai > backup.sql${NC}"
echo -e "  4. Monitor services: ${BLUE}docker stats${NC}"
echo -e "  5. Configure Lightsail firewall (AWS Console):"
echo -e "     - Allow HTTP (80) & HTTPS (443) from 0.0.0.0/0"
echo -e "  6. (Optional) Set up domain name"
echo -e "  7. (Optional) Enable SSL/TLS with Let's Encrypt"

echo -e "\n${GREEN}✓ VetRAI successfully deployed to your Lightsail instance!${NC}\n"
