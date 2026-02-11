#!/usr/bin/env python3
"""Single-port deployment - run from langflow-vetrai directory"""
import sys
sys.path.insert(0, './src/backend/base')
sys.path.insert(0, './src/lfx/src')

if __name__ == "__main__":
    import uvicorn
    from vetrai.main import setup_app
    from pathlib import Path
    
    frontend_dir = Path("src/backend/base/vetrai/frontend")
    print(f"Starting VetRAI on port 7680...")
    print(f"Frontend: {frontend_dir.resolve()}")
    
    app = setup_app(static_files_dir=frontend_dir, backend_only=False)
    uvicorn.run(app, host="0.0.0.0", port=7680, workers=1, log_level="info")
