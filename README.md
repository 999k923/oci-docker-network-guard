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
curl -fsSL https://raw.githubusercontent.com/999k923/oci-docker-network-guard/main/install.sh | bash
