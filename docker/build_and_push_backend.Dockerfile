# syntax=docker/dockerfile:1
# Keep this syntax directive! It's used to enable Docker BuildKit

ARG VETRAI_IMAGE
FROM ${VETRAI_IMAGE}

RUN rm -rf /app/.venv/vetrai/frontend

CMD ["python", "-m", "vetrai", "run", "--host", "0.0.0.0", "--port", "7860", "--backend-only"]
