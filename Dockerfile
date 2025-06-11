# Stage 1: Build static binary
FROM alpine:3.18 AS builder
RUN apk --no-cache add make gcc linux-headers git musl-dev && \
    git clone --depth 1 https://github.com/rofl0r/microsocks /opt/microsocks && \
    cd /opt/microsocks && \
    make LDFLAGS="-static" CFLAGS="-Os -pipe" && \
    strip --strip-all microsocks

# Stage 2: Runtime with bandwidth control
FROM alpine:3.18

# Install dependencies for bandwidth control
RUN apk add --no-cache iproute2 bash && \
    echo "ifb" >> /etc/modules

# Copy microsocks binary
COPY --from=builder /opt/microsocks/microsocks /usr/bin/microsocks

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Environment variables declaration (without default values)
ENV AUTH_ONCE \
    QUIET \
    USERNAME \
    PASSWORD \
    PORT \
    DOWNLOAD_RATE \
    UPLOAD_RATE

ENTRYPOINT ["/entrypoint.sh"]
