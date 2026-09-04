if [ -z "$1" ]; then
    echo "Usage: $0 <veth-interface>"
    echo "Available veth interfaces:"
    ls /sys/class/net/ | grep veth
    exit 1
fi

VETH="$1"

# Extract the peer interface index from sysfs
PEER_IFINDEX=$(cat /sys/class/net/"$VETH"/iflink)

# Iterate through running containers to find the matching namespace
for cid in $(docker ps -q); do
    pid=$(docker inspect -f '{{.State.Pid}}' "$cid")
    name=$(docker inspect -f '{{.Name}}' "$cid" | tr -d '/')
    
    # Check if interface index exists inside the container's netns
    if sudo nsenter -t "$pid" -n ip link | grep -q "^${PEER_IFINDEX}:"; then
        echo "Interface: $VETH"
        echo "Container: $name ($cid)"
        echo "PID:       $pid"
        break
    fi
done


printf "%-20s %-16s %-10s %-15s\n" "CONTAINER" "ID" "PID" "VETH INTERFACE"
echo "------------------------------------------------------------------"

for cid in $(docker ps -q); do
    name=$(docker inspect -f '{{.Name}}' "$cid" | tr -d '/')
    pid=$(docker inspect -f '{{.State.Pid}}' "$cid")
    
    # Read the host ifindex from the container's eth0 iflink
    host_ifindex=$(sudo nsenter -t "$pid" -n cat /sys/class/net/eth0/iflink 2>/dev/null)
    
    if [ -n "$host_ifindex" ]; then
        # Match host ifindex back to the host interface name
        veth=$(grep -l "^${host_ifindex}$" /sys/class/net/*/ifindex 2>/dev/null | cut -d'/' -f5)
        printf "%-20s %-16s %-10s %-15s\n" "$name" "$cid" "$pid" "$veth"
    fi
done