#!/usr/bin/env bash
set -e

GUARD_SCRIPT="/usr/local/bin/oci-docker-network-guard-daemon.sh"

# 写守护脚本
cat > "$GUARD_SCRIPT" <<'EOF'
#!/usr/bin/env bash
set -e

MTU=1500
RATE="50mbit"
BURST="32kbit"
LATENCY="400ms"

MAIN_IFACE=$(ip route | awk '/^default/ {print $5; exit}')
if [ -z "$MAIN_IFACE" ]; then
  exit 1
fi

MAC=$(cat /sys/class/net/$MAIN_IFACE/address)
mkdir -p /etc/udev/rules.d
cat >/etc/udev/rules.d/70-oci-main-net.rules <<EOF2
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="$MAC", NAME="$MAIN_IFACE"
EOF2

mkdir -p /etc/systemd/networkd.conf.d
cat >/etc/systemd/networkd.conf.d/docker-ignore.conf <<EOF2
[Network]
ManageForeignRoutes=no
ManageForeignRoutingPolicyRules=no
EOF2

ip link set dev "$MAIN_IFACE" mtu $MTU || true

mkdir -p /etc/docker
cat >/etc/docker/daemon.json <<EOF2
{
  "mtu": $MTU,
  "live-restore": true,
  "max-concurrent-downloads": 1,
  "max-concurrent-uploads": 1
}
EOF2

systemctl restart docker

cat >/etc/sysctl.d/99-oci-docker.conf <<EOF2
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.netfilter.nf_conntrack_max = 262144
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 4096
EOF2

sysctl --system >/dev/null

limit_container_veth() {
  CONTAINER=$1
  NS=$(docker inspect -f '{{.NetworkSettings.SandboxKey}}' "$CONTAINER")
  VETH=$(ip -o link | awk -F': ' "/veth.*@$NS/ {print \$2}" | cut -d@ -f1)
  for v in $VETH; do
    tc qdisc del dev "$v" root 2>/dev/null || true
    tc qdisc add dev "$v" root tbf rate $RATE burst $BURST latency $LATENCY || true
  done
}

for c in $(docker ps -q); do
  limit_container_veth $c
done

for br in $(ip -o link | awk -F': ' '/^br-/ {print $2}'); do
  ip link set dev "$br" mtu $MTU || true
done

docker events --filter 'event=start' --format '{{.Actor.ID}}' | while read CONTAINER_ID; do
  limit_container_veth $CONTAINER_ID
done
EOF

chmo
