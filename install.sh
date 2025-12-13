#!/usr/bin/env bash
set -e

REPO_RAW="https://raw.githubusercontent.com/999k923/oci-docker-network-guard/main"

echo "=== OCI Docker Network Guard Installer ==="

# 必须 root
if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] 请使用 root 运行"
  exit 1
fi

echo "[INFO] 下载主脚本..."
curl -fsSL "$REPO_RAW/oci-docker-network-guard-all.sh" \
  -o /usr/local/bin/oci-docker-network-guard-all.sh
chmod +x /usr/local/bin/oci-docker-network-guard-all.sh

echo "[INFO] 下载 systemd 服务..."
curl -fsSL "$REPO_RAW/systemd/docker-veth-guard.service" \
  -o /etc/systemd/system/docker-veth-guard.service

echo "[INFO] 运行一次防护脚本..."
/usr/local/bin/oci-docker-network-guard-all.sh

echo "[INFO] 启用 systemd 服务..."
systemctl daemon-reload
systemctl enable docker-veth-guard
systemctl start docker-veth-guard

echo
echo "=== 安装完成 ==="
echo "✔ 防掉线已生效"
echo "✔ 开机 & Docker 启动后自动限速"
echo "👉 建议 reboot 一次"
