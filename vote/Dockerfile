# ===== Stage 1: Build dependencies =====
FROM python:3.11-alpine AS build
WORKDIR /install
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install/deps -r requirements.txt

# ===== Stage 2: Production image =====
FROM python:3.11-alpine
RUN apk update && apk upgrade --no-cache && \
    adduser -D appuser
WORKDIR /app
COPY --from=build /install/deps /usr/local
COPY . .
USER appuser
EXPOSE 80
CMD ["gunicorn", "app:app", "-b", "0.0.0.0:80", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--keep-alive", "0"]
