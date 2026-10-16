# syntax=docker/dockerfile:1.7

ARG GO_VERSION=1.24
FROM golang:${GO_VERSION}-alpine AS builder

WORKDIR /src
ENV CGO_ENABLED=0

COPY go.mod go.sum* ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -trimpath -ldflags="-s -w" -o /out/whoami .

FROM alpine:3.20

RUN apk add --no-cache ca-certificates \
 && addgroup -S app \
 && adduser -S -G app -u 10001 -H -s /sbin/nologin app

COPY --from=builder --chown=app:app /out/whoami /app/whoami

ENV WHOAMI_PORT_NUMBER=8080 \
    WHOAMI_NAME="whoami-alpine"

EXPOSE 8080
USER app

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget -q -O /dev/null "http://127.0.0.1:${WHOAMI_PORT_NUMBER}/health" || exit 1

ENTRYPOINT ["/app/whoami"]
