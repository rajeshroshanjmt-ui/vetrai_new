#!/bin/bash
# VetRAI Production Deployment Script
# Usage: ./deploy.sh [start|stop|restart|logs|status]

set -e

COMMAND="${1:-start}"
COMPOSE_FILE="docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_status() {
    echo -e "${GREEN}[VetRAI]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

case "$COMMAND" in
    start)
        echo_status "Starting VetRAI production stack..."
        docker compose -f "$COMPOSE_FILE" up -d
        echo_status "✅ Services started"
        echo_status "Waiting for services to be healthy (30 seconds)..."
        sleep 30
        docker compose -f "$COMPOSE_FILE" ps
        echo_status "Access frontend at http://localhost"
        echo_status "API documentation at http://localhost/docs"
        ;;
    
    stop)
        echo_status "Stopping VetRAI production stack..."
        docker compose -f "$COMPOSE_FILE" down
        echo_status "✅ Services stopped"
        ;;
    
    restart)
        echo_status "Restarting VetRAI production stack..."
        docker compose -f "$COMPOSE_FILE" restart
        echo_status "✅ Services restarted"
        ;;
    
    logs)
        echo_status "Showing logs (press Ctrl+C to exit)..."
        docker compose -f "$COMPOSE_FILE" logs -f
        ;;
    
    status)
        echo_status "Service Status:"
        docker compose -f "$COMPOSE_FILE" ps
        ;;
    
    update)
        echo_status "Updating images from Docker Hub..."
        docker compose -f "$COMPOSE_FILE" pull
        echo_status "Restarting services with new images..."
        docker compose -f "$COMPOSE_FILE" up -d
        echo_status "✅ Update complete"
        ;;
    
    clean)
        echo_warning "This will remove all containers and data"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            docker compose -f "$COMPOSE_FILE" down -v
            echo_status "✅ All data removed"
        else
            echo_status "Cancelled"
        fi
        ;;
    
    *)
        echo_error "Unknown command: $COMMAND"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  start     - Start all services"
        echo "  stop      - Stop all services"
        echo "  restart   - Restart all services"
        echo "  logs      - Show live logs (Ctrl+C to exit)"
        echo "  status    - Show service status"
        echo "  update    - Pull latest images and restart"
        echo "  clean     - Remove all containers and data (WARNING)"
        exit 1
        ;;
esac
