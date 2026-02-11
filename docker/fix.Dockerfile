# VetRAI Dockerfile - Bypasses workspace shadowing issue
FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim
ENV TZ=UTC

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    libpq5 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY . /app

# Install all dependencies from pyproject.toml files
# Install lfx dependencies first
RUN uv pip install --system --no-cache-dir \
    'langchain-core>=0.3.81,<1.0.0' \
    'pandas>=2.0.0,<3.0.0' \
    'pydantic>=2.0.0,<3.0.0' \
    'pillow>=10.0.0,<13.0.0' \
    'fastapi>=0.115.13,<1.0.0' \
    'uvicorn>=0.34.3,<1.0.0' \
    'typer>=0.16.0,<1.0.0' \
    'platformdirs>=4.3.8,<5.0.0' \
    'aiofiles>=24.1.0,<25.0.0' \
    'typing-extensions>=4.14.0,<5.0.0' \
    'python-dotenv>=1.0.0,<2.0.0' \
    'rich>=13.0.0,<14.0.0' \
    'httpx[http2]>=0.24.0,<1.0.0' \
    'aiofile>=3.8.0,<4.0.0' \
    'json-repair>=0.30.3,<1.0.0' \
    'docstring-parser>=0.16,<1.0.0' \
    'networkx>=3.4.2,<4.0.0' \
    'nanoid>=2.0.0,<3.0.0' \
    'cachetools>=6.0.0' \
    'emoji>=2.14.1,<3.0.0' \
    'chardet>=5.2.0,<6.0.0' \
    'defusedxml>=0.7.1,<1.0.0' \
    'passlib>=1.7.4,<2.0.0' \
    'pydantic-settings>=2.10.1,<3.0.0' \
    'tomli>=2.2.1,<3.0.0' \
    'orjson>=3.10.15,<4.0.0' \
    'asyncer>=0.0.8,<1.0.0' \
    'structlog>=25.4.0,<26.0.0' \
    'loguru>=0.7.3,<1.0.0' \
    'langchain~=0.3.23' \
    'validators>=0.34.0,<1.0.0' \
    'filelock>=3.20.1,<4.0.0' \
    'pypdf>=6.4.0,<7.0.0' \
    'cryptography>=43.0.0' \
    'ag-ui-protocol>=0.1.10' \
    'markitdown>=0.1.4,<2.0.0' \
    'setuptools>=80.0.0,<81.0.0' \
    'wheel>=0.46.2,<1.0.0'

# Install backend base dependencies
RUN uv pip install --system --no-cache-dir \
    'httpx[http2]>=0.27,<1.0.0' \
    'aiofile>=3.9.0,<4.0.0' \
    'gunicorn>=22.0.0,<23.0.0' \
    'langchain-community>=0.3.28,<1.0.0' \
    'langchainhub~=0.1.15' \
    'langchain-experimental>=0.3.0,<1.0.0' \
    'sqlmodel>=0.0.21' \
    'email-validator>=2.0.0' \
    'python-multipart>=0.0.12,<1.0.0' \
    'orjson==3.10.15' \
    'alembic>=1.13.0,<2.0.0' \
    'bcrypt==4.0.1' \
    'PyJWT>=2.10.1' \
    'multiprocess>=0.70.14,<1.0.0' \
    'duckdb>=1.0.0,<2.0.0' \
    'python-docx>=1.1.0,<2.0.0' \
    'nest-asyncio>=1.6.0,<2.0.0' \
    'pyperclip>=1.8.2,<2.0.0' \
    'uncurl>=0.0.11,<1.0.0' \
    'sentry-sdk[fastapi,loguru]>=2.5.1,<3.0.0' \
    'firecrawl-py>=1.0.16,<2.0.0' \
    'opentelemetry-api>=1.25.0,<2.0.0' \
    'opentelemetry-sdk>=1.25.0,<2.0.0' \
    'opentelemetry-exporter-prometheus>=0.46b0,<1.0.0' \
    'opentelemetry-instrumentation-fastapi>=0.46b0,<1.0.0' \
    'prometheus-client>=0.20.0,<1.0.0' \
    'pip>=25.3,<26.0.0' \
    'grandalf>=0.8.0,<1.0.0' \
    'spider-client>=0.0.27,<1.0.0' \
    'diskcache>=5.6.3,<6.0.0' \
    'clickhouse-connect==0.7.19' \
    'assemblyai>=0.33.0,<1.0.0' \
    'fastapi-pagination>=0.13.1,<1.0.0' \
    'mcp>=1.17.0,<2.0.0' \
    'aiosqlite>=0.20.0,<1.0.0' \
    'greenlet>=3.1.1,<4.0.0' \
    'jsonquerylang>=1.1.1,<2.0.0' \
    'sqlalchemy[aiosqlite]>=2.0.38,<3.0.0' \
    'scipy>=1.15.2,<2.0.0' \
    'ibm-watsonx-ai>=1.3.1,<2.0.0' \
    'langchain-ibm>=0.3.8,<1.0.0' \
    'trustcall>=0.0.38,<1.0.0' \
    'langchain-chroma>=0.1.4,<1.0.0' \
    'jaraco-context>=6.1.0' \
    'psycopg>=3.3.2,<4.0.0' \
    'psycopg2-binary>=2.9.9,<3.0.0' \
    'elevenlabs>=1.52.0,<2.0.0' \
    'openai>=1.0.0'

# Install local workspace packages WITHOUT resolving dependencies
# since we've already installed all required dependencies above
RUN uv pip install --system --no-deps -e ./src/lfx \
    && uv pip install --system --no-deps -e ./src/backend/base \
    && uv pip install --system --no-deps -e .

# Skip frontend build for now - backend API is priority
# RUN cd /app/src/frontend && timeout 300 npm install --legacy-peer-deps && npm run build 2>/dev/null || true

# Create config directory
RUN mkdir -p /app/vetrai /var/lib/vetrai

# Expose ports
EXPOSE 7860
EXPOSE 3000

# Set environment variables
ENV VETRAI_HOST=0.0.0.0
ENV VETRAI_PORT=7860
ENV PYTHONUNBUFFERED=1

# Run the backend with proper entrypoint
CMD ["uvicorn", "vetrai.main:app", "--host", "0.0.0.0", "--port", "7860"]
