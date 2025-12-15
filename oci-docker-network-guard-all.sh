#!/usr/bin/env bash
set -e

echo "=== OCI Docker Network Guard (ALL + STABLE) ==="

MODE="$1"  # safe 模式判断

### 基础参数
MTU=1500
RATE="50mbit"
BURST="32kbit"
LATENCY="400ms"

### 1️⃣ 自动识别主网卡（默认路由）
MAIN_IFACE=$(ip route | awk '/^default/ {print $5; exit}')
if [ -z "$MAIN_IFACE" ]; then
  echo "[ERROR] 无法识别主网卡"
  exit 1
fi
echo "[INFO] 主网卡: $MAIN_IFACE"

# safe 模式下，不固定网卡、改 MTU、改 bridge
if [ "$MODE" != "safe" ]; then
  ### 2️⃣ 固定主网卡名称
  MAC=$(cat /sys/class/net/$MAIN_IFACE/address)
  mkdir -p /etc/udev/rules.d
  cat >/etc/udev/rules.d/70-oci-main-net.rules <<EOF
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="$MAC", NAME="$MAIN_IFACE"
EOF
  echo "[OK] 主网卡 $MAIN_IFACE 已固定"

  ### 3️⃣ 禁止 systemd-networkd 接管 Docker 网络
  mkdir -p /etc/systemd/networkd.conf.d
  cat >/etc/systemd/networkd.conf.d/docker-ignore.conf <<EOF
[Network]
ManageForeignRoutes=no
ManageForeignRoutingPolicyRules=no
EOF
  echo "[OK] systemd-networkd 不再管理 Docker 网络"

  ### 4️⃣ 主网卡 MTU 统一
  ip link set dev "$MAIN_IFACE" mtu $MTU || true
  echo "[OK] 主网卡 MTU -> $MTU"

  ### 5️⃣ 修改 Docker 配置（重启 Docker）
  mkdir -p /etc/docker
  cat >/etc/docker/daemon.json <<EOF
{
  "mtu": $MTU,
  "live-restore": true,
  "max-concurrent-downloads": 1,
  "max-concurrent-uploads": 1
}
EOF
  systemctl restart docker
  echo "[OK] Docker MTU 已统一（重启 Docker）"

  ### 6️⃣ TCP / 网络栈优化
  cat >/etc/sysctl.d/99-oci-docker.conf <<EOF
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.netfilter.nf_conntrack_max = 262144
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 4096
EOF
  sysctl --system >/dev/null
  echo "[OK] TCP / conntrack 优化完成"

  ### 7️⃣ 修正 Docker bridge MTU
  for br in $(ip -o link | awk -F': ' '/^br-/ {print $2}'); do
    ip link set dev "$br" mtu $MTU || true
  done
  echo "[OK] Docker bridges MTU 已修正"
fi

### 8️⃣ 给所有容器 veth 限速（safe 模式也会执行）
echo "[INFO] 为所有容器 veth 设置限速"
for veth in $(ip -o link | awk -F': ' '/veth/ {print $2}' | cut -d@ -f1); do
  tc qdisc del dev "$veth" root 2>/dev/null || true
  tc qdisc add dev "$veth" root tbf rate $RATE burst $BURST latency $LATENCY || true
  echo "  - $veth -> $RATE"
done

### 9️⃣ 重载 systemd（安全模式也可以跳过，如果只限速 veth）
[ "$MODE" != "safe" ] && systemctl daemon-reexec

echo
echo "=== 完成 ==="
if [ "$MODE" == "safe" ]; then
  echo "✔ SAFE 模式完成：仅限制容器 veth 带宽 ($RATE)"
else
  echo "✔ 初始化完成：主网卡固定、Docker MTU、TCP 优化、veth 限速"
fi
echo
echo "👉 建议现在 reboot 一次，让所有规则完全生效（仅初始化需要）"
