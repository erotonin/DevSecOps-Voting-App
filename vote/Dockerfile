# ===== Stage 1: Build dependencies =====
FROM python:3.11-alpine AS build
WORKDIR /install
ARG NEXUS_URL=https://pypi.org/simple
COPY requirements.txt .
RUN TRUSTED_HOST=$(echo $NEXUS_URL | awk -F/ '{print $3}') && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --prefix=/install/deps -r requirements.txt -i ${NEXUS_URL} --trusted-host $TRUSTED_HOST wheel>=0.46.2 jaraco.context>=6.1.0

# ===== Stage 2: Production image =====
FROM python:3.11-alpine
RUN apk update && apk upgrade --no-cache && \
    adduser -D appuser
WORKDIR /app
COPY --from=build /install/deps /usr/local
# Nâng cấp các thư viện bị lỗi CVE để ghi đè phiên bản cũ trong base image
RUN pip install --no-cache-dir --upgrade wheel jaraco.context
COPY . .
USER appuser
EXPOSE 80
CMD ["gunicorn", "app:app", "-b", "0.0.0.0:80", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--keep-alive", "0"]
