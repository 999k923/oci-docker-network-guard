
---

### 2️⃣ `install.sh`

```bash
#!/usr/bin/env bash
set -e

echo "=== OCI Docker Network Guard Installer ==="

GUARD_SCRIPT="/usr/local/bin/oci-docker-network-guard-daemon.sh"

# 写入守护脚本
cat > "$GUARD_SCRIPT" <<'EOF'
#!/usr/bin/env bash
set -e

echo "=== OCI Docker Network Guard Daemon ==="

MTU=1500
RATE="50mbit"
BURST="32kbit"
LATENCY="400ms"

# 主网卡识别
MAIN_IFACE=$(ip route | awk '/^default/ {print $5; exit}')
if [ -z "$MAIN_IFACE" ]; then
  echo "[ERROR] 无法识别主网卡"
  exit 1
fi
echo "[INFO] 主网卡: $MAIN_IFACE"

# 固定主网卡
MAC=$(cat /sys/class/net/$MAIN_IFACE/address)
mkdir -p /etc/udev/rules.d
cat >/etc/udev/rules.d/70-oci-main-net.rules <<EOF2
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="$MAC", NAME="$MAIN_IFACE"
EOF2
echo "[OK] 主网卡 $MAIN_IFACE 已固定"

# 禁止 systemd-networkd 管理 Docker 网络
mkdir -p /etc/systemd/networkd.conf.d
cat >/etc/systemd/networkd.conf.d/docker-ignore.conf <<EOF2
[Network]
ManageForeignRoutes=no
ManageForeignRoutingPolicyRules=no
EOF2
echo "[OK] systemd-networkd 不再管理 Docker 网络"

# MTU / Docker 配置
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
echo "[OK] Docker MTU 已统一"

# TCP / conntrack
cat >/etc/sysctl.d/99-oci-docker.conf <<EOF2
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.netfilter.nf_conntrack_max = 262144
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 4096
EOF2
sysctl --system >/dev/null
echo "[OK] TCP / conntrack 优化完成"

# 限速函数
limit_container_veth() {
  CONTAINER=$1
  NS=$(docker inspect -f '{{.NetworkSettings.SandboxKey}}' "$CONTAINER")
  VETH=$(ip -o link | awk -F': ' "/veth.*@$NS/ {print \$2}" | cut -d@ -f1)
  for v in $VETH; do
    tc qdisc del dev "$v" root 2>/dev/null || true
    tc qdisc add dev "$v" root tbf rate $RATE burst $BURST latency $LATENCY || true
    echo "[LIMIT] $v -> $RATE"
  done
}

# 限速已有容器
for c in $(docker ps -q); do
  limit_container_veth $c
done
echo "[OK] 当前容器已限速"

# 修正 Docker bridge MTU
for br in $(ip -o link | awk -F': ' '/^br-/ {print $2}'); do
  ip link set dev "$br" mtu $MTU || true
done
echo "[OK] Docker bridges MTU 已修正"

# 守护监听新容器
echo "[INFO] 开始监听新容器启动事件..."
docker events --filter 'event=start' --format '{{.Actor.ID}}' | while read CONTAINER_ID; do
  echo "[INFO] 检测到新容器启动: $CONTAINER_ID"
  limit_container_veth $CONTAINER_ID
done
EOF

chmod +x "$GUARD_SCRIPT"

# 后台运行守护
nohup "$GUARD_SCRIPT" >/var/log/oci-docker-network-guard.log 2>&1 &

echo
echo "=== 安装完成 ==="
echo "守护进程已启动，日志: /var/log/oci-docker-network-guard.log"
echo "主网卡已固定，Docker MTU 已统一，TCP 栈优化完成"
echo "已有容器限速生效，新启动容器会自动限速"
