"""Entry point for running the Vetrai Agentic MCP server.

This allows running the server with:
    python -m vetrai.agentic.mcp
"""

from vetrai.agentic.mcp.server import mcp

if __name__ == "__main__":
    mcp.run()
