#!/bin/bash
# Script to run VetRAI with Docker Compose

set -e

echo "=========================================="
echo "VetRAI - Full Application with Docker"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo "Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    echo "Please ensure Docker Desktop includes Docker Compose"
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed${NC}"
echo ""

# Parse command line arguments
COMMAND=${1:-up}

case $COMMAND in
    up)
        echo -e "${YELLOW}Building and starting services...${NC}"
        docker-compose up --build
        ;;
    down)
        echo -e "${YELLOW}Stopping services...${NC}"
        docker-compose down
        ;;
    logs)
        echo -e "${YELLOW}Showing logs...${NC}"
        docker-compose logs -f
        ;;
    restart)
        echo -e "${YELLOW}Restarting services...${NC}"
        docker-compose restart
        ;;
    clean)
        echo -e "${YELLOW}Removing all containers and volumes...${NC}"
        docker-compose down -v
        echo -e "${GREEN}✓ Clean complete${NC}"
        ;;
    *)
        echo "Usage: $0 {up|down|logs|restart|clean}"
        echo ""
        echo "Commands:"
        echo "  up       - Build and start all services (default)"
        echo "  down     - Stop all services"
        echo "  logs     - View live logs"
        echo "  restart  - Restart services"
        echo "  clean    - Remove all containers and volumes"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}=========================================="
echo "VetRAI Setup Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}Access VetRAI at: http://localhost:7860${NC}"
echo "Database: localhost:5432"
echo ""
