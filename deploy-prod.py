#!/usr/bin/env python3
"""
VetRAI Production Deployment Script
Handles building, pushing to Docker Hub, and running production stack
"""

import os
import sys
import subprocess
from pathlib import Path
from datetime import datetime

class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    RESET = '\033[0m'

def log_info(msg):
    print(f"{Colors.BLUE}[INFO]{Colors.RESET} {msg}")

def log_success(msg):
    print(f"{Colors.GREEN}[SUCCESS]{Colors.RESET} {msg}")

def log_warning(msg):
    print(f"{Colors.YELLOW}[WARNING]{Colors.RESET} {msg}")

def log_error(msg):
    print(f"{Colors.RED}[ERROR]{Colors.RESET} {msg}")

def run_command(cmd, description=""):
    """Execute shell command and return status"""
    if description:
        log_info(description)
    
    try:
        result = subprocess.run(cmd, shell=True, check=True, cwd=os.getcwd())
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"Command failed: {cmd}")
        return False

def main():
    """Main deployment workflow"""
    
    print(f"\n{Colors.BLUE}{'='*60}")
    print(f"VetRAI Production Deployment Script")
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*60}{Colors.RESET}\n")
    
    # Step 1: Check Docker status
    log_info("Checking Docker status...")
    if not run_command("docker --version"):
        log_error("Docker is not installed or not available")
        sys.exit(1)
    
    # Step 2: Build images
    log_info("Building Docker images...")
    print(f"{Colors.YELLOW}Enter image tag (default: latest):{Colors.RESET}")
    tag = input().strip() or "latest"
    
    # Backend image
    log_info(f"Building backend image: root2wings/vetrai:{tag}")
    if not run_command(f"docker build -t root2wings/vetrai:{tag} -f docker/fix.Dockerfile . --progress=plain"):
        log_error("Failed to build backend image")
        sys.exit(1)
    log_success(f"Backend image built: root2wings/vetrai:{tag}")
    
    # Frontend image
    log_info(f"Building frontend image: root2wings/vetrai-nginx:{tag}")
    if not run_command(f"docker build -t root2wings/vetrai-nginx:{tag} -f docker/frontend/build_and_push_frontend.Dockerfile . --progress=plain"):
        log_error("Failed to build frontend image")
        sys.exit(1)
    log_success(f"Frontend image built: root2wings/vetrai-nginx:{tag}")
    
    # Step 3: Docker Hub login
    log_info("Checking Docker Hub login...")
    if not run_command("docker login"):
        log_warning("Docker Hub login failed or skipped")
    else:
        log_success("Logged into Docker Hub")
    
    # Step 4: Push images
    log_info(f"Pushing backend image to Docker Hub: root2wings/vetrai:{tag}")
    if not run_command(f"docker push root2wings/vetrai:{tag}"):
        log_error("Failed to push backend image")
        sys.exit(1)
    log_success(f"Pushed: root2wings/vetrai:{tag}")
    
    log_info(f"Pushing frontend image to Docker Hub: root2wings/vetrai-nginx:{tag}")
    if not run_command(f"docker push root2wings/vetrai-nginx:{tag}"):
        log_error("Failed to push frontend image")
        sys.exit(1)
    log_success(f"Pushed: root2wings/vetrai-nginx:{tag}")
    
    # Step 5: Start production stack
    log_info("Starting production stack in vetrai_prod folder...")
    prod_dir = Path("vetrai_prod")
    
    if not prod_dir.exists():
        log_error("vetrai_prod folder not found")
        sys.exit(1)
    
    os.chdir(str(prod_dir))
    
    # Stop any existing services
    log_info("Stopping any existing services...")
    run_command("docker compose down", "")
    
    # Start services
    log_info("Starting production services...")
    if not run_command("docker compose up -d", ""):
        log_error("Failed to start production services")
        sys.exit(1)
    
    log_success("Production services started!")
    
    # Step 6: Verify services
    import time
    log_info("Waiting for services to be healthy (30 seconds)...")
    time.sleep(30)
    
    log_info("Checking service status...")
    run_command("docker compose ps", "")
    
    # Step 7: Test endpoints
    log_info("Testing API endpoints...")
    import urllib.request
    import json
    
    endpoints = [
        ("Health Check", "http://localhost/health_check"),
        ("API Version", "http://localhost/api/v1/version"),
    ]
    
    for endpoint_name, url in endpoints:
        try:
            response = urllib.request.urlopen(url, timeout=5)
            data = json.loads(response.read().decode())
            log_success(f"{endpoint_name}: {url} (200 OK)")
            print(f"  Response: {json.dumps(data, indent=2)}")
        except Exception as e:
            log_warning(f"{endpoint_name}: {url} (Error: {e})")
    
    print(f"\n{Colors.GREEN}{'='*60}")
    print(f"Deployment Complete!")
    print(f"{'='*60}")
    print(f"Frontend: http://localhost")
    print(f"API Docs: http://localhost/docs")
    print(f"Backend: http://localhost:7860 (internal)")
    print(f"{'='*60}{Colors.RESET}\n")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Deployment cancelled by user{Colors.RESET}")
        sys.exit(0)
    except Exception as e:
        log_error(f"Unexpected error: {e}")
        sys.exit(1)
