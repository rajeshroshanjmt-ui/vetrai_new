#!/bin/bash
# VetRAI Lightsail Deployment Script
# Run this on a fresh Ubuntu 22.04 Lightsail instance
# Usage: chmod +x lightsail-deploy.sh && ./lightsail-deploy.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root (not required but helpful for some operations)
if [ "$EUID" -eq 0 ]; then
    echo_warning "Running as root. This is OK but not necessary."
fi

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}VetRAI Lightsail Deployment Script${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Step 1: Update system
echo_info "Step 1: Updating system packages..."
sudo apt update
sudo apt upgrade -y
echo_success "System updated"

# Step 2: Install Docker
echo_info "Step 2: Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm -f get-docker.sh
echo_success "Docker installed"

# Step 3: Add user to docker group
echo_info "Step 3: Configuring Docker permissions..."
sudo usermod -aG docker ubuntu || sudo usermod -aG docker $(whoami)
echo_success "User added to docker group (may need to log out and back in)"

# Step 4: Install Docker Compose
echo_info "Step 4: Installing Docker Compose..."
sudo apt install -y docker-compose
echo_success "Docker Compose installed"

# Step 5: Verify installations
echo_info "Step 5: Verifying installations..."
docker --version
docker compose version
echo_success "Installations verified"

# Step 6: Create application directory
echo_info "Step 6: Creating application directory..."
mkdir -p ~/vetrai-prod
cd ~/vetrai-prod
echo_success "Directory created: $(pwd)"

# Step 7: Download docker-compose.yml
echo_info "Step 7: Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # PostgreSQL Database
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

  # VetRAI Backend
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

  # Nginx Frontend
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
echo_success "docker-compose.yml created"

# Step 8: Start services
echo_info "Step 8: Starting VetRAI services (this may take 1-2 minutes)..."
docker compose pull
docker compose up -d
echo_success "Services started"

# Step 9: Wait for services to be healthy
echo_info "Step 9: Waiting for services to be healthy..."
sleep 10
echo_info "Checking service status..."
docker compose ps

# Step 10: Verify deployment
echo_info "Step 10: Verifying deployment..."
sleep 10

echo_info "Testing health endpoint..."
if curl -f -s http://localhost/health_check > /dev/null; then
    echo_success "✅ Health check endpoint is responding"
else
    echo_warning "⚠️  Health check disabled (may still be starting)"
fi

echo_info "Testing API version endpoint..."
if curl -f -s http://localhost/api/v1/version > /dev/null; then
    echo_success "✅ API endpoint is responding"
else
    echo_warning "⚠️  API endpoint not ready yet"
fi

# Step 11: Display access information
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"

# Get the public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo -e "\n${BLUE}Access Information:${NC}"
echo -e "  Frontend:    ${GREEN}http://${PUBLIC_IP}${NC}"
echo -e "  API Docs:    ${GREEN}http://${PUBLIC_IP}/docs${NC}"
echo -e "  ReDoc:       ${GREEN}http://${PUBLIC_IP}/redoc${NC}"
echo -e "  Health:      ${GREEN}http://${PUBLIC_IP}/health_check${NC}"

echo -e "\n${BLUE}Management Commands:${NC}"
echo -e "  View logs:     ${YELLOW}docker compose logs -f${NC}"
echo -e "  Status:        ${YELLOW}docker compose ps${NC}"
echo -e "  Stop:          ${YELLOW}docker compose down${NC}"
echo -e "  Restart:       ${YELLOW}docker compose restart${NC}"
echo -e "  Update images: ${YELLOW}docker compose pull && docker compose up -d${NC}"

echo -e "\n${BLUE}Next Steps:${NC}"
echo -e "  1. Open browser to: ${GREEN}http://${PUBLIC_IP}${NC}"
echo -e "  2. Test the API at: ${GREEN}http://${PUBLIC_IP}/docs${NC}"
echo -e "  3. (Optional) Configure domain name in Lightsail"
echo -e "  4. (Optional) Set up SSL certificate with Let's Encrypt"
echo -e "  5. Configure Lightsail firewall to allow HTTP (80) and HTTPS (443)"

echo -e "\n${YELLOW}Important:${NC}"
echo -e "  - Database credentials: vetrai / vetrai"
echo -e "  - Change passwords in production!"
echo -e "  - Configure domain and SSL for production use"
echo -e "  - Set up automated backups (Lightsail snapshots)"

echo -e "\n${BLUE}logs in 30 seconds (Ctrl+C to skip):${NC}"
sleep 5
echo -e "\n${BLUE}Service Logs:${NC}"
docker compose logs --tail=20

echo_success "VetRAI is now running on your Lightsail instance!"
