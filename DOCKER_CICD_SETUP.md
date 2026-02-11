# Vetrai Docker & CI/CD Configuration

## Docker Hub Setup

### Repository Structure
Create the following repositories on Docker Hub under the `vetrai` organization:

| Repository | Description |
|------------|-------------|
| `vetrai/vetrai` | Main Vetrai image |
| `vetrai/vetrai-backend` | Backend-only image |
| `vetrai/vetrai-frontend` | Frontend-only image |
| `vetrai/vetrai-nightly` | Nightly build image |
| `vetrai/vetrai-all` | Full image with all dependencies |

### Quick Start
```bash
# Pull and run Vetrai
docker pull vetrai/vetrai:latest
docker run -p 7860:7860 vetrai/vetrai:latest

# With docker-compose
cd docker_example
docker-compose up -d
```

---

## GitHub Actions Secrets Required

Add these secrets in your GitHub repository settings (`Settings > Secrets and variables > Actions`):

| Secret Name | Description |
|-------------|-------------|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `GHCR_TOKEN` | GitHub Container Registry token (optional) |

---

## CI/CD Workflows Updated

The following workflows have been updated with Vetrai branding:

### Build & Release
- `docker-build.yml` - Main Docker build pipeline
- `docker-build-v2.yml` - V2 Docker build pipeline
- `docker-nightly-build.yml` - Nightly builds
- `release.yml` - Release pipeline
- `release_nightly.yml` - Nightly release
- `nightly_build.yml` - Nightly builds

### Testing
- `ci.yml` - Main CI pipeline
- `python_test.yml` - Python tests
- `typescript_test.yml` - TypeScript tests
- `docker_test.yml` - Docker tests
- `smoke-tests.yml` - Smoke tests

### Documentation
- `deploy-docs-draft.yml` - Docs deployment
- `docs-update-openapi.yml` - OpenAPI docs update

---

## Image Tags

### Production Tags
```
vetrai/vetrai:latest
vetrai/vetrai:1.8.0
vetrai/vetrai:base-latest
vetrai/vetrai:base-1.8.0
```

### Nightly Tags
```
vetrai/vetrai-nightly:latest
vetrai/vetrai-nightly:base-latest
```

### GitHub Container Registry
```
ghcr.io/vetrai/vetrai:latest
ghcr.io/vetrai/vetrai:1.8.0
```

---

## Environment Variables

The Docker images support these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `VETRAI_DATABASE_URL` | Database connection string | SQLite |
| `VETRAI_CONFIG_DIR` | Config/data directory | `/app/vetrai` |
| `VETRAI_AUTO_LOGIN` | Enable auto-login | `true` |
| `VETRAI_LOG_LEVEL` | Logging level | `INFO` |

---

## Building Locally

```bash
# Build the main image
docker build -t vetrai/vetrai:local .

# Build with docker-compose
docker-compose -f docker_example/docker-compose.yml build
```

---

Created: 2026-01-06
