#!/usr/bin/env bash
set -e

echo "=== OCI Docker Network Guard 卸载 ==="

# 杀掉守护进程
pkill -f oci-docker-network-guard-daemon.sh || true
rm -f /usr/local/bin/oci-docker-network-guard-daemon.sh

# 删除配置
rm -f /etc/udev/rules.d/70-oci-main-net.rules
rm -f /etc/systemd/networkd.conf.d/docker-ignore.conf
rm -f /etc/sysctl.d/99-oci-docker.conf

echo "=== 卸载完成 ==="
