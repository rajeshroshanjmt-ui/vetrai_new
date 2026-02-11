#!/usr/bin/env python3.12
"""Test VetRAI app import."""
import sys
sys.path.insert(0, r'c:\Users\LENOVO\Rajesh\vetraiv1\vetrai_new\langflow-vetrai')

try:
    print("Attempting to import langflow.main...")
    from langflow.main import create_app
    print("✓ Successfully imported langflow.main.create_app")
    
    print("Creating app...")
    app = create_app()
    print(f"✓ App created successfully")
    print(f"  App type: {type(app)}")
    print(f"  App: {app}")
except Exception as e:
    print(f"✗ Error: {type(e).__name__}: {e}")
    import traceback  
    traceback.print_exc()
