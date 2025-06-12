#!/bin/bash
set -e
# Redirect all output to /dev/null
exec >/dev/null 2>&1

# Kiểm tra eth0 tồn tại trước khi tiếp tục
ip link show eth0 >/dev/null 2>&1 || { echo "eth0 not found" >&2; exit 1; }

get_params() {
    local r=$1
    awk -v rate="$r" 'BEGIN {
        if (rate <= 20) { mult=200; lat="300ms" }
        else if (rate <= 50) { mult=150; lat="200ms" }
        else if (rate <= 100) { mult=100; lat="100ms" }
        else { mult=75; lat="50ms" }
        burst = rate * mult
        if (burst < 10) burst = 10
        printf "%.0fkbit %s", burst, lat
    }'
}

# Thiết lập giới hạn băng thông
setup_bandwidth() {
    local interface="eth0"
    
    # Dọn sạch qdisc và ifb cũ nếu có
    tc qdisc del dev $interface root 2>/dev/null || true
    tc qdisc del dev $interface ingress 2>/dev/null || true
    tc qdisc del dev ifb0 root 2>/dev/null || true
    ip link del ifb0 2>/dev/null || true

    # Upload (egress)
    if [ -n "$UPLOAD_RATE" ]; then
        local rate=${UPLOAD_RATE/Mbps/} params=$(get_params "$rate")
        tc qdisc add dev $interface root tbf rate ${rate}mbit burst ${params%% *} latency ${params##* }
    fi

    # Download (ingress) qua ifb
    if [ -n "$DOWNLOAD_RATE" ]; then
        local rate=${DOWNLOAD_RATE/Mbps/} params=$(get_params "$rate")
        modprobe ifb 2>/dev/null || true
        ip link show ifb0 >/dev/null 2>&1 || ip link add ifb0 type ifb
        ip link set dev ifb0 up
        tc qdisc add dev $interface handle ffff: ingress
        tc filter add dev $interface parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb0
        tc qdisc add dev ifb0 root tbf rate ${rate}mbit burst ${params%% *} latency ${params##* }
    fi
}

# Dọn dẹp khi container thoát
cleanup() {
    local interface="eth0"
    tc qdisc del dev $interface root 2>/dev/null || true
    tc qdisc del dev $interface ingress 2>/dev/null || true
    tc qdisc del dev ifb0 root 2>/dev/null || true
    ip link del ifb0 2>/dev/null || true
}

trap cleanup EXIT INT TERM

# Áp dụng giới hạn nếu có yêu cầu
{ [ -n "$DOWNLOAD_RATE" ] || [ -n "$UPLOAD_RATE" ]; } && setup_bandwidth

# Khởi chạy microsocks
exec /usr/bin/microsocks \
    ${AUTH_ONCE:+-1} \
    ${QUIET:+-q} \
    ${USERNAME:+-u "$USERNAME"} \
    ${PASSWORD:+-P "$PASSWORD"} \
    -p "${PORT:-1080}"
