#!/usr/bin/env bash
set -e

echo "=== 卸载 OCI Docker Network Guard ==="

systemctl disable --now docker-veth-guard || true
rm -f /etc/systemd/system/docker-veth-guard.service
rm -f /usr/local/bin/oci-docker-network-guard-all.sh

systemctl daemon-reload

echo "[OK] 已卸载"
