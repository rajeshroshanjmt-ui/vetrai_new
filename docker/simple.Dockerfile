# Simplified VetRAI Dockerfile - without frozen lock
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim
ENV TZ=UTC

WORKDIR /app

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
    build-essential \
    curl \
    npm \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY . /app

# Install dependencies using uv without frozen lock
# This allows the build to succeed even if lock file is outdated
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-install-project --no-dev --extra postgresql

EXPOSE 7860
EXPOSE 3000

CMD ["./docker/dev.start.sh"]
