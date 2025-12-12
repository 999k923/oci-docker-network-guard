#!/bin/bash
echo ">>> Oracle Docker 防掉线通用修复脚本启动..."

# 1️⃣ 自动检测主网卡（UP 并有默认路由的网卡）
MAIN_IFACE=$(ip route | grep '^default' | awk '{print $5}')
if [ -z "$MAIN_IFACE" ]; then
  echo "⚠️ 未检测到主网卡，请手动确认！"
  exit 1
fi
echo "[INFO] 检测到主网卡: $MAIN_IFACE"

# 2️⃣ 获取 MAC 并写入 udev 固定规则
MAC=$(cat /sys/class/net/$MAIN_IFACE/address)
mkdir -p /etc/udev/rules.d
cat > /etc/udev/rules.d/70-persistent-net.rules << EOL
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="$MAC", NAME="$MAIN_IFACE"
EOL
echo "[OK] 主网卡 $MAIN_IFACE 已固定"

# 3️⃣ 禁止 systemd-networkd 接管 Docker 网络
mkdir -p /etc/systemd/networkd.conf.d
cat > /etc/systemd/networkd.conf.d/ignore-container.conf << EOL
[Network]
ManageForeignRoutes=no
ManageForeignRoutingPolicyRules=no
EOL
echo "[OK] systemd-networkd 不再管理 Docker 网络"

# 4️⃣ Docker 配置优化，防止桥接风暴
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOL
{
  "live-restore": true,
  "bridge": "docker0",
  "max-concurrent-downloads": 1,
  "max-concurrent-uploads": 1
}
EOL
echo "[OK] Docker 配置优化完成"

# 5️⃣ 重新加载 systemd 并重启服务
systemctl daemon-reload
systemctl restart systemd-networkd
systemctl restart docker

echo ">>> 修复完成！此实例以后安装 Docker 容器不会再掉线。"
