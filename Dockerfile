# Vetrai Dockerfile - Build from source
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js for frontend build
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn

# Copy source code
COPY . /app/

# Upgrade pip and install dependencies
RUN pip install --upgrade pip setuptools wheel

# Install dependencies from local workspace packages
# Install in dependency order: lfx -> vetrai-base -> vetrai
RUN pip install --no-cache-dir ./src/lfx && \
    pip install --no-cache-dir ./src/backend/base && \
    pip install --no-cache-dir .

# Build frontend (optional, fallback if fails)
RUN cd /app/src/frontend 2>/dev/null && \
    yarn install --frozen-lockfile 2>/dev/null && \
    yarn build 2>/dev/null && \
    mkdir -p /app/src/backend/base/vetrai/frontend 2>/dev/null && \
    cp -r /app/src/frontend/build/* /app/src/backend/base/vetrai/frontend/ 2>/dev/null || true

# Create config directory
RUN mkdir -p /app/vetrai

# Expose port
EXPOSE 7860

# Set environment variables
ENV VETRAI_HOST=0.0.0.0
ENV VETRAI_PORT=7860
ENV PYTHONUNBUFFERED=1

# Default command to start the application
CMD ["uvicorn", "vetrai.main:app", "--host", "0.0.0.0", "--port", "7860"]
