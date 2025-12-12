# Oracle Docker Stable

## 介绍
这个脚本用于在 **Oracle Cloud (OCI) 实例** 上防止 Docker 容器导致的掉线问题。  
适用于 Ubuntu、Oracle Linux、RHEL 等单网卡实例，自动固定主网卡，优化 Docker 网络配置。

## 功能
- 自动检测并固定主网卡名称
- 禁止 systemd-networkd 接管 Docker 网络
- 限制 Docker 并发下载/上传，避免桥接网络风暴
- 保留默认网络和已有容器，安全可靠
- 可直接在相同配置的实例上复用

## 使用方法

```bash
# 克隆项目
git clone https://github.com/999k923/oracle-docker-stable.git
cd oracle-docker-stable

# 赋予执行权限并运行
chmod +x fix.sh
sudo ./fix.sh
