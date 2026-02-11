# VetRAI Repository API - Offline Mode

A local, offline API service that serves VetRAI GitHub repository information without requiring internet connectivity.

## Overview

This service provides a FastAPI-based REST API that serves repository metadata from a local JSON file. No external API calls are made, making it ideal for:

- **Offline environments** - Works without internet
- **Rate limit avoidance** - No GitHub API rate limits
- **Performance** - Instant responses from local storage
- **Privacy** - No external data requests
- **Customization** - Easy to modify repository data

## Files

- **`repo_api.py`** - FastAPI application (main offline API service)
- **`repo_data.json`** - Local repository data storage
- **`repo_client.py`** - Python client example for consuming the API
- **`docker-compose.yml`** - Service definition (port 8001)

## API Endpoints

### Health Check
```
GET /health
```
Returns API status
```json
{"status": "healthy", "mode": "offline"}
```

### Repository Information
```
GET /repo
```
Returns basic repository information

### Statistics
```
GET /repo/stats
```
Returns repository statistics (stars, forks, issues, etc.)

### Basic Info
```
GET /repo/info
```
Returns repository name, owner, URL, and description

### Features
```
GET /repo/features
```
Returns list of VetRAI features

### Releases
```
GET /repo/releases
```
Returns version and release information

### Topics
```
GET /repo/topics
```
Returns repository topics/tags

### Full Metadata
```
GET /repo/metadata
```
Returns complete repository information

## Usage

### Option 1: Using Docker Compose

Add to your `docker-compose.yml` (already done):

```yaml
repo-api:
  image: python:3.11-slim
  container_name: vetrai_repo_api
  working_dir: /app
  command: pip install fastapi uvicorn && python -m uvicorn repo_api:app --host 0.0.0.0 --port 8001
  volumes:
    - .:/app
  ports:
    - "8001:8001"
  networks:
    - vetrai_network
```

Start the service:
```bash
docker compose up repo-api
```

### Option 2: Running Locally

```bash
# Install dependencies
pip install fastapi uvicorn

# Start the API
python -m uvicorn repo_api:app --host 0.0.0.0 --port 8001

# Or use the reload flag for development
python -m uvicorn repo_api:app --host 0.0.0.0 --port 8001 --reload
```

### Option 3: Using the Client

```bash
# Run the example client
python repo_client.py
```

## Example Requests

### Using curl

```bash
# Health check
curl http://localhost:8001/health

# Get repository info
curl http://localhost:8001/repo/info

# Get statistics
curl http://localhost:8001/repo/stats

# Get features
curl http://localhost:8001/repo/features
```

### Using Python

```python
import requests

# Get repository stats
response = requests.get("http://localhost:8001/repo/stats")
stats = response.json()
print(f"Stars: {stats['stars']}")
print(f"Forks: {stats['forks']}")

# Get features
response = requests.get("http://localhost:8001/repo/features")
features = response.json()
for feature in features['features']:
    print(f"- {feature}")
```

## Modifying Repository Data

Edit `repo_data.json` to update repository information:

```json
{
  "repo": "vetrai",
  "owner": "vetrai-ai",
  "url": "https://github.com/vetrai-ai/vetrai",
  "description": "Platform for building AI workflows",
  "stars": 2500,
  "forks": 450,
  ...
}
```

Changes will be reflected immediately in API responses.

## API Documentation

Auto-generated API documentation is available at:

- **Swagger UI**: `http://localhost:8001/docs`
- **ReDoc**: `http://localhost:8001/redoc`

## Service Details

| Property | Value |
|----------|-------|
| Container Name | vetrai_repo_api |
| Port | 8001 |
| Base URL | http://localhost:8001 |
| Mode | Offline (no external API calls) |
| Status Interval | 30 seconds |
| Restart Policy | Always |

## Integration

### With VetRAI Frontend

```javascript
// Fetch repository stats
fetch('http://localhost:8001/repo/stats')
  .then(r => r.json())
  .then(data => {
    document.getElementById('stars').textContent = data.stars;
    document.getElementById('forks').textContent = data.forks;
  });
```

### With VetRAI Backend

```python
import httpx

async def get_repo_stats():
    async with httpx.AsyncClient() as client:
        response = await client.get("http://repo-api:8001/repo/stats")
        return response.json()
```

## Advantages

✅ **No Internet Required** - Works completely offline  
✅ **Instant Responses** - No network latency  
✅ **No Rate Limiting** - Unlimited API calls  
✅ **Privacy Focused** - No external requests  
✅ **Easy to Customize** - Just edit JSON file  
✅ **Lightweight** - Minimal container size  

## Troubleshooting

### API not responding
```bash
# Check if service is running
docker compose ps repo-api

# View logs
docker compose logs repo-api

# Restart the service
docker compose restart repo-api
```

### Port already in use
Change the port in docker-compose.yml:
```yaml
ports:
  - "8002:8001"  # Map to 8002 instead
```

### Access from different host
Use the service name in Docker network:
```
http://repo-api:8001/repo/stats  # Inside Docker
http://localhost:8001/repo/stats  # From host machine
```

## Future Enhancements

- Add data sync with GitHub (scheduled updates)
- Support for multiple repositories
- Statistics dashboard
- Caching layer with Redis
- Database backend for data persistence

---

**Status**: Fully functional and ready to use! 🚀
