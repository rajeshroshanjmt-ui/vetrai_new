"""
Offline GitHub Repository API
Serves local repository data without requiring internet connection
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import json
from pathlib import Path
from typing import List, Dict, Any
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="VetRAI Repository API (Offline)",
    description="Local API for VetRAI GitHub repository information",
    version="1.0.0"
)

# Load repository data
REPO_DATA_FILE = Path(__file__).parent / "repo_data.json"

def load_repo_data() -> Dict[str, Any]:
    """Load repository data from JSON file"""
    try:
        with open(REPO_DATA_FILE, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        logger.error(f"Repository data file not found: {REPO_DATA_FILE}")
        raise HTTPException(status_code=404, detail="Repository data not found")
    except json.JSONDecodeError:
        logger.error(f"Invalid JSON in repository data file: {REPO_DATA_FILE}")
        raise HTTPException(status_code=500, detail="Invalid repository data")

# Pydantic models
class RepoStats(BaseModel):
    stars: int
    forks: int
    watchers: int
    open_issues: int
    open_pull_requests: int

class RepoInfo(BaseModel):
    repo: str
    owner: str
    url: str
    description: str
    language: str
    license: str
    stats: RepoStats

class FullRepoData(BaseModel):
    repo: str
    owner: str
    url: str
    description: str
    stars: int
    forks: int
    language: str
    license: str

# Routes

@app.get("/")
async def root():
    """API health check and info"""
    return {
        "name": "VetRAI Repository API (Offline Mode)",
        "status": "online",
        "version": "1.0.0",
        "mode": "offline",
        "endpoints": {
            "/repo": "Full repository information",
            "/repo/stats": "Repository statistics only",
            "/repo/info": "Basic repository info",
            "/repo/features": "VetRAI features list",
            "/health": "Health check"
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "mode": "offline"}

@app.get("/repo", response_model=FullRepoData)
async def get_repo():
    """Get full repository information"""
    data = load_repo_data()
    return FullRepoData(
        repo=data["repo"],
        owner=data["owner"],
        url=data["url"],
        description=data["description"],
        stars=data["stars"],
        forks=data["forks"],
        language=data["language"],
        license=data["license"]
    )

@app.get("/repo/stats")
async def get_repo_stats():
    """Get repository statistics"""
    data = load_repo_data()
    return {
        "stars": data["stars"],
        "forks": data["forks"],
        "watchers": data["watchers"],
        "open_issues": data["open_issues"],
        "open_pull_requests": data["open_pull_requests"],
        "contributors": data["stats"]["contributors"],
        "total_commits": data["stats"]["total_commits"]
    }

@app.get("/repo/info")
async def get_repo_info():
    """Get basic repository information"""
    data = load_repo_data()
    return {
        "name": data["repo"],
        "owner": data["owner"],
        "url": data["url"],
        "description": data["description"],
        "last_synced": data["stats"]["last_synced"]
    }

@app.get("/repo/features")
async def get_repo_features():
    """Get VetRAI features"""
    data = load_repo_data()
    return {
        "features": data["features"],
        "total_features": len(data["features"])
    }

@app.get("/repo/releases")
async def get_repo_releases():
    """Get release information"""
    data = load_repo_data()
    return {
        "latest": data["releases"]["latest"],
        "latest_release_date": data["releases"]["latest_release_date"],
        "total_releases": data["releases"]["total_releases"]
    }

@app.get("/repo/topics")
async def get_repo_topics():
    """Get repository topics/tags"""
    data = load_repo_data()
    return {
        "topics": data["topics"]
    }

@app.get("/repo/metadata")
async def get_repo_metadata():
    """Get full repository metadata"""
    data = load_repo_data()
    return data

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return {
        "error": exc.detail,
        "status_code": exc.status_code,
        "mode": "offline"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
