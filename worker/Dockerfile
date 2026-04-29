# ===== Stage 1: Build =====
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:7.0-alpine AS build
ARG TARGETARCH
WORKDIR /source
COPY *.csproj .
RUN dotnet restore -a $TARGETARCH
COPY . .
RUN dotnet publish -c release -o /app -a $TARGETARCH --self-contained false --no-restore

# ===== Stage 2: Production image =====
FROM mcr.microsoft.com/dotnet/runtime:7.0-alpine
RUN apk update && apk upgrade --no-cache && \
    rm -rf /var/cache/apk/*
WORKDIR /app
COPY --from=build /app .
RUN adduser -D appuser
USER appuser
ENTRYPOINT ["dotnet", "Worker.dll"]
