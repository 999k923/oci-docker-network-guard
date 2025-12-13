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

# OCI Docker Network Guard

防止 Oracle Cloud OCI 免费实例在使用 Docker / Dockge / 1Panel
时因网络洪峰导致整机掉线。

## 特性

- 固定主网卡名称
- 禁止 systemd-networkd 干扰 Docker 网络
- 统一 MTU = 1500
- 所有容器 veth 限速（防网络洪峰）
- systemd 开机自动生效

## 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/999k923/oci-docker-network-guard/main/install.sh | bash
```
## 卸载
```bash
curl -fsSL https://raw.githubusercontent.com/999k923/oci-docker-network-guard/main/uninstall.sh | bash
```
