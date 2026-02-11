# VetRAI - Full Application Setup Guide

This guide explains how to run the complete VetRAI application using Docker Compose.

## 📋 Prerequisites

- **Docker Desktop** - [Download here](https://www.docker.com/products/docker-desktop)
- At least 4GB RAM available for Docker
- 5GB free disk space

## 🚀 Quick Start (Recommended)

### Windows

```bash
# Navigate to the VetRAI directory
cd langflow-vetrai

# Run the application
.\run.bat

# Or use Docker Compose directly
docker-compose up --build
```

### macOS / Linux

```bash
# Navigate to the VetRAI directory
cd langflow-vetrai

# Make script executable
chmod +x run.sh

# Run the application
./run.sh

# Or use Docker Compose directly
docker-compose up --build
```

## 📊 Architecture

The setup includes two main services:

### 1. **PostgreSQL Database** (Port 5432)
- Image: `postgres:16-alpine`
- User: `vetrai`
- Password: `vetrai`
- Database: `vetrai`
- Data persists in `vetrai_postgres_data` volume

### 2. **VetRAI Application** (Port 7860)
- Builds from the `Dockerfile`
- Runs Python backend + React frontend
- Depends on PostgreSQL service
- Configuration stored in `vetrai_config_data` volume

## 🎯 Accessing the Application

Once the services are running:

- **VetRAI UI**: http://localhost:7860
- **PostgreSQL**: localhost:5432

## 📝 Available Commands

### Using `run.bat` (Windows)

```bash
run.bat up          # Build and start (default)
run.bat down        # Stop all services
run.bat logs        # View live logs
run.bat restart     # Restart services
run.bat clean       # Remove all containers and volumes
```

### Using `run.sh` (macOS/Linux)

```bash
./run.sh up         # Build and start (default)
./run.sh down       # Stop all services
./run.sh logs       # View live logs
./run.sh restart    # Restart services
./run.sh clean      # Remove all containers and volumes
```

### Using `docker-compose` directly

```bash
# Start services
docker-compose up --build

# Start in background
docker-compose up -d --build

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# View logs for specific service
docker-compose logs -f vetrai
docker-compose logs -f postgres

# Restart services
docker-compose restart

# Remove everything including volumes
docker-compose down -v
```

## 🔧 Configuration

Edit the `.env` file to customize settings:

```env
# Database credentials
POSTGRES_USER=vetrai
POSTGRES_PASSWORD=vetrai
POSTGRES_DB=vetrai

# VetRAI server settings
VETRAI_HOST=0.0.0.0
VETRAI_PORT=7860

# API Keys (add yours here)
# OPENAI_API_KEY=sk-...
# LANGCHAIN_API_KEY=ls-...
```

## 📊 Service Health

The setup includes health checks:

- **PostgreSQL**: Checks database connectivity every 10 seconds
- **VetRAI**: Checks HTTP endpoint every 30 seconds

View service status:

```bash
docker-compose ps

# Example output:
# NAME             SERVICE    STATUS            PORTS
# vetrai_postgres  postgres   Up 2 minutes      5432/tcp
# vetrai_app       vetrai     Up 1 minute       7860/tcp
```

## 📁 Volumes (Persistent Data)

- **`vetrai_postgres_data`**: PostgreSQL database files
- **`vetrai_config_data`**: VetRAI configuration and workflows

Data persists even after stopping containers.

## 🔄 Troubleshooting

### Port Already in Use

If port 7860 or 5432 is already in use:

```bash
# Find process using port (Windows)
netstat -ano | findstr :7860

# Kill the process
taskkill /PID <PID> /F

# OR edit docker-compose.yml and change port mappings:
ports:
  - "7861:7860"    # New: 7861, Container: 7860
```

### Container Won't Start

```bash
# Check logs
docker-compose logs vetrai

# Rebuild without cache
docker-compose build --no-cache

# Full cleanup and restart
docker-compose down -v
docker-compose up --build
```

### Database Connection Issues

```bash
# Check PostgreSQL logs
docker-compose logs postgres

# Verify database is healthy
docker-compose ps postgres

# Reset database
docker-compose down -v
docker-compose up --build
```

### Out of Memory

Increase Docker Desktop memory:
1. Open Docker Desktop Settings
2. Go to Resources → Advanced
3. Increase Memory to 4GB or more
4. Apply & Restart

## 🔐 Security Notes

⚠️ **For Development Only**

The current setup uses default credentials:
- PostgreSQL user: `vetrai`
- PostgreSQL password: `vetrai`

**For Production:**
1. Change all credentials in `.env`
2. Use environment-specific `.env` files
3. Enable network isolation
4. Set up proper backup strategy
5. Use Docker secrets management

## 📦 Development Workflows

### Rebuild After Code Changes

```bash
# Full rebuild
docker-compose build --no-cache

# Then restart
docker-compose up
```

### View Real-time Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f vetrai

# Last 50 lines
docker-compose logs --tail 50 vetrai
```

### Run Commands in Container

```bash
# Access Python shell in VetRAI container
docker-compose exec vetrai python

# Run a command
docker-compose exec vetrai python -m vetrai --version

# Access PostgreSQL
docker-compose exec postgres psql -U vetrai -d vetrai
```

## 📚 Additional Resources

- [VetRAI Documentation](https://docs.vetrai.org)
- [Docker Documentation](https://docs.docker.com)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file)
- [PostgreSQL Documentation](https://www.postgresql.org/docs)

## 🆘 Support

For issues:
1. Check logs: `docker-compose logs -f`
2. Verify Docker installation: `docker --version`
3. Ensure ports are available: `netstat -an | grep 7860`
4. Read VetRAI documentation at https://docs.vetrai.org
5. Check GitHub issues: https://github.com/vetrai/vetrai/issues

## ✅ Next Steps

After the application starts:

1. **Access VetRAI**: Open http://localhost:7860 in your browser
2. **Create Your First Workflow**: Use the visual builder to create AI agents
3. **Explore Examples**: Check the included example workflows
4. **Configure APIs**: Add LLM keys (OpenAI, etc.) in settings
5. **Build Agents**: Create AI-powered workflows and agents

---

**Last Updated**: 2026-02-06  
**Version**: VetRAI 1.8.0 with Docker Compose
