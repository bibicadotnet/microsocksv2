FROM alpine:3.18 AS builder
RUN apk add --no-cache make gcc linux-headers git musl-dev && \
    git clone --depth 1 https://github.com/rofl0r/microsocks /opt/microsocks && \
    cd /opt/microsocks && \
    make LDFLAGS="-static" CFLAGS="-Os -pipe" && \
    strip --strip-all microsocks

FROM alpine:3.18
RUN apk add --no-cache iproute2 bash
COPY --from=builder /opt/microsocks/microsocks /usr/bin/microsocks
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN addgroup -g 65534 -S nogroup || true && \
    adduser -u 65534 -G nogroup -S -s /bin/sh nobody || true
ENTRYPOINT ["/entrypoint.sh"]
