#!/bin/bash
set -e

# Function to find the correct network interface
get_interface() {
    # Try multiple methods to find the correct interface
    local interface
    
    # Method 1: Default route interface
    interface=$(ip route show default | head -n1 | awk '{print $5}' 2>/dev/null || echo "")
    if [ -n "$interface" ] && ip link show "$interface" >/dev/null 2>&1; then
        echo "$interface"
        return 0
    fi
    
    # Method 2: First non-loopback interface with IP
    interface=$(ip -4 route show | grep -E '^[0-9]' | head -n1 | awk '{print $3}' 2>/dev/null || echo "")
    if [ -n "$interface" ] && ip link show "$interface" >/dev/null 2>&1; then
        echo "$interface"
        return 0
    fi
    
    # Method 3: Find interface with docker network (common patterns)
    for iface in $(ip link show | grep -E '^[0-9]+:' | awk -F': ' '{print $2}' | grep -E '^(eth|ens|enp|docker|veth)'); do
        if ip addr show "$iface" | grep -q 'inet ' 2>/dev/null; then
            echo "$iface"
            return 0
        fi
    done
    
    # Method 4: Fallback to eth0 if exists
    if ip link show eth0 >/dev/null 2>&1; then
        echo "eth0"
        return 0
    fi
    
    return 1
}

# Function to setup bandwidth limits
setup_bandwidth() {
    local interface
    interface=$(get_interface)
    
    if [ -z "$interface" ]; then
        echo "Error: Could not determine network interface"
        return 1
    fi
    
    echo "Setting bandwidth limits on interface $interface..."
    
    # Load ifb module
    modprobe ifb 2>/dev/null || true
    
    # Remove existing ifb0 if exists
    ip link del ifb0 2>/dev/null || true
    
    # Create and bring up ifb0
    ip link add ifb0 type ifb
    ip link set dev ifb0 up
    
    # Clear existing qdiscs
    tc qdisc del dev $interface root 2>/dev/null || true
    tc qdisc del dev $interface ingress 2>/dev/null || true
    tc qdisc del dev ifb0 root 2>/dev/null || true
    
    # Setup download limit (ingress)
    if [ -n "$DOWNLOAD_RATE" ]; then
        local download_rate=$(echo $DOWNLOAD_RATE | sed 's/Mbps//g')
        # Redirect ingress to ifb0
        tc qdisc add dev $interface handle ffff: ingress
        tc filter add dev $interface parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb0
        # Apply rate limiting on ifb0
        tc qdisc add dev ifb0 root handle 1: htb default 10
        tc class add dev ifb0 parent 1: classid 1:1 htb rate ${download_rate}mbit ceil ${download_rate}mbit
        tc filter add dev ifb0 parent 1: protocol ip prio 1 u32 match ip src 0.0.0.0/0 flowid 1:1
        echo "Download limit set to ${download_rate}mbit"
    fi
    
    # Setup upload limit (egress)
    if [ -n "$UPLOAD_RATE" ]; then
        local upload_rate=$(echo $UPLOAD_RATE | sed 's/Mbps//g')
        tc qdisc add dev $interface root handle 2: htb default 10
        tc class add dev $interface parent 2: classid 2:1 htb rate ${upload_rate}mbit ceil ${upload_rate}mbit
        tc filter add dev $interface parent 2: protocol ip prio 1 u32 match ip dst 0.0.0.0/0 flowid 2:1
        echo "Upload limit set to ${upload_rate}mbit"
    fi
}

# Cleanup function
cleanup() {
    echo "Cleaning up bandwidth controls..."
    local interface
    interface=$(get_interface 2>/dev/null) || interface=""
    
    if [ -n "$interface" ]; then
        tc qdisc del dev $interface root 2>/dev/null || true
        tc qdisc del dev $interface ingress 2>/dev/null || true
    fi
    tc qdisc del dev ifb0 root 2>/dev/null || true
    ip link del ifb0 2>/dev/null || true
}

trap cleanup EXIT INT TERM

# Setup bandwidth if rates are specified
if [ -n "$DOWNLOAD_RATE" ] || [ -n "$UPLOAD_RATE" ]; then
    setup_bandwidth
fi

# Build microsocks command
CMD="/usr/bin/microsocks"
[ "$AUTH_ONCE" = "true" ] && CMD="$CMD -1"
[ "$QUIET" = "true" ] && CMD="$CMD -q" 
[ -n "$USERNAME" ] && [ -n "$PASSWORD" ] && CMD="$CMD -u $USERNAME -P $PASSWORD"
CMD="$CMD -p ${PORT:-1080}"

echo "Starting: $CMD"
exec $CMD
