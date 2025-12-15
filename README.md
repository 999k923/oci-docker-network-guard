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
#!/usr/bin/env bash
set -e

echo "=== 一键安装 OCI Docker Network Guard ==="

### 1️⃣ 下载主脚本
echo "[INFO] 下载 oci-docker-network-guard-all.sh ..."
curl -fsSL https://raw.githubusercontent.com/999k923/oci-docker-network-guard/main/oci-docker-network-guard-all.sh -o /usr/local/bin/oci-docker-network-guard-all.sh
chmod +x /usr/local/bin/oci-docker-network-guard-all.sh
echo "[OK] 脚本已保存到 /usr/local/bin/oci-docker-network-guard-all.sh"

### 2️⃣ 运行一次初始化模式（会重启 Docker）
echo "[INFO] 运行一次初始化模式..."
/usr/local/bin/oci-docker-network-guard-all.sh
echo "[OK] 初始化完成"

### 3️⃣ 创建 systemd service 文件（safe 模式执行）
echo "[INFO] 创建 systemd service..."
cat >/etc/systemd/system/docker-veth-guard.service <<EOF
[Unit]
Description=OCI Docker veth bandwidth guard
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/oci-docker-network-guard-all.sh safe
EOF
echo "[OK] systemd service 创建完成"

### 4️⃣ 创建 systemd timer，每半小时执行一次（固定 0 分和 30 分）
echo "[INFO] 创建 systemd timer..."
cat >/etc/systemd/system/docker-veth-guard.timer <<EOF
[Unit]
Description=Run docker-veth-guard every 30 minutes

[Timer]
OnCalendar=*:0/30
Persistent=true
AccuracySec=1min

[Install]
WantedBy=timers.target
EOF
echo "[OK] systemd timer 创建完成"

### 5️⃣ 启用并启动 timer
systemctl daemon-reload
systemctl enable --now docker-veth-guard.timer
echo "[OK] Timer 已启用，每半小时自动执行"

echo
echo "=== 安装完成 ==="
echo "✔ 脚本已保存并授予权限"
echo "✔ 初次初始化已执行"
echo "✔ Timer 每半小时固定在 0 分和 30 分执行 safe 模式"
echo "✔ 开机后 Timer 会自动启动"
echo
echo "👉 建议现在 reboot 一次，让所有规则完全生效"


```
