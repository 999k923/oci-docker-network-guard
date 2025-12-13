#!/usr/bin/env bash
set -e

echo "=== OCI Docker Network Guard Installer ==="

# 下载主脚本
echo "[INFO] 下载主脚本..."
curl -fsSL https://raw.githubusercontent.com/999k923/oci-docker-network-guard/main/oci-docker-network-guard-all.sh -o /usr/local/bin/oci-docker-network-guard-all.sh
chmod +x /usr/local/bin/oci-docker-network-guard-all.sh
echo "[OK] 主脚本已下载到 /usr/local/bin/oci-docker-network-guard-all.sh"

# 下载 systemd 服务文件
echo "[INFO] 下载 systemd 服务..."
mkdir -p /etc/systemd/system
curl -fsSL https://raw.githubusercontent.com/999k923/oci-docker-network-guard/main/systemd/docker-veth-guard.service -o /etc/systemd/system/docker-veth-guard.service
systemctl daemon-reload
echo "[OK] systemd 服务已下载"

# 运行一次防护脚本
echo "[INFO] 运行一次防护脚本..."
bash /usr/local/bin/oci-docker-network-guard-all.sh

# 启用 systemd 服务（开机自启）
echo "[INFO] 启用 systemd 服务..."
systemctl enable docker-veth-guard.service

echo
echo "=== 安装完成 ==="
echo "✔ 主网卡 + Docker 网络防护已生效"
echo "✔ 所有容器 veth 已限速"
echo "✔ 建议现在 reboot 一次，让所有规则完全生效"
