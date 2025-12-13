# OCI Docker Network Guard

防止 Oracle Cloud / 1Panel / Dockge 容器访问导致主机掉线。

### 功能

- 固定主网卡
- 禁止 systemd-networkd 管理 Docker 网络
- 统一 MTU、优化 TCP / conntrack
- 限制所有现有容器 veth 流量
- 自动监听新启动容器并限速
- 支持 OCI ARM / AMD 实例
- 不依赖 systemd 服务，不会报依赖错误

### 安装

```bash
# 一键部署 OCI Docker Network Guard (开机自启 + 每30分钟刷新 veth 限速)
curl -fsSL https://raw.githubusercontent.com/999k923/oci-docker-network-guard/main/oci-docker-network-guard-all.sh -o /usr/local/bin/oci-docker-network-guard-all.sh && \
chmod +x /usr/local/bin/oci-docker-network-guard-all.sh && \
cat >/etc/systemd/system/docker-veth-guard.service <<'EOF'
[Unit]
Description=OCI Docker veth bandwidth guard
After=docker.service
Wants=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/oci-docker-network-guard-all.sh
EOF
cat >/etc/systemd/system/docker-veth-guard.timer <<'EOF'
[Unit]
Description=Run OCI Docker veth guard every 30 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=30min
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload && \
systemctl enable --now docker-veth-guard.timer && \
systemctl start docker-veth-guard.timer
echo "✅ OCI Docker Network Guard 部署完成，开机自启 + 每30分钟刷新 veth 限速已启用。"

```
