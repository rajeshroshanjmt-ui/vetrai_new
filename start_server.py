#!/usr/bin/env python3.12
"""Start VetRAI backend server."""
import subprocess
import sys

print("Python version:", sys.version)
print("Executable:", sys.executable)

# Run uvicorn
subprocess.run([
    sys.executable, "-m", "uvicorn",
    "--factory", "langflow.main:create_app",
    "--host", "0.0.0.0",
    "--port", "7860",
    "--reload"
], cwd="c:\\Users\\LENOVO\\Rajesh\\vetraiv1\\vetrai_new\\langflow-vetrai")
