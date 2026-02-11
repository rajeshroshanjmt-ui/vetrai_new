#!/usr/bin/env python3
"""
Example client for VetRAI Repository API (Offline Mode)
Shows how to use the local API endpoints
"""

import requests
import json
from typing import Dict, Any

# API Base URL
API_BASE_URL = "http://localhost:8001"

class VetRAIRepoClient:
    """Client for VetRAI Repository API"""
    
    def __init__(self, base_url: str = API_BASE_URL):
        self.base_url = base_url
    
    def health_check(self) -> Dict[str, Any]:
        """Check API health status"""
        response = requests.get(f"{self.base_url}/health")
        return response.json()
    
    def get_repo_info(self) -> Dict[str, Any]:
        """Get basic repository information"""
        response = requests.get(f"{self.base_url}/repo/info")
        return response.json()
    
    def get_repo_stats(self) -> Dict[str, Any]:
        """Get repository statistics"""
        response = requests.get(f"{self.base_url}/repo/stats")
        return response.json()
    
    def get_features(self) -> Dict[str, Any]:
        """Get VetRAI features list"""
        response = requests.get(f"{self.base_url}/repo/features")
        return response.json()
    
    def get_releases(self) -> Dict[str, Any]:
        """Get release information"""
        response = requests.get(f"{self.base_url}/repo/releases")
        return response.json()
    
    def get_topics(self) -> Dict[str, Any]:
        """Get repository topics"""
        response = requests.get(f"{self.base_url}/repo/topics")
        return response.json()
    
    def get_full_metadata(self) -> Dict[str, Any]:
        """Get complete repository metadata"""
        response = requests.get(f"{self.base_url}/repo/metadata")
        return response.json()

# Example usage
if __name__ == "__main__":
    client = VetRAIRepoClient()
    
    print("\n" + "="*60)
    print("VetRAI Repository API - Offline Mode")
    print("="*60)
    
    # Health check
    print("\n✓ Health Status:")
    health = client.health_check()
    print(json.dumps(health, indent=2))
    
    # Repository info
    print("\n✓ Repository Info:")
    info = client.get_repo_info()
    print(json.dumps(info, indent=2))
    
    # Statistics
    print("\n✓ Repository Statistics:")
    stats = client.get_repo_stats()
    print(json.dumps(stats, indent=2))
    
    # Features
    print("\n✓ VetRAI Features:")
    features = client.get_features()
    print(json.dumps(features, indent=2))
    
    # Releases
    print("\n✓ Release Information:")
    releases = client.get_releases()
    print(json.dumps(releases, indent=2))
    
    # Topics
    print("\n✓ Topics/Tags:")
    topics = client.get_topics()
    print(json.dumps(topics, indent=2))
    
    print("\n" + "="*60)
