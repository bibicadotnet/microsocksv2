#!/bin/bash
set -e

setup_bandwidth() {
    local interface=$(ip route | awk '/default/ {print $5; exit}')
    [ -z "$interface" ] && interface=$(ip link show up | awk -F': ' '/^[0-9]+: [^lo]/ {gsub(/@.*/, "", $2); print $2; exit}')
    [ -z "$interface" ] && { echo "FATAL: No network interface found"; exit 1; }
    
    modprobe ifb numifbs=1 || { echo "FATAL: Can't load ifb"; exit 1; }
    ip link add ifb0 type ifb 2>/dev/null || true
    ip link set dev ifb0 up || { echo "FATAL: Can't setup ifb0"; exit 1; }
    
    tc qdisc del dev $interface root 2>/dev/null || true
    tc qdisc del dev $interface ingress 2>/dev/null || true
    tc qdisc del dev ifb0 root 2>/dev/null || true
    
    if [ -n "$DOWNLOAD_RATE" ]; then
        local dl_rate=$(echo "$DOWNLOAD_RATE" | grep -oE '[0-9]+')
        [ -z "$dl_rate" ] && { echo "FATAL: Invalid DOWNLOAD_RATE"; exit 1; }
        
        tc qdisc add dev $interface handle ffff: ingress || exit 1
        tc filter add dev $interface parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb0 || exit 1
        tc qdisc add dev ifb0 root handle 1: htb default 10 || exit 1
        tc class add dev ifb0 parent 1: classid 1:1 htb rate ${dl_rate}mbit ceil ${dl_rate}mbit || exit 1
        tc filter add dev ifb0 parent 1: protocol ip prio 1 u32 match ip src 0.0.0.0/0 flowid 1:1 || exit 1
    fi
    
    if [ -n "$UPLOAD_RATE" ]; then
        local ul_rate=$(echo "$UPLOAD_RATE" | grep -oE '[0-9]+')
        [ -z "$ul_rate" ] && { echo "FATAL: Invalid UPLOAD_RATE"; exit 1; }
        
        tc qdisc add dev $interface root handle 2: htb default 10 || exit 1
        tc class add dev $interface parent 2: classid 2:1 htb rate ${ul_rate}mbit ceil ${ul_rate}mbit || exit 1
        tc filter add dev $interface parent 2: protocol ip prio 1 u32 match ip dst 0.0.0.0/0 flowid 2:1 || exit 1
    fi
}

{ [ -n "$DOWNLOAD_RATE" ] || [ -n "$UPLOAD_RATE" ]; } && setup_bandwidth

CMD="/usr/bin/microsocks"
[ "$AUTH_ONCE" = "true" ] && CMD="$CMD -1"
[ "$QUIET" = "true" ] && CMD="$CMD -q" 
[ -n "$USERNAME" ] && [ -n "$PASSWORD" ] && CMD="$CMD -u $USERNAME -P $PASSWORD"
exec $CMD -p ${PORT:-1080}
